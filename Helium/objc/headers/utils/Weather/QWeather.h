//
//  QWeather.h
//  Helium
//
//  Created by Fuuko on 2024/4/15.
//

#ifndef QWeather_h
#define QWeather_h

#import <Foundation/Foundation.h>
#import "IWeather.h"

@interface QWeather : IWeather

@property (nonatomic) BOOL freeSub;
@property (nonatomic, strong) NSDictionary *now;
@property (nonatomic, strong) NSDictionary *daily;
@property (nonatomic, strong) NSDictionary *hourly;

- (NSDictionary *)fetchNowWeatherForLocation:(NSString *)location;
- (NSDictionary *)fetchTodayWeatherForLocation:(NSString *)location;
- (NSDictionary *)fetch24HoursWeatherForLocation:(NSString *)location;

@end

#endif /* QWeather_h */
