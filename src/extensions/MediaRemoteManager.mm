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

- (NSDictionary *)getNowPlayingInfo {
    __block NSDictionary *info = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(CFDictionaryRef information) {
        info = (__bridge NSDictionary*)information;
        dispatch_semaphore_signal(semaphore);
    });

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    return info;
}

- (NSString *)getBundleIdentifier {
    __block NSString *bundleIdentifier = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    MRMediaRemoteGetNowPlayingClient(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(id client) {
        CFStringRef bundleid = MRNowPlayingClientGetBundleIdentifier(client);
        bundleIdentifier = (__bridge NSString*)bundleid;
        dispatch_semaphore_signal(semaphore);
    });

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    return bundleIdentifier;
}

- (bool)getNowPlayingApplicationIsPlaying {
    __block bool isPlaying = false;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(Boolean playing) {
        isPlaying = playing;
        dispatch_semaphore_signal(semaphore);
    });

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    return isPlaying;
}

@end
