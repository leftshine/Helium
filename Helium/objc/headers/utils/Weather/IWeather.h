//
//  IWeather.h
//  Helium
//
//  Created by Fuuko on 2024/4/15.
//

#ifndef IWeather_h
#define IWeather_h

#import <UIKit/UIKit.h>
#import "LocationUtils.h"
@class CLPlacemark;

typedef void (^IWeatherDataCallbackBlock)(NSDictionary *weatherData);
typedef void (^IWeatherLocationCallbackBlock)(NSString *location);

@interface IWeather : NSObject
@property (nonatomic) NSString *apiKey;
@property (nonatomic) BOOL useMetric;
@property (nonatomic) BOOL useFahrenheit;
@property (nonatomic) NSString *locale;
@property (nonatomic, strong) CLPlacemark *city;
@property (nonatomic) long long lastUpdateTime;
@property (nonatomic, strong) NSString *lastLocation;
@property (nonatomic, strong) NSString *location;
@property (nonatomic) double fontSize;
@property (nonatomic) BOOL useCurrentLocation;

+ (instancetype)sharedInstance;

- (NSString *)conditionsEmoji;
- (UIImage *)conditionsImage:(double)fontSize;
- (NSString *)conditionsDescription;
- (NSString *)temperature;
- (NSString *)temperature:(BOOL)withSymbol;
- (NSString *)feelsLike;
- (NSString *)feelsLike:(BOOL)withSymbol;
- (NSString *)highDescription;
- (NSString *)highDescription:(BOOL)withSymbol;
- (NSString *)lowDescription;
- (NSString *)lowDescription:(BOOL)withSymbol;
- (NSString *)windSpeed;
- (NSString *)windSpeed:(BOOL)withUnit;
- (NSString *)windDirection;
- (NSString *)humidity;
- (NSString *)humidity:(BOOL)withSymbol;
- (NSString *)visibility;
- (NSString *)visibility:(BOOL)withUnit;
- (NSString *)pressure;
- (NSString *)pressure:(BOOL)withUnit;
- (NSString *)precipitationNextHour;
- (NSString *)precipitationNextHour:(BOOL)withSymbol;
- (NSString *)precipitationPercentNextHour;
- (NSString *)precipitationPercentNextHour:(BOOL)withSymbol;
- (NSString *)precipitationPast24Hours;
- (NSString *)precipitationPast24Hours:(BOOL)withUnit;

- (NSMeasurementFormatter *)sharedNSMeasurementFormatter;
- (NSDictionary *)getWeatherData;
- (void)updateWeather:(IWeatherDataCallbackBlock)dataCallback;
- (void)updateLocation:(IWeatherLocationCallbackBlock)locationCallback;
- (NSString *)formatFloat:(double)f;

@end

#endif /* IWeather_h */
