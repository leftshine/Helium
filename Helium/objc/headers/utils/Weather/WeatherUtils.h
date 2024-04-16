//
//  WeatherUtils.h
//  Helium
//
//  Created by Fuuko on 2024/4/15.
//

#ifndef WeatherUtils_h
#define WeatherUtils_h

#import <Foundation/Foundation.h>
@class CLPlacemark;

@interface WeatherUtils : NSObject
+ (NSString *)formatWeatherData:(NSDictionary *)data format:(NSString *)format;
+ (NSArray *)getGeocodeByName:(NSString *)name;
+ (CLPlacemark *)getPlacemarkByGeocode:(NSString *)geolocation;
@end

#endif /* WeatherUtils_h */
