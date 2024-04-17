//
//  OpenWeatherMap.h
//  Helium
//
//  Created by Fuuko on 2024/4/16.
//

#ifndef OpenWeatherMap_h
#define OpenWeatherMap_h

#import <Foundation/Foundation.h>
#import "IWeather.h"

@interface OpenWeatherMap : IWeather

@property (nonatomic, strong) NSDictionary *weather;
@property (nonatomic, strong) NSDictionary *forecast;

- (NSDictionary *)fetchWeatherForLocation:(NSString *)location;
- (NSDictionary *)fetchForecastForLocation:(NSString *)location;

@end

#endif /* OpenWeatherMap_h */
