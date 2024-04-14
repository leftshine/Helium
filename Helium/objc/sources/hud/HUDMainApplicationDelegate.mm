//
//  HUDMainApplicationDelegate.mm
//  Helium
//
//  Created by lemin on 10/5/23.
//

#import <objc/runtime.h>

#import "HUDMainApplicationDelegate.h"
#import "HUDMainWindow.h"
#import "HUDRootViewController.h"

#import "FontUtils.h"
#import "NSBundle+Language.h"
#import "TWCWeather.h"

#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"

#import "Const.h"
#import "Sentry.h"

@implementation HUDMainApplicationDelegate {
    HUDRootViewController *_rootViewController;
    SBSAccessibilityWindowHostingController *_windowHostingController;
}

- (instancetype)init
{
    if (self = [super init]) {
#if DEBUG
        os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate init]");
#endif

        // load fonts from app
        [[FontUtils shared] loadFontsFromFolder:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath],  @"/fonts"]];
        // load fonts from documents
        [[FontUtils shared] loadFontsFromFolder:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];

        // set language
        // [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
        // [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLocale"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:[self dateLocale], nil] forKey:@"AppleLanguages"];
        // [[NSUserDefaults standardUserDefaults] setObject:[self dateLocale] forKey:@"AppleLocale"];

        [[NSUserDefaults standardUserDefaults] synchronize];
        [NSBundle setLanguage:[self dateLocale]];

        [TWCWeather sharedInstance];
    }

    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions
{
#if DEBUG
    os_log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);
#endif

    _rootViewController = [[HUDRootViewController alloc] init];

    self.window = [[HUDMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_rootViewController];

    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];

    _windowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init];
    unsigned int _contextId = [self.window _contextId];
    double windowLevel = [self.window windowLevel];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // [_windowHostingController registerWindowWithContextID:_contextId atLevel:windowLevel];
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:_windowHostingController];
    [invocation setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
    [invocation setArgument:&_contextId atIndex:2];
    [invocation setArgument:&windowLevel atIndex:3];
    [invocation invoke];
#pragma clang diagnostic pop

    [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
        options.dsn = @SENTRY_DSN;
        options.debug = YES;     // Enabled debug when first installing is always helpful
        options.environment = @SENTRY_ENV;

        // Enable all experimental features
        options.attachViewHierarchy = YES;
        options.enablePreWarmedAppStartTracing = YES;
        options.enableTimeToFullDisplayTracing = YES;
        options.swiftAsyncStacktraces = YES;
//        options.tracesSampleRate = @1.0;
    }];

    return YES;
}

- (NSString *)dateLocale
{
    NSDictionary *_userDefaults = [[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] mutableCopy] ? : [NSMutableDictionary dictionary];
    NSString *locale = [_userDefaults objectForKey:@"dateLocale"];

    return locale ? locale : @"en";
}

@end
