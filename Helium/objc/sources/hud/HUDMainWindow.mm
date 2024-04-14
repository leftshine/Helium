//
//  HUDMainWindow.mm
//  Helium
//
//  Created by lemin on 10/5/23.
//

#import "HUDMainWindow.h"
#import "HUDRootViewController.h"

@implementation HUDMainWindow

+ (BOOL)_isSystemWindow {
    return YES;
}

- (BOOL)_isWindowServerHostingManaged {
    return NO;
}

- (BOOL)_ignoresHitTest {
    return YES;
}

- (BOOL)_isSecure {
    return YES;
}

- (BOOL)_shouldCreateContextAsSecure {
    return YES;
}

@end
