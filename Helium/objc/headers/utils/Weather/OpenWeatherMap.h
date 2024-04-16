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

- (NSDictionary *)fetchWeatherForLocation:(NSString *)location;
- (NSString *)UVIndex;

@end

#endif /* OpenWeatherMap_h */
