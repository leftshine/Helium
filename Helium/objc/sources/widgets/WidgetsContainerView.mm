//
//  WidgetsContainerView.mm
//  Helium
//
//  Created by Fuuko on 2024/4/13.
//

#import "EZTimer.h"
#import "UsefulFunctions.h"
#import "WidgetsContainerView.h"

@implementation WidgetsContainerView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];

    if (self) {
        [self setupView];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setupView];
    }

    return self;
}

- (void)setupView {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.layer.borderColor = [UIColor greenColor].CGColor;

    self.widgetViews = [NSMutableArray array];

    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    self.blurView.layer.masksToBounds = YES;
    self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
    self.blurView.layer.borderColor = [UIColor redColor].CGColor;
    [self addSubview:self.blurView];

    // Set constraints to make blur view match the size of WidgetsContainerView
    [self addConstraints:@[
         [self.blurView.topAnchor constraintEqualToAnchor:self.topAnchor
                                                 constant:-2],
         [self.blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                     constant:-4],
         [self.blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor
                                                    constant:2],
         [self.blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                      constant:4],
    ]];
}

- (void)reloadConfig {
    if (self.viewID) {
        [self loadUserDefaults:YES];
        NSDictionary *config = nil;

        for (NSDictionary *prop in [_userDefaults objectForKey: @"widgetProperties"]) {
            if ([[prop objectForKey:@"id"] isEqualToString:self.viewID]) {
                config = prop;
                break;
            }
        }

        // global config
        BOOL debugBorder = getBoolFromDictKey(_userDefaults, @"debugBorder", false);
        [self setDebugBorder:debugBorder];

        // Orientation Mode
        NSInteger oMode = getIntFromDictKey(config, @"orientationMode", 0);
        self.orientationMode = oMode;

        NSInteger align = getIntFromDictKey(config, @"alignment", 0);
        self.alignment = align;

        // blur config
        NSDictionary *blurDetails = [config valueForKey:@"blurDetails"] ? [config valueForKey:@"blurDetails"] : @{
                @"hasBlur": @(NO)
        };
        BOOL dynamicColor = getBoolFromDictKey(config, @"dynamicColor", true);
        BOOL hasBlur = !dynamicColor && getBoolFromDictKey(blurDetails, @"hasBlur");
        NSInteger blurCornerRadius = getIntFromDictKey(blurDetails, @"cornerRadius", 4);
        double blurAlpha = getDoubleFromDictKey(blurDetails, @"alpha", 1.0);
        BOOL isDarkEffect = getBoolFromDictKey(blurDetails, @"styleDark", true);

        [self setBlurAlpha:blurAlpha];
        [self setHasBlur:hasBlur];
        [self setBlurCornerRadius:blurCornerRadius];
        [self setBlurEffect:isDarkEffect];
    }
}

- (void)loadUserDefaults:(BOOL)forceReload {
    if (forceReload || !_userDefaults) {
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] mutableCopy] ? : [NSMutableDictionary dictionary];
    }
}

- (void)setHasBlur:(BOOL)hasBlur {
    if (hasBlur) {
        [self.blurView setHidden:NO];
    } else {
        [self.blurView setHidden:YES];
    }
}

- (void)setBlurEffect:(BOOL)isDark {
    if (isDark) {
        [self.blurView setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    } else {
        [self.blurView setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight]];
    }
}

- (void)setBlurAlpha:(double)alpha {
    self.blurView.alpha = alpha;
}

- (void)setBlurCornerRadius:(double)radius {
    self.blurView.layer.cornerRadius = radius;
}

- (void)setDebugBorder:(BOOL)show {
    if (show) {
        self.layer.borderWidth = 1.0;
        self.blurView.layer.borderWidth = 1.0;
    } else {
        self.layer.borderWidth = 0;
        self.blurView.layer.borderWidth = 0;
    }
}

- (void)setEnabled:(BOOL)enabled {
    self.isEnabled = enabled;
    self.userInteractionEnabled = enabled;
    [self setHidden:!enabled];

    if (enabled) {
        [self resumeTimer];
    } else {
        [self pauseTimer];
    }
}

- (void)setLandscape:(BOOL)landscape {
    self.isLandscape = landscape;
    [self showOrHide];
}

- (void)checkOrientationMode {
    if (self.isEnabled) {
        switch (self.orientationMode) {
            // Portrait
            case 1: {
                if (self.isLandscape) {
                    [self setHidden:YES];
                } else {
                    [self setHidden:NO];
                }
            }
            break;

            // Landscape
            case 2: {
                if (self.isLandscape) {
                    [self setHidden:NO];
                } else {
                    [self setHidden:YES];
                }
            }
            break;
        }
    }
}

- (void)showOrHide {
    BOOL allHidden = true;

    for (WidgetView *widgetView in self.widgetViews) {
        if (!widgetView.hidden) {
            allHidden = false;
            break;
        }
    }

    if (allHidden) {
        [self setHidden:YES];
    } else {
        [self checkOrientationMode];
    }
}

