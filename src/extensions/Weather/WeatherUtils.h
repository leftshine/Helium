#import <Foundation/Foundation.h>

@interface WeatherUtils : NSObject
+ (NSString*)formatWeatherData:(NSDictionary *)data format:(NSString *)format;
+ (NSArray *)getGeocodeByName:(NSString *)name;
+ (NSString *)getNameByGeocode:(NSString *)geolocation;
@end