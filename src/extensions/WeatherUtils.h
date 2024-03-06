#import <Foundation/Foundation.h>

@interface WeatherUtils : NSObject
+ (NSString*)formatWeatherData:(NSDictionary *)data format:(NSString *)format;
@end