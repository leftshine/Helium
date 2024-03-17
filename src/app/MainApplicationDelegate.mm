#import "MainApplicationDelegate.h"
#import "MainApplication.h"
#import "Helium-Swift.h"

#import "../hud/HUDHelper.h"
#import "../extensions/FontUtils.h"
#import "../extensions/Weather/TWCWeather.h"
#import "../helpers/private_headers/UIApplication+Private.h"

@implementation MainApplicationDelegate

- (instancetype)init {
    if (self = [super init]) {
        os_log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate init]");
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions {
    os_log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);

    // load fonts from app
    [FontUtils loadFontsFromFolder:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath],  @"/fonts"]];
    // load fonts from documents
    [FontUtils loadFontsFromFolder:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
    [FontUtils loadAllFonts];

    [TWCWeather sharedInstance];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:[[[ContentInterface alloc] init] createUI]];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    if ([shortcutItem.type isEqualToString:@"com.leemin.helium.shortcut.toggle-hud"]) {
        SetHUDEnabled(!IsHUDEnabled());
        [[UIApplication sharedApplication] suspend];
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if ([url.scheme isEqualToString:@"helium"]) {
        if ([url.host isEqualToString:@"toggle"]) {
            SetHUDEnabled(!IsHUDEnabled());
            [[UIApplication sharedApplication] suspend];
        } else if ([url.host isEqualToString:@"on"] && !IsHUDEnabled()) {
            SetHUDEnabled(true);
            [[UIApplication sharedApplication] suspend];
        } else if ([url.host isEqualToString:@"off"] && IsHUDEnabled()) {
            SetHUDEnabled(false);
            [[UIApplication sharedApplication] suspend];
        } else {
            [[UIApplication sharedApplication] suspend];
        }
    }
    return NO;
}

@end
