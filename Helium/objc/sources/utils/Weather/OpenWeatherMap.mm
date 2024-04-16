//
//  OpenWeatherMap.mm
//  Helium
//
//  Created by Fuuko on 2024/4/16.
//

#import <CoreLocation/CoreLocation.h>
#import "DateTimeUtils.h"
#import "LocationUtils.h"
#import "NetworkUtils.h"
#import "OpenWeatherMap.h"
#import "UsefulFunctions.h"
#import "WeatherUtils.h"
#import "WeatherWindSpeedFormatter.h"

@implementation OpenWeatherMap

+ (instancetype)sharedInstance {
    static OpenWeatherMap *_shared = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });
    return _shared;
}

- (instancetype)init {
    self = [super init];

    if (self != nil) {
        self.useFahrenheit = NO;
        self.useMetric = YES;
    }

    return self;
}

- (NSDictionary *)fetchWeatherForLocation:(NSString *)location {
    NSArray *components = [location componentsSeparatedByString:@","];
    NSString *res = [NetworkUtils getDataFrom:[NSString stringWithFormat:@"https://app.owm.io/app/1.0/weather?lat=%@&lon=%@&units=%@&appid=%@&exclude=minutely,alerts", components[1], components[0], self.useMetric ? @"metric" : @"imperial", self.apiKey]];
    NSData *data = [res dataUsingEncoding:NSUTF8StringEncoding];
    NSError *erro = nil;

    if (data != nil) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&erro ];
        return json;
    }

    return nil;
}

- (NSString *)locationName {
    return self.city.subLocality ? : @"--";
}

- (NSString *)temperature {
    return [self temperature:NO];
}

- (NSString *)temperature:(BOOL)withSymbol {
    NSString *temperatureString = nil;

    if (self.weatherData) {
        NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey(self.weatherData[@"current"], @"temp") unit:[self useMetric] ? NSUnitTemperature.celsius : NSUnitTemperature.fahrenheit];
        measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : [measurement measurementByConvertingToUnit:NSUnitTemperature.celsius];

        if (withSymbol) {
            temperatureString = [formatter stringFromMeasurement:measurement];
        } else {
            temperatureString = [self formatFloat:measurement.doubleValue];
        }
    } else {
        temperatureString = @"--";
    }

    return temperatureString;
}

- (NSString *)feelsLike {
    return [self feelsLike:NO];
}

- (NSString *)feelsLike:(BOOL)withSymbol {
    NSString *temperatureString = nil;

    if (self.weatherData) {
        NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey(self.weatherData[@"current"], @"feels_like") unit:[self useMetric] ? NSUnitTemperature.celsius : NSUnitTemperature.fahrenheit];
        measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : [measurement measurementByConvertingToUnit:NSUnitTemperature.celsius];

        if (withSymbol) {
            temperatureString = [formatter stringFromMeasurement:measurement];
        } else {
            temperatureString = [self formatFloat:measurement.doubleValue];
        }
    } else {
        temperatureString = @"--";
    }

    return temperatureString;
}

- (NSString *)conditionsEmoji {
    NSString *weatherEmoji = @"";

    if (self.weatherData) {
        NSString *weatherCode = getStringFromDictKey([self.weatherData[@"current"][@"weather"] firstObject], @"icon", @"UNKNOWN");

        if ([weatherCode isEqualToString:@"01d"]) {
            weatherEmoji = @"☀️";
        } else if ([weatherCode isEqualToString:@"01n"]) {
            weatherEmoji = @"🌙";
        } else if ([weatherCode isEqualToString:@"02d"]) {
            weatherEmoji = @"⛅️";
        } else if ([weatherCode isEqualToString:@"02n"]) {
            weatherEmoji = @"🌥️";
        } else if ([weatherCode isEqualToString:@"03d"] || [weatherCode isEqualToString:@"03n"] || [weatherCode isEqualToString:@"04d"] || [weatherCode isEqualToString:@"04n"]) {
            weatherEmoji = @"☁️";
        } else if ([weatherCode isEqualToString:@"09d"] || [weatherCode isEqualToString:@"09n"] || [weatherCode isEqualToString:@"10d"] || [weatherCode isEqualToString:@"10n"]) {
            weatherEmoji = @"🌧️";
        } else if ([weatherCode isEqualToString:@"11d"] || [weatherCode isEqualToString:@"11n"]) {
            weatherEmoji = @"⛈️";
        } else if ([weatherCode isEqualToString:@"13d"] || [weatherCode isEqualToString:@"13n"]) {
            weatherEmoji = @"🌨️";
        } else if ([weatherCode isEqualToString:@"50d"] || [weatherCode isEqualToString:@"50n"]) {
            weatherEmoji = @"🌫️";
        } else {
            weatherEmoji = @"❓";
        }
    }

    return weatherEmoji;
}

