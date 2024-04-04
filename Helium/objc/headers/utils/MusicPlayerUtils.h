//
//  MusicPlayerUtils.h
//  Helium
//
//  Created by Fuuko on 2024/3/28.
//

#ifndef MusicPlayerUtils_h
#define MusicPlayerUtils_h
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MusicPlayerUtils : NSObject
+ (BOOL)hasBluetoothHeadset;
+ (BOOL)hasWiredHeadset;
+ (NSString *)getLyricsKeyByBundleIdentifier:(NSString *)bundleid lyricsType:(NSInteger)lyricsType bluetoothType:(NSInteger)bluetoothType wiredType:(NSInteger)wiredType unsupported:(BOOL)unsupported autoDetected:(BOOL)autoDetected;
+ (NSString *)getLyricsKeyByType:(NSInteger)type;
@end

NS_ASSUME_NONNULL_END

#endif /* MusicPlayerUtils_h */