- (void)reloadWidgets {
    if (self.viewID) {
        [self loadUserDefaults:YES];
        NSDictionary *config = nil;

        for (NSDictionary *prop in [_userDefaults objectForKey: @"widgetProperties"]) {
            if ([[prop objectForKey:@"id"] isEqualToString:self.viewID]) {
                config = prop;
                break;
            }
        }

        // text alignment
        NSInteger textAlign = getIntFromDictKey(config, @"textAlignment", 1);
        // auto resizes
        BOOL autoResizes = getBoolFromDictKey(config, @"autoResizes", true);

        // Remove any existing widget views before adding new ones
        for (WidgetView *widgetView in self.widgetViews) {
            [widgetView removeFromSuperview];
        }

        [self cancleTimer];
        [self.widgetViews removeAllObjects];

        NSArray *widgetIDs = [config objectForKey:@"widgetIDs"] ? [config objectForKey:@"widgetIDs"] : @[];

        if ([widgetIDs count] > 0) {
            for (int i = 0; i < [widgetIDs count]; i++) {
                NSDictionary *widgetConfig = [widgetIDs objectAtIndex:i];
                WidgetView *widgetView = [[WidgetView alloc] initWithFrame:CGRectZero];
                widgetView.parentView = (WidgetsContainerView *)self;
                widgetView.viewID = getStringFromDictKey(widgetConfig, @"id");
                [widgetView reloadConfig];
                [self.widgetViews addObject:widgetView];
                [self addSubview:widgetView];

                if (self.alignment == 0) { // Horizontal Layout
                    [self addConstraints:@[
                         [widgetView.topAnchor constraintEqualToAnchor:self.topAnchor],
                         [widgetView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                    ]];

                    if (i == 0) { // First view
                        [self addConstraints:@[
                             [widgetView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor]
                        ]];

                        if ([widgetIDs count] == 1) { // If only one view
                            [widgetView setTextAlignment:textAlign];
                        } else { // If more than one view
                            if (textAlign == NSTextAlignmentLeft) { // Left-aligned when the first view is left-aligned
                                [widgetView setTextAlignment:NSTextAlignmentCenter];
                                [widgetView setContentHighPriority:YES];
                            } else { // Right-aligned when the first view is centered or right-aligned
                                [widgetView setTextAlignment:NSTextAlignmentRight];
                                [widgetView setContentHighPriority:NO];
                            }
                        }
                    } else {
                        WidgetView *previousWidgetView = self.widgetViews[i - 1];
                        [self addConstraints:@[
                             [widgetView.leadingAnchor constraintEqualToAnchor:previousWidgetView.trailingAnchor]
                        ]];

                        if ([widgetIDs count] >= 2) {
                            if (textAlign == NSTextAlignmentRight) { // Content compression resistance when the second and last view are right-aligned
                                [widgetView setTextAlignment:NSTextAlignmentCenter];
                                [widgetView setContentHighPriority:YES];
                            } else {
                                if ([widgetIDs count] > 2 && i < ([widgetIDs count] - 1)) { // Content compression resistance for the middle views
                                    [widgetView setTextAlignment:NSTextAlignmentCenter];
                                    [widgetView setContentHighPriority:YES];
                                } else {
                                    [widgetView setTextAlignment:NSTextAlignmentLeft];
                                    [widgetView setContentHighPriority:NO];
                                }
                            }
                        }
                    }
                } else { // Vertical Layout
                    [self addConstraints:@[
                         [widgetView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                         [widgetView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
                    ]];

                    if (i == 0) { // First view
                        [self addConstraints:@[
                             [widgetView.topAnchor constraintEqualToAnchor:self.topAnchor]
                        ]];
                    } else {
                        WidgetView *previousWidgetView = self.widgetViews[i - 1];
                        [self addConstraints:@[
                             [widgetView.topAnchor constraintEqualToAnchor:previousWidgetView.bottomAnchor]
                        ]];
                    }

                    [widgetView setTextAlignment:textAlign];
                }
            }

            if (self.alignment == 0) { // Horizontal Layout
                WidgetView *lastWidgetView = [self.widgetViews lastObject];
                [self addConstraints:@[
                     [lastWidgetView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
                ]];

                if (!autoResizes && [widgetIDs count] >= 2 && textAlign == NSTextAlignmentCenter) { // When there are more than two views and they are centered, the first and last views are the same size
                    WidgetView *firstWidgetView = [self.widgetViews firstObject];
                    [self addConstraints:@[
                         [firstWidgetView.widthAnchor constraintEqualToAnchor:lastWidgetView.widthAnchor]
                    ]];
                }
            } else { // Vertical Layout
                WidgetView *lastWidgetView = [self.widgetViews lastObject];
                [self addConstraints:@[
                     [lastWidgetView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                ]];
            }
        }

        // update interval
        double updateInterval = getDoubleFromDictKey(config, @"updateInterval", 1);

        dispatch_queue_t concurrentQueue = dispatch_queue_create("formatQueue", DISPATCH_QUEUE_SERIAL);
        __weak typeof(self) weakSelf = self;
        [[EZTimer shareInstance] timer:[NSString stringWithFormat:@"view_%@", self.viewID]
                         timerInterval:updateInterval
                                leeway:0.1
                            resumeType:EZTimerResumeTypeNow
                                 queue:EZTimerQueueTypeConcurrent
                             queueName:@"update"
                               repeats:YES
                                action:^(NSString *timerName) {
            for (WidgetView *widgetView in weakSelf.widgetViews) {
                dispatch_async(concurrentQueue, ^{
                                   [widgetView updateLabel];
                               });
            }
        }];

        BOOL isEnabled = getBoolFromDictKey(config, @"isEnabled", true);
        [self setEnabled:isEnabled];
    }
}

- (void)cancleTimer {
    [[EZTimer shareInstance] cancel:[NSString stringWithFormat:@"view_%@", self.viewID]];
}

- (void)resumeTimer {
    [[EZTimer shareInstance] resume:[NSString stringWithFormat:@"view_%@", self.viewID]];
}

- (void)pauseTimer {
    [[EZTimer shareInstance] pause:[NSString stringWithFormat:@"view_%@", self.viewID]];
}

@end
