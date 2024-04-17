//
//  ColorfulClouds.h
//  Helium
//
//  Created by Fuuko on 2024/4/15.
//

#ifndef ColorfulClouds_h
#define ColorfulClouds_h

#import <Foundation/Foundation.h>
#import "IWeather.h"

@interface ColorfulClouds : IWeather

@property (nonatomic, strong) NSDictionary *weatherData;

- (NSDictionary *)fetchWeatherForLocation:(NSString *)location;

- (NSString *)UVIndex;
- (NSString *)airQualityIndex;

@end

#endif /* ColorfulClouds_h */
