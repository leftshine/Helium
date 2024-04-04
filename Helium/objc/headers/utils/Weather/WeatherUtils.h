#import <Foundation/Foundation.h>
@class CLPlacemark;

@interface WeatherUtils : NSObject
+ (NSString *)formatWeatherData:(NSDictionary *)data format:(NSString *)format;
+ (NSArray *)getGeocodeByName:(NSString *)name;
+ (CLPlacemark *)getPlacemarkByGeocode:(NSString *)geolocation;
@end
