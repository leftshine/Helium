#import <Foundation/Foundation.h>
#import "../helpers/private_headers/MediaRemote.h"

@interface MediaRemoteManager : NSObject

+ (instancetype)sharedManager;

- (NSDictionary *)getNowPlayingInfo;
- (NSString *)getBundleIdentifier;
- (bool)getNowPlayingApplicationIsPlaying;

@end