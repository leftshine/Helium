#import <Foundation/Foundation.h>

@interface MediaRemoteManager : NSObject

+ (instancetype)sharedManager;

- (void)getNowPlayingInfoWithCompletion:(void (^)(NSDictionary *info))completion;
- (void)getBundleIdentifierWithCompletion:(void (^)(NSString *bundleIdentifier))completion;

@end
