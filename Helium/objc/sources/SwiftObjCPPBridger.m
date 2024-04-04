//
//  SwiftObjCPPBridger.m
//  Helium
//
//  Created by lemin on 10/13/23.
//

#import "SwiftObjCPPBridger.h"

#pragma mark - HUD Functions

extern BOOL IsHUDEnabled(void);
extern void SetHUDEnabled(BOOL isEnabled);
extern void waitForNotification(void (^onFinish)(void), BOOL isEnabled);
extern void runMainHUD(void);

BOOL IsHUDEnabledBridger(void) {
    return (int)IsHUDEnabled();
}

void SetHUDEnabledBridger(BOOL isEnabled) {
    SetHUDEnabled(isEnabled);
}

void waitForNotificationBridger(void (^onFinish)(void), BOOL isEnabled) {
    waitForNotification(onFinish, isEnabled);
}

void runMainHUDBridger(void) {
    runMainHUD();
}
