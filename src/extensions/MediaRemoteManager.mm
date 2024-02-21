#import "MediaRemoteManager.h"

typedef void (*MRMediaRemoteGetNowPlayingInfoFunction)(dispatch_queue_t queue, void (^completionHandler)(NSDictionary *information));
typedef NSString * (*MRNowPlayingClientGetBundleIdentifierFunction)(id client);
typedef void (*MRMediaRemoteGetNowPlayingClientFunction)(dispatch_queue_t queue, void (^completionHandler)(id client));

@implementation MediaRemoteManager {
    CFBundleRef _bundle;
    MRMediaRemoteGetNowPlayingInfoFunction MRMediaRemoteGetNowPlayingInfo;
    MRNowPlayingClientGetBundleIdentifierFunction MRNowPlayingClientGetBundleIdentifier;
    MRMediaRemoteGetNowPlayingClientFunction MRMediaRemoteGetNowPlayingClient;
}

+ (instancetype)sharedManager {
    static MediaRemoteManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _bundle = CFBundleCreate(NULL, (__bridge CFURLRef)[NSURL URLWithString:@"/System/Library/PrivateFrameworks/MediaRemote.framework"]);
        if (!_bundle) {
            NSLog(@"Failed to load MediaRemote framework.");
        } else {
            MRMediaRemoteGetNowPlayingInfo = (MRMediaRemoteGetNowPlayingInfoFunction)CFBundleGetFunctionPointerForName(_bundle, CFSTR("MRMediaRemoteGetNowPlayingInfo"));
            MRNowPlayingClientGetBundleIdentifier = (MRNowPlayingClientGetBundleIdentifierFunction)CFBundleGetFunctionPointerForName(_bundle, CFSTR("MRNowPlayingClientGetBundleIdentifier"));
            MRMediaRemoteGetNowPlayingClient = (MRMediaRemoteGetNowPlayingClientFunction)CFBundleGetFunctionPointerForName(_bundle, CFSTR("MRMediaRemoteGetNowPlayingClient"));
        }
    }
    return self;
}

- (void)dealloc {
    if (_bundle) {
        CFRelease(_bundle);
    }
}

- (void)getNowPlayingInfoWithCompletion:(void (^)(NSDictionary *info))completion {
    if (MRMediaRemoteGetNowPlayingInfo) {
        MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(NSDictionary *information) {
            completion(information);
        });
    } else {
        NSLog(@"Failed to get function pointer for MRMediaRemoteGetNowPlayingInfo.");
        completion(nil);
    }
}

- (void)getBundleIdentifierWithCompletion:(void (^)(NSString *bundleIdentifier))completion {
    if (MRNowPlayingClientGetBundleIdentifier && MRMediaRemoteGetNowPlayingClient) {
        MRMediaRemoteGetNowPlayingClient(dispatch_get_main_queue(), ^(id client) {
            NSString *bundleIdentifier = MRNowPlayingClientGetBundleIdentifier(client);
            completion(bundleIdentifier);
        });
    } else {
        NSLog(@"Failed to get function pointers for MRNowPlayingClientGetBundleIdentifier and/or MRMediaRemoteGetNowPlayingClient.");
        completion(nil);
    }
}

@end
