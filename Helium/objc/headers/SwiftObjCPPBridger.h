//
//  SwiftObjCPPBridger.h
//  Helium
//
//  Created by lemin on 10/13/23.
//

#ifndef SwiftObjCPPBridger_h
#define SwiftObjCPPBridger_h

#import <Foundation/Foundation.h>

#pragma mark - HUD Functions

BOOL IsHUDEnabledBridger(void);
void SetHUDEnabledBridger(BOOL isEnabled);
void waitForNotificationBridger(void (^onFinish)(void), BOOL isEnabled);
void runMainHUDBridger(void);
#endif /* SwiftObjCPPBridger_h */
