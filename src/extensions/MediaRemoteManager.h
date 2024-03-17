#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^NowPlayingInfoCompletionBlock)(NSDictionary * _Nullable info);
typedef void (^BundleIdentifierCompletionBlock)(NSString * _Nullable bundleIdentifier);
typedef void (^ApplicationPlaybackStateCompletionBlock)(bool isPlaying);

@interface MediaRemoteManager : NSObject

+ (instancetype)sharedManager;

- (void)getNowPlayingInfoWithCompletion:(NowPlayingInfoCompletionBlock)completion;
- (void)getBundleIdentifierWithCompletion:(BundleIdentifierCompletionBlock)completion;
- (void)getNowPlayingApplicationIsPlayingWithCompletion:(ApplicationPlaybackStateCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END