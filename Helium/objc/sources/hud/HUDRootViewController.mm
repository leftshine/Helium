//
//  HUDRootViewController.mm
//  Helium
//
//  Created by lemin on 10/5/23.
//

#import <notify.h>
#import <objc/runtime.h>

#if TARGET_IPHONE_SIMULATOR
#import "Helium_Simulator-Swift.h"
#else
#import "Helium-Swift.h"
#endif
#import "HUDRootViewController.h"

#import "UsefulFunctions.h"
#import "WidgetsContainerView.h"

#import "FBSOrientationObserver.h"
#import "FBSOrientationUpdate.h"
#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"
#import "SpringBoardServices.h"
#import "UIApplication+Private.h"

#define NOTIFY_UI_LOCKSTATE "com.apple.springboard.lockstate"

static void SpringBoardLockStatusChanged
    (CFNotificationCenterRef center,
    void                     *observer,
    CFStringRef              name,
    const void               *object,
    CFDictionaryRef          userInfo) {
    HUDRootViewController *rootViewController = (__bridge HUDRootViewController *)observer;
    NSString *lockState = (__bridge NSString *)name;

    if ([lockState isEqualToString:@NOTIFY_UI_LOCKSTATE]) {
        mach_port_t sbsPort = SBSSpringBoardServerPort();

        if (sbsPort == MACH_PORT_NULL) {
            return;
        }

        BOOL isLocked;
        BOOL isPasscodeSet;
        SBGetScreenLockStatus(sbsPort, &isLocked, &isPasscodeSet);

        if (!isLocked) {
            [rootViewController.view setHidden:NO];
            [rootViewController resumeLoopTimer];
        } else {
            [rootViewController pauseLoopTimer];
            [rootViewController.view setHidden:YES];
        }
    }
}

static void ReloadHUD
    (CFNotificationCenterRef center,
    void                     *observer,
    CFStringRef              name,
    const void               *object,
    CFDictionaryRef          userInfo) {
    // NSLog(@"boom ReloadHUD");
    HUDRootViewController *rootViewController = (__bridge HUDRootViewController *)observer;

    [rootViewController reloadUserDefaults];
    [rootViewController reloadWidgets];
    [rootViewController updateViewConstraints];
}

#pragma mark - HUDRootViewController

@implementation HUDRootViewController {
    NSMutableDictionary *_userDefaults;
    NSMutableArray <NSLayoutConstraint *> *_constraints;
    FBSOrientationObserver *_orientationObserver;
    // view object arrays
    NSMutableArray <WidgetsContainerView *> *_containerViews;

    UIView *_contentView;
    ScreenshotInvisibleContainer *_containerView;
    UIView *_hiddenContainerView;
    UIView *_borderView;

    UIInterfaceOrientation _orientation;

    UIView *_horizontalLine;
    UIView *_verticalLine;
}

- (void)registerNotifications
{
    int token;

    notify_register_dispatch(NOTIFY_RELOAD_HUD, &token, dispatch_get_main_queue(), ^(int token) {
        [self reloadUserDefaults];
        [self reloadWidgets];
        [self updateViewConstraints];
    });

    CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();

    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        SpringBoardLockStatusChanged,
        CFSTR(NOTIFY_UI_LOCKSTATE),
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
        );

    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        ReloadHUD,
        CFSTR(NOTIFY_RELOAD_HUD),
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
        );
}

#pragma mark - User Default Stuff

- (void)loadUserDefaults:(BOOL)forceReload
{
    if (forceReload || !_userDefaults) {
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] mutableCopy] ? : [NSMutableDictionary dictionary];
    }
}

- (void)reloadUserDefaults
{
    [self loadUserDefaults:YES];

    if ([self debugBorder]) {
        [_borderView setHidden:NO];
        [_horizontalLine setHidden:NO];
        [_verticalLine setHidden:NO];
    } else {
        [_borderView setHidden:YES];
        [_horizontalLine setHidden:YES];
        [_verticalLine setHidden:YES];
    }

    if ([self hideOnScreenshot]) {
        [_containerView setupContainerAsHideContentInScreenshots];
    } else {
        [_containerView setupContainerAsDisplayContentInScreenshots];
    }
}

- (BOOL)debugBorder
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"debugBorder"];
    return mode ? [mode boolValue] : NO;
}

