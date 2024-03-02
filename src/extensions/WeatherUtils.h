#import <Foundation/Foundation.h>

@interface WeatherUtils : NSObject
+ (NSString *)getWeatherIcon:(NSString *)text;
+ (NSString*)formatWeatherData:(NSDictionary *)data format:(NSString *)format;
@end