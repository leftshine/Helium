//
//  HUDHelper.h
//  Helium
//
//  Created by Fuuko on 2024/3/27.
//

#ifndef HUDHelper_h
#define HUDHelper_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN BOOL IsHUDEnabled(void);
OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);
OBJC_EXTERN void waitForNotification(void (^onFinish)(), BOOL isEnabled);
OBJC_EXTERN void runMainHUD(void);

NS_ASSUME_NONNULL_END

#endif /* HUDHelper_h */
