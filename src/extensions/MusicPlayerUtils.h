#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MusicPlayerUtils : NSObject
+ (BOOL)hasBluetoothHeadset;
+ (BOOL)hasWiredHeadset;
+ (NSString*)getLyricsKeyByBundleIdentifier:(NSString *)bundleid lyricsType:(int)lyricsType bluetoothType:(int)bluetoothType wiredType:(int)wiredType unsupported:(BOOL)unsupported;
+ (NSString*)getLyricsKeyByType:(int)type;
@end