- (BOOL)hideOnScreenshot
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:@"hideOnScreenshot"];
    return mode ? [mode boolValue] : NO;
}

- (NSArray *)widgetProperties
{
    [self loadUserDefaults:NO];
    NSArray *properties = [_userDefaults objectForKey:@"widgetProperties"];
    return properties;
}

- (BOOL)isLandscapeOrientation
{
    BOOL isLandscape;

    if (_orientation == UIInterfaceOrientationUnknown) {
        isLandscape = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    } else {
        isLandscape = UIInterfaceOrientationIsLandscape(_orientation);
    }

    return isLandscape;
}

#pragma mark - Initialization and Deallocation

- (instancetype)init
{
    self = [super init];

    if (self) {
        _constraints = [NSMutableArray array];
        _containerViews = [NSMutableArray array];
        _orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
        __weak HUDRootViewController *weakSelf = self;
        [_orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
            HUDRootViewController *strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                               [strongSelf updateOrientation:(UIInterfaceOrientation)orientationUpdate.orientation
                                         animateWithDuration:orientationUpdate.duration];
                           });
        }];
        [self registerNotifications];
    }

    return self;
}

- (void)dealloc
{
    [_orientationObserver invalidate];
}

#pragma mark - HUD UI Main Functions

- (void)viewDidLoad
{
    [super viewDidLoad];
    // MARK: Main Content View
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_contentView];

    _hiddenContainerView = [[UIView alloc] init];
    _hiddenContainerView.backgroundColor = [UIColor clearColor];
    _hiddenContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    _containerView = [[ScreenshotInvisibleContainer alloc] initWithContent:_hiddenContainerView];
    [_contentView addSubview:_containerView];

    _horizontalLine = [[UIView alloc] initWithFrame:CGRectZero];
    _horizontalLine.backgroundColor = [UIColor redColor];
    _horizontalLine.translatesAutoresizingMaskIntoConstraints = NO;
    [_horizontalLine setHidden:YES];
    [_hiddenContainerView addSubview:_horizontalLine];

    _verticalLine = [[UIView alloc] initWithFrame:CGRectZero];
    _verticalLine.backgroundColor = [UIColor redColor];
    _verticalLine.translatesAutoresizingMaskIntoConstraints = NO;
    [_verticalLine setHidden:YES];
    [_hiddenContainerView addSubview:_verticalLine];

    _borderView = [[UIView alloc] initWithFrame:CGRectZero];
    _borderView.backgroundColor = [UIColor clearColor];
    _borderView.layer.borderColor = [UIColor redColor].CGColor;
    _borderView.layer.borderWidth = 1.0;
    _borderView.translatesAutoresizingMaskIntoConstraints = NO;
    [_borderView setHidden:YES];
    [_hiddenContainerView addSubview:_borderView];

    [_contentView setUserInteractionEnabled:YES];

    [self reloadWidgets];
    notify_post(NOTIFY_RELOAD_HUD);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    notify_post(NOTIFY_LAUNCHED_HUD);
}

#pragma mark - Timer and View Updating
- (void)pauseLoopTimer
{
    for (WidgetsContainerView *containerView in _containerViews) {
        [containerView pauseTimer];
    }
}

- (void)resumeLoopTimer
{
    for (WidgetsContainerView *containerView in _containerViews) {
        [containerView resumeTimer];
    }
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    [self updateViewConstraints];
}

- (void)reloadWidgets {
    for (WidgetsContainerView *widgetsContainerView in _containerViews) {
        [widgetsContainerView removeFromSuperview];
        [widgetsContainerView cancleTimer];
    }

    [_containerViews removeAllObjects];

    for (NSDictionary *properties in [self widgetProperties]) {
        WidgetsContainerView *containerView = [[WidgetsContainerView alloc] initWithFrame:CGRectZero];
        containerView.viewID = getStringFromDictKey(properties, @"id");
        [containerView reloadConfig];
        [containerView reloadWidgets];
        [containerView setLandscape:[self isLandscapeOrientation]];
        [_containerViews addObject:containerView];
        [_hiddenContainerView addSubview:containerView];
    }
}

