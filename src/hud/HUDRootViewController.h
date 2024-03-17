#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HUDRootViewController: UIViewController
- (void)pauseLoopTimer;
- (void)resumeLoopTimer;
- (void)reloadUserDefaults;
- (void)reloadWidgets;
@end

NS_ASSUME_NONNULL_END