#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationUtils : NSObject <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) NSString *location;
@property (nonatomic, copy) void (^block) (NSError *error,NSString *result);
// @property (nonatomic, strong) dispatch_semaphore_t semaphore;

+ (instancetype)sharedInstance;
- (void)getCurrentLocation:(void (^)(NSError *, NSString *))block;
@end