#import "MediaRemote.h"
#import "MediaRemoteManager.h"

@implementation MediaRemoteManager

+ (instancetype)sharedManager {
    static MediaRemoteManager *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)getNowPlayingInfoWithCompletion:(NowPlayingInfoCompletionBlock)completion {
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(CFDictionaryRef information) {
        NSDictionary *info = (__bridge NSDictionary *)information;
        completion(info);
    });
}

- (void)getBundleIdentifierWithCompletion:(BundleIdentifierCompletionBlock)completion {
    MRMediaRemoteGetNowPlayingClient(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(id client) {
        CFStringRef bundleid = MRNowPlayingClientGetBundleIdentifier(client);
        NSString *bundleIdentifier = (__bridge NSString *)bundleid;
        completion(bundleIdentifier);
    });
}

- (void)getNowPlayingApplicationIsPlayingWithCompletion:(ApplicationPlaybackStateCompletionBlock)completion {
    MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(Boolean playing) {
        bool isPlaying = playing;
        completion(isPlaying);
    });
}

@end
