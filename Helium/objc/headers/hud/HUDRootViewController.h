//
//  HUDRootViewController.h
//  Helium
//
//  Created by Fuuko on 2024/3/28.
//

#ifndef HUDRootViewController_h
#define HUDRootViewController_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HUDRootViewController : UIViewController
- (void)pauseLoopTimer;
- (void)resumeLoopTimer;
- (void)reloadUserDefaults;
- (void)reloadWidgets;
@end

NS_ASSUME_NONNULL_END

#endif /* HUDRootViewController_h */
