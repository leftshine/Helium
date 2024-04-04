//
//  LocationUtils.h
//  Helium
//
//  Created by Fuuko on 2024/3/28.
//

#ifndef LocationUtils_h
#define LocationUtils_h
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

@interface LocationUtils : NSObject <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) NSString *location;
@property (nonatomic, copy) void (^ block) (NSError *error, NSString *result);
// @property (nonatomic, strong) dispatch_semaphore_t semaphore;

+ (instancetype)sharedInstance;
- (void)getCurrentLocation:(void (^)(NSError *, NSString *))block;
@end

//NS_ASSUME_NONNULL_END

#endif /* LocationUtils_h */