- (UIImage *)conditionsImage:(double)fontSize {
    UIImage *weatherImage = nil;
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    BOOL isDayTime = (hour >= 6 && hour < 18); // Assuming day time is between 6 AM and 6 PM

    if (self.weatherData) {
        NSString *weatherCode = getStringFromDictKey([self.weatherData[@"current"][@"weather"] firstObject], @"icon", @"UNKNOWN");

        // NSLog(@"boom %d", weatherCode);
        if ([weatherCode isEqualToString:@"01d"]) {
            weatherImage = [UIImage systemImageNamed:@"sun.max.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"01n"]) {
            weatherImage = [UIImage systemImageNamed:@"moon.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"02d"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.sun.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"02n"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.moon.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"03d"] || [weatherCode isEqualToString:@"03n"] || [weatherCode isEqualToString:@"04d"] || [weatherCode isEqualToString:@"04n"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"09d"] || [weatherCode isEqualToString:@"09n"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.drizzle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"10d"] || [weatherCode isEqualToString:@"10n"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"11d"] || [weatherCode isEqualToString:@"11n"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.bolt.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"13d"] || [weatherCode isEqualToString:@"13n"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.snow.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"50d"] || [weatherCode isEqualToString:@"50n"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.fog.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else {
            weatherImage = [UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        }
    }

    if (!weatherImage) {
        weatherImage = [UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
    }

    return weatherImage;
}

- (NSString *)conditionsDescription {
    if (self.weatherData) {
        return NSLocalizedString(getStringFromDictKey([self.weatherData[@"current"][@"weather"] firstObject], @"main", @"UNKNOWN"), comment: @"");
    }

    return NSLocalizedString(@"UNKNOWN", comment: @"");
}

- (NSString *)lowDescription {
    return [self lowDescription:NO];
}

- (NSString *)lowDescription:(BOOL)withSymbol {
    NSString *temperatureString = nil;

    if (self.weatherData) {
        NSArray *dailyForecasts = self.weatherData[@"daily"];

        if (dailyForecasts != nil && dailyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([dailyForecasts firstObject], @"temp_min") unit:[self useMetric] ? NSUnitTemperature.celsius : NSUnitTemperature.fahrenheit];
            measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : [measurement measurementByConvertingToUnit:NSUnitTemperature.celsius];

            if (withSymbol) {
                temperatureString = [formatter stringFromMeasurement:measurement];
            } else {
                temperatureString = [self formatFloat:measurement.doubleValue];
            }
        }
    } else {
        temperatureString = @"--";
    }

    return temperatureString;
}

- (NSString *)highDescription {
    return [self highDescription:NO];
}

- (NSString *)highDescription:(BOOL)withSymbol {
    NSString *temperatureString = nil;

    if (self.weatherData) {
        NSArray *dailyForecasts = self.weatherData[@"daily"];

        if (dailyForecasts != nil && dailyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([dailyForecasts firstObject], @"temp_max") unit:[self useMetric] ? NSUnitTemperature.celsius : NSUnitTemperature.fahrenheit];
            measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : [measurement measurementByConvertingToUnit:NSUnitTemperature.celsius];

            if (withSymbol) {
                temperatureString = [formatter stringFromMeasurement:measurement];
            } else {
                temperatureString = [self formatFloat:measurement.doubleValue];
            }
        }
    } else {
        temperatureString = @"--";
    }

    return temperatureString;
}

- (NSString *)windSpeed {
    return [self windSpeed:YES];
}

- (NSString *)windSpeed:(BOOL)withUnit {
    NSString *windSpeedString = nil;

    if (self.weatherData) {
        NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.weatherData[@"current"], @"wind_speed") unit:NSUnitSpeed.metersPerSecond];
        measurement = [self useMetric] ? [measurement measurementByConvertingToUnit:NSUnitSpeed.kilometersPerHour] : [measurement measurementByConvertingToUnit:NSUnitSpeed.milesPerHour];

        if (withUnit) {
            windSpeedString = [formatter stringFromMeasurement:measurement];
        } else {
            windSpeedString = [self formatFloat:measurement.doubleValue];
        }
    } else {
        windSpeedString = @"--";
    }

    return windSpeedString;
}

- (NSString *)windDirection {
    return [self windDirection:NO];
}

