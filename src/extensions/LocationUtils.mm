#import "LocationUtils.h"

@implementation LocationUtils

+(instancetype)sharedInstance {
	static LocationUtils *_shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_shared = [[self alloc] init];
	});
	return _shared;
}

-(instancetype)init {
	self = [super init];

	if (self != nil) {
        self.location = nil;
		self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.allowsBackgroundLocationUpdates = YES;
        self.locationManager.showsBackgroundLocationIndicator = NO;
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
	}
	return self;
}

- (void)getCurrentLocation:(void (^)(NSError *, NSString *))block  {
    // NSLog(@"boom %d", [CLLocationManager locationServicesEnabled]);
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
        self.block = block;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *currentLocation = [locations lastObject];
    // NSLog(@"boom Latitude: %f, Longitude: %f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
    
    self.block(nil, [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.longitude, currentLocation.coordinate.latitude]);

    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // NSLog(@"boom Location manager failed with error: %@", error);
    self.block(error, nil);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            [manager startUpdatingLocation];
            break;
        case kCLAuthorizationStatusDenied:
            break;
        case kCLAuthorizationStatusRestricted:
            break;
        case kCLAuthorizationStatusNotDetermined:
            break;
        default:
            break;
    }
}

@end