- (void)updateViewConstraints
{
    [NSLayoutConstraint deactivateConstraints:_constraints];
    [_constraints removeAllObjects];

    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;

    // code from Lessica/TrollSpeed
    if ([self isLandscapeOrientation]) {
        CGFloat notchHeight;
        CGFloat paddingNearNotch;
        CGFloat paddingFarFromNotch;

        notchHeight = CGRectGetMinY(layoutGuide.layoutFrame);
        paddingNearNotch = (notchHeight > 30) ? notchHeight - 16 : 4;
        paddingFarFromNotch = (notchHeight > 30) ? -24 : -4;

        [_constraints addObjectsFromArray:@[
             [_contentView.leadingAnchor constraintEqualToAnchor:layoutGuide.leadingAnchor
                                                        constant:(_orientation == UIInterfaceOrientationLandscapeLeft ? -paddingFarFromNotch : paddingNearNotch)],
             [_contentView.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor
                                                         constant:(_orientation == UIInterfaceOrientationLandscapeLeft ? -paddingNearNotch : paddingFarFromNotch)],
        ]];

        CGFloat minimumLandscapeTopConstant = 0;
        CGFloat minimumLandscapeBottomConstant = 0;

        minimumLandscapeTopConstant = (isPad ? 30 : 10);
        minimumLandscapeBottomConstant = (isPad ? -34 : -14);

        /* Fixed Constraints */
        [_constraints addObjectsFromArray:@[
             [_contentView.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.topAnchor
                                                                 constant:minimumLandscapeTopConstant],
             [_contentView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor
                                                                 constant:minimumLandscapeBottomConstant],
        ]];

        /* Flexible Constraint */
        NSLayoutConstraint *_topConstraint = [_contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:minimumLandscapeTopConstant];
        _topConstraint.priority = UILayoutPriorityDefaultLow;

        [_constraints addObject:_topConstraint];
    } else {
        [_constraints addObjectsFromArray:@[
             [_contentView.leadingAnchor constraintEqualToAnchor:layoutGuide.leadingAnchor],
             [_contentView.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor],
        ]];

        CGFloat minimumTopConstraintConstant = 0;
        CGFloat minimumBottomConstraintConstant = 0;

        if (CGRectGetMinY(layoutGuide.layoutFrame) >= 51) {
            minimumTopConstraintConstant = -8;
            minimumBottomConstraintConstant = -4;
        } else if (CGRectGetMinY(layoutGuide.layoutFrame) > 30) {
            minimumTopConstraintConstant = -12;
            minimumBottomConstraintConstant = -4;
        } else {
            minimumTopConstraintConstant = (isPad ? 30 : 20);
            minimumBottomConstraintConstant = -20;
        }

        /* Fixed Constraints */
        [_constraints addObjectsFromArray:@[
             [_contentView.topAnchor constraintGreaterThanOrEqualToAnchor:layoutGuide.topAnchor
                                                                 constant:minimumTopConstraintConstant],
             [_contentView.bottomAnchor constraintLessThanOrEqualToAnchor:layoutGuide.bottomAnchor
                                                                 constant:minimumBottomConstraintConstant],
        ]];

        /* Flexible Constraint */
        NSLayoutConstraint *_topConstraint = [_contentView.topAnchor constraintEqualToAnchor:layoutGuide.topAnchor constant:minimumTopConstraintConstant];
        _topConstraint.priority = UILayoutPriorityDefaultLow;

        [_constraints addObject:_topConstraint];
    }

    // MARK: Set Label Constraints
    NSArray *widgetProps = [self widgetProperties];

    // DEFINITELY NEEDS OPTIMIZATION
    for (int i = 0; i < [widgetProps count]; i++) {
        WidgetsContainerView *widgetsContainerView = [_containerViews objectAtIndex:i];
        NSDictionary *properties = [widgetProps objectAtIndex:i];

        if (!widgetsContainerView || !properties) {
            break;
        }

        double offsetPX = getDoubleFromDictKey(properties, @"offsetPX");
        double offsetPY = getDoubleFromDictKey(properties, @"offsetPY");
        double offsetLX = getDoubleFromDictKey(properties, @"offsetLX");
        double offsetLY = getDoubleFromDictKey(properties, @"offsetLY");
        NSInteger anchorSide = getIntFromDictKey(properties, @"anchor");
        NSInteger anchorYSide = getIntFromDictKey(properties, @"anchorY");

        // set the vertical anchor
        if (anchorYSide == 1) {
            [_constraints addObject:[widgetsContainerView.centerYAnchor constraintEqualToAnchor:_contentView.centerYAnchor constant:([self isLandscapeOrientation] ? offsetLY : offsetPY)]];
        } else if (anchorYSide == 0) {
            [_constraints addObject:[widgetsContainerView.topAnchor constraintEqualToAnchor:_contentView.topAnchor constant:([self isLandscapeOrientation] ? offsetLY : offsetPY)]];
        } else {
            [_constraints addObject:[widgetsContainerView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor constant:([self isLandscapeOrientation] ? offsetLY : offsetPY)]];
        }

        // set the horizontal anchor
        if (anchorSide == 1) {
            [_constraints addObject:[widgetsContainerView.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor constant:([self isLandscapeOrientation] ? offsetLX : offsetPX)]];
        } else if (anchorSide == 0) {
            [_constraints addObject:[widgetsContainerView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:([self isLandscapeOrientation] ? offsetLX : offsetPX)]];
        } else {
            [_constraints addObject:[widgetsContainerView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:([self isLandscapeOrientation] ? -offsetLX : -offsetPX)]];
        }

        // set the width
        if (!getBoolFromDictKey(properties, @"autoResizes")) {
            [_constraints addObject:[widgetsContainerView.widthAnchor constraintEqualToConstant:getDoubleFromDictKey(properties, @"scale", 50.0)]];
            [_constraints addObject:[widgetsContainerView.heightAnchor constraintEqualToConstant:getDoubleFromDictKey(properties, @"scaleY", 12.0)]];
        }
    }

    [_constraints addObjectsFromArray:@[
         [_horizontalLine.centerYAnchor constraintEqualToAnchor:_contentView.centerYAnchor],
         [_horizontalLine.widthAnchor constraintEqualToAnchor:_contentView.widthAnchor],
         [_horizontalLine.heightAnchor constraintEqualToConstant:1]
    ]];

    [_constraints addObjectsFromArray:@[
         [_verticalLine.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor],
         [_verticalLine.widthAnchor constraintEqualToConstant:1],
         [_verticalLine.heightAnchor constraintEqualToAnchor:_contentView.heightAnchor]
    ]];

    [_constraints addObjectsFromArray:@[
         [_borderView.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor],
         [_borderView.widthAnchor constraintEqualToAnchor:_contentView.widthAnchor],
         [_borderView.heightAnchor constraintEqualToAnchor:_contentView.heightAnchor]
    ]];

    [NSLayoutConstraint activateConstraints:_constraints];
    [super updateViewConstraints];
}