- (NSString *)windDirection:(BOOL)shortDescription {
    NSString *windDirectionString = nil;

    if (self.weatherData) {
        WeatherWindSpeedFormatter *formatter = [WeatherWindSpeedFormatter convenienceFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        windDirectionString = [formatter stringForWindDirection:getDoubleFromDictKey(self.weatherData[@"current"], @"wind_deg") shortDescription:shortDescription];
    }

    return windDirectionString ? : @"--";
}

- (NSString *)humidity {
    return [self humidity:NO];
}

- (NSString *)humidity:(BOOL)withSymbol {
    NSString *humidityString = nil;

    if (self.weatherData) {
        humidityString = [NSString stringWithFormat:withSymbol ? @"%.0f%%" : @"%.0f", getDoubleFromDictKey(self.weatherData[@"current"], @"humidity")];
    }

    return humidityString ? : @"--";
}

- (NSString *)visibility {
    return [self visibility:NO];
}

- (NSString *)visibility:(BOOL)withUnit {
    NSString *visibilityString = nil;

    if (self.weatherData) {
        NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.weatherData[@"current"], @"visibility") unit:NSUnitLength.meters];
        measurement = [self useMetric] ? [measurement measurementByConvertingToUnit:NSUnitLength.kilometers] : [measurement measurementByConvertingToUnit:NSUnitLength.miles];

        if (withUnit) {
            visibilityString = [formatter stringFromMeasurement:measurement];
        } else {
            visibilityString = [NSString stringWithFormat:@"%.1f", measurement.doubleValue];
        }
    } else {
        visibilityString = @"--";
    }

    return visibilityString;
}

- (NSString *)precipitationPast24Hours {
    return [self precipitationPast24Hours:NO];
}

- (NSString *)precipitationPast24Hours:(BOOL)withUnit {
    NSString *precipitationString = nil;

    if (self.weatherData) {
        NSArray *dailyForecasts = self.weatherData[@"daily"];

        if (dailyForecasts != nil && dailyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey([dailyForecasts firstObject], @"precipitation") unit:NSUnitLength.millimeters];
            measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.inches];

            if (withUnit) {
                precipitationString = [formatter stringFromMeasurement:measurement];
            } else {
                precipitationString = [self formatFloat:measurement.doubleValue];
            }
        }
    } else {
        precipitationString = @"--";
    }

    return precipitationString;
}

- (NSString *)precipitationNextHour {
    return [self precipitationNextHour:NO];
}

- (NSString *)precipitationNextHour:(BOOL)withSymbol {
    NSString *precipitationString = nil;

    if (self.weatherData) {
        NSArray *hourlyForecasts = self.weatherData[@"hourly"];

        if (hourlyForecasts != nil && hourlyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([hourlyForecasts firstObject][@"rain"], @"1h", 0) unit:NSUnitLength.millimeters];
            measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.inches];

            if (withSymbol) {
                precipitationString = [formatter stringFromMeasurement:measurement];
            } else {
                precipitationString = [NSString stringWithFormat:@"%.0f", measurement.doubleValue];
            }
        }
    } else {
        precipitationString = @"--";
    }

    return precipitationString;
}

- (NSString *)precipitationPercentNextHour {
    return [self precipitationPercentNextHour:NO];
}

- (NSString *)precipitationPercentNextHour:(BOOL)withSymbol {
    NSString *precipitationString = nil;

    if (self.weatherData) {
        NSArray *hourlyForecasts = self.weatherData[@"hourly"];

        if (hourlyForecasts != nil && hourlyForecasts.count > 0) {
            precipitationString = [NSString stringWithFormat:withSymbol ? @"%.0f%%" : @"%.0f", getDoubleFromDictKey([hourlyForecasts firstObject], @"pop") * 100];
        }
    } else {
        precipitationString = @"--";
    }

    return precipitationString;
}

- (NSString *)pressure {
    return [self pressure:NO];
}

- (NSString *)pressure:(BOOL)withUnit {
    NSString *pressureString = nil;

    if (self.weatherData) {
        NSMeasurementFormatter *formatter = [self sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.weatherData[@"current"], @"pressure") unit:NSUnitPressure.hectopascals];
        measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitPressure.poundsForcePerSquareInch];

        if (withUnit) {
            pressureString = [formatter stringFromMeasurement:measurement];
        } else {
            pressureString = [NSString stringWithFormat:@"%.0f", measurement.doubleValue];
        }
    } else {
        pressureString = @"--";
    }

    return pressureString;
}

- (NSString *)UVIndex {
    NSString *uvIndexString = nil;

    if (self.weatherData) {
        uvIndexString = [NSString stringWithFormat:@"%.0f", getDoubleFromDictKey(self.weatherData[@"current"], @"uvi")];
    }

    return uvIndexString ? : @"--";
}

