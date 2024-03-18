#import "WeatherUtils.h"
#import "../LocationUtils.h"
#import <CoreLocation/CoreLocation.h>

@implementation WeatherUtils
+ (NSString*)formatWeatherData:(NSDictionary *)data format:(NSString *)format {
    if(data) {
        @try {
            format = [format stringByReplacingOccurrencesOfString:@"{n}" withString:data[@"conditions"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{e}" withString:data[@"conditions_emoji"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{l}" withString:data[@"location"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{uvi}" withString:data[@"uv_index"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{aqi}" withString:data[@"aqi"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{t}" withString:data[@"temperature"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{ts}" withString:data[@"temperature_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{bt}" withString:data[@"feels_like"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{bts}" withString:data[@"feels_like_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{lt}" withString:data[@"low_temperature"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{lts}" withString:data[@"low_temperature_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{ht}" withString:data[@"high_temperature"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{hts}" withString:data[@"high_temperature_with_symbol"]?:@""];
            
            format = [format stringByReplacingOccurrencesOfString:@"{ws}" withString:data[@"wind_speed"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{wsu}" withString:data[@"wind_speed_with_unit"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{wd}" withString:data[@"wind_direction"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{wds}" withString:data[@"wind_direction_short"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{h}" withString:data[@"humidity"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{hs}" withString:data[@"humidity_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{v}" withString:data[@"visibility"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{vu}" withString:data[@"visibility_with_unit"]?:@""];
            
            format = [format stringByReplacingOccurrencesOfString:@"{pp}" withString:data[@"precipitation_next_hour"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{pps}" withString:data[@"precipitation_next_hour_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{ppn}" withString:data[@"precipitation_percent_next_hour"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{ppns}" withString:data[@"precipitation_percent_next_hour_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{pp24}" withString:data[@"precipitation_24h"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{pp24u}" withString:data[@"precipitation_24h_with_unit"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{ps}" withString:data[@"pressure"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{psu}" withString:data[@"pressure_with_unit"]?:@""];
        }
        @catch (NSException *exception) {
            NSLog(@"[ERROR]\nstr[%@]\nexception[%@]", format, exception);
            format = NSLocalizedString(@"error", comment:@"");
        }
    } else {
        format = NSLocalizedString(@"error", comment:@"");
    }
    return format;
}

+ (NSArray *)getGeocodeByName:(NSString *)name {
    __block NSArray *arr = nil;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [geocoder geocodeAddressString:name completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"boom error: %@", error);
        arr = placemarks;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    return arr;
}

+ (CLPlacemark *)getPlacemarkByGeocode:(NSString *)geolocation {
    __block CLPlacemark *placemark = nil;
    NSString *longtitude, *latitude;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    if (geolocation == nil || geolocation.length == 0)
        return placemark;
    else {
        NSArray *arr = [geolocation componentsSeparatedByString:@","];
        longtitude = [arr firstObject];
        latitude = [arr lastObject];
    }
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longtitude doubleValue]];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"boom error: %@", error);
        // NSLog(@"boom : %@", placemarks);
        if (placemarks != nil && [placemarks count] > 0) {
            placemark = ((CLPlacemark*)[placemarks firstObject]);
            // NSArray *formattedAddressLines = placemark.addressDictionary[@"FormattedAddressLines"];
            // NSString *addressString = [formattedAddressLines componentsJoinedByString:@"\n"];
            // NSLog(@"boom Address: %@", placemark.addressDictionary);
            // NSLog(@"boom : %@", addressString);
        }
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));
    return placemark;
}

@end