static inline CGFloat orientationAngle(UIInterfaceOrientation orientation) {
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;

        case UIInterfaceOrientationLandscapeLeft:
            return -M_PI_2;

        case UIInterfaceOrientationLandscapeRight:
            return M_PI_2;

        default:
            return 0;
    }
}

static inline CGRect orientationBounds(UIInterfaceOrientation orientation, CGRect bounds) {
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return CGRectMake(0, 0, bounds.size.height, bounds.size.width);

        default:
            return bounds;
    }
}

- (void)updateOrientation:(UIInterfaceOrientation)orientation animateWithDuration:(NSTimeInterval)duration
{
    if (orientation == _orientation) {
        return;
    }

    _orientation = orientation;

    __weak typeof(self) weakSelf = self;
    NSArray *widgetProps = [weakSelf widgetProperties];

    for (int i = 0; i < [widgetProps count]; i++) {
        WidgetsContainerView *widgetsContainerView = [_containerViews objectAtIndex:i];
        [widgetsContainerView setLandscape:[self isLandscapeOrientation]];
    }

    CGRect bounds = orientationBounds(orientation, [UIScreen mainScreen].bounds);
    [self.view setNeedsUpdateConstraints];
    [self.view setHidden:YES];
    [self.view setBounds:bounds];

    [UIView animateWithDuration:duration
                     animations:^{
        [weakSelf.view setTransform:CGAffineTransformMakeRotation(orientationAngle(orientation))];
    }
                     completion:^(BOOL finished) {
        [weakSelf.view setHidden:NO];
    }];
}

@end