- (NSDictionary *)getWeatherData {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    [data setObject:self.conditionsDescription forKey:@"conditions"];
    [data setObject:[self conditionsImage:self.fontSize] forKey:@"conditions_image"];
    [data setObject:self.conditionsEmoji forKey:@"conditions_emoji"];
    [data setObject:self.locationName forKey:@"location"];

    [data setObject:self.temperature forKey:@"temperature"];
    [data setObject:[self temperature:YES] forKey:@"temperature_with_symbol"];

    [data setObject:self.lowDescription forKey:@"low_temperature"];
    [data setObject:[self lowDescription:YES] forKey:@"low_temperature_with_symbol"];

    [data setObject:self.highDescription forKey:@"high_temperature"];
    [data setObject:[self highDescription:YES] forKey:@"high_temperature_with_symbol"];

    [data setObject:self.feelsLike forKey:@"feels_like"];
    [data setObject:[self feelsLike:YES] forKey:@"feels_like_with_symbol"];

    [data setObject:[self windSpeed:NO] forKey:@"wind_speed"];
    [data setObject:self.windSpeed forKey:@"wind_speed_with_unit"];

    [data setObject:[self windDirection:NO] forKey:@"wind_direction"];
    [data setObject:self.windDirection forKey:@"wind_direction_short"];

    [data setObject:self.humidity forKey:@"humidity"];
    [data setObject:[self humidity:YES] forKey:@"humidity_with_symbol"];

    [data setObject:self.visibility forKey:@"visibility"];
    [data setObject:[self visibility:YES] forKey:@"visibility_with_unit"];

    [data setObject:self.precipitationNextHour forKey:@"precipitation_next_hour"];
    [data setObject:[self precipitationNextHour:YES] forKey:@"precipitation_next_hour_with_symbol"];

    [data setObject:self.precipitationPercentNextHour forKey:@"precipitation_percent_next_hour"];
    [data setObject:[self precipitationPercentNextHour:YES] forKey:@"precipitation_percent_next_hour_with_symbol"];

    [data setObject:self.precipitationPast24Hours forKey:@"precipitation_24h"];
    [data setObject:[self precipitationPast24Hours:YES] forKey:@"precipitation_24h_with_unit"];

    [data setObject:self.pressure forKey:@"pressure"];
    [data setObject:[self pressure:YES] forKey:@"pressure_with_unit"];

    [data setObject:self.UVIndex forKey:@"uv_index"];
    return data;
}

- (void)updateWeather:(IWeatherDataCallbackBlock)dataCallback {
    __weak typeof(self) weakSelf = self;
    long long nowTime = [DateTimeUtils getCurrentTimestamp];
    dispatch_queue_t concurrentQueue = dispatch_queue_create("weatherQueue", DISPATCH_QUEUE_SERIAL);

    if (self.useCurrentLocation) {
        [self updateLocation:^(NSString *location) {
            dispatch_async(concurrentQueue, ^{
                               // NSLog(@"boom location %@", location);
                               if (location != nil && nowTime - weakSelf.lastUpdateTime > 60) {
                                   // Fetch current, daily, and hourly weather for the location.
                                   weakSelf.weatherData = [weakSelf fetchWeatherForLocation:location != nil ?
                                                           location : weakSelf.lastLocation] ? : weakSelf.weatherData;

                                   weakSelf.city = [WeatherUtils getPlacemarkByGeocode:location != nil ?
                                                    location : weakSelf.lastLocation] ? : weakSelf.city;
                                   // NSLog(@"boom city %@", weakSelf.city);

                                   // Update last update time and location.
                                   weakSelf.lastLocation = location != nil ? location : weakSelf.lastLocation;
                                   weakSelf.lastUpdateTime = nowTime;
                               }

                               dataCallback([weakSelf getWeatherData]);
                           });
        }];
    } else {
        // Check if location unchanged or more than 60 seconds since last update.
        if ((self.location != nil && [self.location length] > 0) && (![self.lastLocation isEqualToString:self.location] || nowTime - self.lastUpdateTime > 60)) {
            // Fetch current, daily, and hourly weather for the location.
            self.weatherData = [self fetchWeatherForLocation:self.location] ? : self.weatherData;

            self.city = [WeatherUtils getPlacemarkByGeocode:self.location] ? : self.city;

            // Update last update time and location.
            self.lastUpdateTime = nowTime;
            self.lastLocation = self.location;
        }

        dataCallback([self getWeatherData]);
    }
}

@end
