#import <Foundation/Foundation.h>
#import "../helpers/private_headers/Weather/WeatherHeaders.h"

@interface QWeather : NSObject
@property (nonatomic) NSString *apiKey;
@property (nonatomic) BOOL useMetric;
@property (nonatomic) BOOL useFahrenheit;
@property (nonatomic) BOOL freeSub;
@property (nonatomic) NSString *locale;
@property (nonatomic) NSDictionary *now;
@property (nonatomic) NSDictionary *daily;
@property (nonatomic) NSDictionary *hourly;
@property (nonatomic) NSDictionary *city;

+(instancetype)sharedInstance;
- (NSString *)getWeatherIcon:(NSString *)text;
- (NSDictionary *)fetchNowWeatherForLocation:(NSString *)location;
- (NSDictionary *)fetchTodayWeatherForLocation:(NSString *)location;
- (NSDictionary *)fetch24HoursWeatherForLocation:(NSString *)location;
- (NSData *)fetchLocationIDForName:(NSString *)name;


-(NSString *)locationName;
-(NSString *)conditionsEmoji;
-(UIImage *)conditionsImage:(double) fontSize;
-(NSString *)conditionsDescription;
-(NSString *)temperature;
-(NSString *)temperature:(BOOL) withSymbol;
-(NSString *)feelsLike;
-(NSString *)feelsLike:(BOOL) withSymbol;
-(NSString *)highDescription;
-(NSString *)highDescription:(BOOL) withSymbol;
-(NSString *)lowDescription;
-(NSString *)lowDescription:(BOOL) withSymbol;
-(NSString *)windSpeed;
-(NSString *)windSpeed:(BOOL) withUnit;
-(NSString *)windDirection;
-(NSString *)humidity;
-(NSString *)humidity:(BOOL) withSymbol;
-(NSString *)visibility;
-(NSString *)visibility:(BOOL) withUnit;
-(NSString *)pressure;
-(NSString *)pressure:(BOOL) withUnit;
-(NSString *)precipitationNextHour;
-(NSString *)precipitationNextHour:(BOOL) withSymbol;
-(NSString *)precipitationPercentNextHour;
-(NSString *)precipitationPercentNextHour:(BOOL) withSymbol;
-(NSString *)precipitationPast24Hours;
-(NSString *)precipitationPast24Hours:(BOOL) withUnit;

- (NSDictionary *)getWeatherData:(double) fontSize;
- (NSString *)getDataFrom:(NSString *)url;
- (void)updateWeather:(NSString *)location;
@end