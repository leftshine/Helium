#import "ColorfulClouds.h"
#import "WeatherUtils.h"
#import "../UsefulFunctions.h"
#import "../../helpers/private_headers/Weather/WeatherWindSpeedFormatter.h"

static NSString *UserAgent = @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5";

@implementation ColorfulClouds

+(instancetype)sharedInstance {
	static ColorfulClouds *_shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_shared = [[self alloc] init];
	});
	return _shared;
}

-(instancetype)init {
	self = [super init];

	if (self != nil) {
		self.useFahrenheit = NO;
		self.useMetric = YES;
	}
	return self;
}

+(NSMeasurementFormatter *)sharedNSMeasurementFormatter {
	static NSMeasurementFormatter *formatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		formatter = [[NSMeasurementFormatter alloc] init];
	});
	[formatter setUnitOptions:NSMeasurementFormatterUnitOptionsProvidedUnit];
	formatter.numberFormatter.maximumFractionDigits = 1;
	return formatter;
}

- (NSDictionary *)fetchWeatherForLocation:(NSString *)location{
    NSString *res = [self getDataFrom:[NSString stringWithFormat:@"https://api.caiyunapp.com/v2.6/%@/%@/weather?lang=%@&unit=%@&alert=true&dailysteps=1&hourlysteps=24", self.apiKey, location, self.locale, self.useMetric?@"metric":@"imperial"]];
    NSData *data = [res dataUsingEncoding:NSUTF8StringEncoding];
    NSError *erro = nil;
    if (data!=nil) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&erro ];
        return json;
    }
    return nil;
}

- (NSData *)fetchLocationIDForName:(NSString *)name{
    NSString *res = [self getDataFrom:[NSString stringWithFormat:@"https://geoapi.qweather.com/v2/city/lookup?location=%@&key=%@&lang=%@", [self encodeURIComponent:name], self.apiKey, self.locale]];
    NSData *data = [res dataUsingEncoding:NSUTF8StringEncoding];
    if (data!=nil) {
        // NSLog(@"weather location:%@", data);
        return data;
    }
    return nil;
}

-(NSString *)locationName {
	return self.city;
}

-(NSString *)temperature {
	return [self temperature:NO];
}

-(NSString *)temperature:(BOOL) withSymbol {
    NSString *temperatureString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey(self.weatherData[@"result"][@"realtime"], @"temperature") unit:[self useMetric]?NSUnitTemperature.celsius:NSUnitTemperature.fahrenheit];
        measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : [measurement measurementByConvertingToUnit:NSUnitTemperature.celsius];
        if (withSymbol) 
            temperatureString = [formatter stringFromMeasurement:measurement];
        else
            temperatureString = [self formatFloat:measurement.doubleValue];
    } else {
        temperatureString = @"--";
    }
    return temperatureString;
}

-(NSString *)feelsLike {
	return [self feelsLike:NO];
}

-(NSString *)feelsLike:(BOOL) withSymbol {
    NSString *temperatureString = nil;
	if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey(self.weatherData[@"result"][@"realtime"], @"apparent_temperature") unit:[self useMetric]?NSUnitTemperature.celsius:NSUnitTemperature.fahrenheit];
        measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : [measurement measurementByConvertingToUnit:NSUnitTemperature.celsius];
        if (withSymbol) 
            temperatureString = [formatter stringFromMeasurement:measurement];
        else
            temperatureString = [self formatFloat:measurement.doubleValue];
    } else {
        temperatureString = @"--";
    }
    return temperatureString;
}

- (NSString *)conditionsEmoji {
    NSString *weatherEmoji = @"";

    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSString *weatherCode = getStringFromDictKey(self.weatherData[@"result"][@"realtime"], @"skycon", @"UNKNOWN");
        // NSLog(@"boom %d", weatherCode);
        if ([weatherCode isEqualToString:@"CLEAR_DAY"]) {
            weatherEmoji = @"☀️";
        } else if ([weatherCode isEqualToString:@"CLEAR_NIGHT"]) {
            weatherEmoji = @"🌙";
        } else if ([weatherCode isEqualToString:@"PARTLY_CLOUDY_DAY"]) {
            weatherEmoji = @"⛅️";
        } else if ([weatherCode isEqualToString:@"PARTLY_CLOUDY_NIGHT"]) {
            weatherEmoji = @"🌥️";
        } else if ([weatherCode isEqualToString:@"CLOUDY"]) {
            weatherEmoji = @"☁️";
        } else if ([weatherCode isEqualToString:@"LIGHT_HAZE"]) {
            weatherEmoji = @"🌫️";
        } else if ([weatherCode isEqualToString:@"MODERATE_HAZE"]) {
            weatherEmoji = @"🌫️";
        } else if ([weatherCode isEqualToString:@"HEAVY_HAZE"]) {
            weatherEmoji = @"🌫️";
        } else if ([weatherCode isEqualToString:@"LIGHT_RAIN"]) {
            weatherEmoji = @"🌧️";
        } else if ([weatherCode isEqualToString:@"MODERATE_RAIN"]) {
            weatherEmoji = @"🌧️";
        } else if ([weatherCode isEqualToString:@"HEAVY_RAIN"]) {
            weatherEmoji = @"🌧️";
        } else if ([weatherCode isEqualToString:@"STORM_RAIN"]) {
            weatherEmoji = @"🌧️";
        } else if ([weatherCode isEqualToString:@"FOG"]) {
            weatherEmoji = @"🌫️";
        } else if ([weatherCode isEqualToString:@"LIGHT_SNOW"]) {
            weatherEmoji = @"🌨️";
        } else if ([weatherCode isEqualToString:@"MODERATE_SNOW"]) {
            weatherEmoji = @"🌨️";
        } else if ([weatherCode isEqualToString:@"HEAVY_SNOW"]) {
            weatherEmoji = @"🌨️";
        } else if ([weatherCode isEqualToString:@"STORM_SNOW"]) {
            weatherEmoji = @"🌨️";
        } else if ([weatherCode isEqualToString:@"DUST"]) {
            weatherEmoji = @"🌬️";
        } else if ([weatherCode isEqualToString:@"SAND"]) {
            weatherEmoji = @"🌪️";
        } else if ([weatherCode isEqualToString:@"WIND"]) {
            weatherEmoji = @"🌬️";
        } else {
            weatherEmoji = @"❓";
        }
    }
    
    return weatherEmoji;
}

- (UIImage *)conditionsImage:(double)fontSize {
    UIImage *weatherImage = nil;
    int hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    BOOL isDayTime = (hour >= 6 && hour < 18); // Assuming day time is between 6 AM and 6 PM
    
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSString *weatherCode = getStringFromDictKey(self.weatherData[@"result"][@"realtime"], @"skycon", @"UNKNOWN");
        // NSLog(@"boom %d", weatherCode);
        if ([weatherCode isEqualToString:@"CLEAR_DAY"]) {
            weatherImage = [UIImage systemImageNamed:@"sun.max.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"CLEAR_NIGHT"]) {
            weatherImage = [UIImage systemImageNamed:@"moon.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"PARTLY_CLOUDY_DAY"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.sun.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"PARTLY_CLOUDY_NIGHT"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.moon.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"CLOUDY"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"LIGHT_HAZE"]) {
            weatherImage = [UIImage systemImageNamed:@"sun.haze.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"MODERATE_HAZE"]) {
            weatherImage = [UIImage systemImageNamed:@"sun.haze.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"HEAVY_HAZE"]) {
            weatherImage = [UIImage systemImageNamed:@"sun.haze.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"LIGHT_RAIN"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.drizzle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"MODERATE_RAIN"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"HEAVY_RAIN"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.heavyrain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"STORM_RAIN"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.bolt.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"FOG"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.fog.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"LIGHT_SNOW"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.snow.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"MODERATE_SNOW"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.snow.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"HEAVY_SNOW"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.snow.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"STORM_SNOW"]) {
            weatherImage = [UIImage systemImageNamed:@"cloud.snow.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"DUST"]) {
            weatherImage = isDayTime ? [UIImage systemImageNamed:@"sun.dust.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"moon.dust.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"SAND"]) {
            weatherImage = [UIImage systemImageNamed:@"smoke.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else if ([weatherCode isEqualToString:@"WIND"]) {
            weatherImage = [UIImage systemImageNamed:@"wind" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        } else {
            weatherImage = [UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        }
    }
    
    if (!weatherImage) {
        weatherImage = [UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
    }
    
    return weatherImage;
}

-(NSString *)conditionsDescription {
	if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        return NSLocalizedString(getStringFromDictKey(self.weatherData[@"result"][@"realtime"], @"skycon", @"UNKNOWN"), comment:@"");
    }
    return NSLocalizedString(@"UNKNOWN", comment:@"");
}

-(NSString *)lowDescription {
	return [self lowDescription:NO];
}

-(NSString *)lowDescription:(BOOL) withSymbol {
    NSString *temperatureString = nil;
	if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSArray *dailyForecasts = self.weatherData[@"result"][@"daily"][@"temperature"];
        if (dailyForecasts != nil && dailyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([dailyForecasts firstObject], @"min") unit:[self useMetric]?NSUnitTemperature.celsius:NSUnitTemperature.fahrenheit];
            measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : [measurement measurementByConvertingToUnit:NSUnitTemperature.celsius];
            if (withSymbol) 
                temperatureString = [formatter stringFromMeasurement:measurement];
            else
                temperatureString = [self formatFloat:measurement.doubleValue];
        }
    } else {
        temperatureString = @"--";
    }
    return temperatureString;
}

-(NSString *)highDescription {
	return [self highDescription:NO];
}

-(NSString *)highDescription:(BOOL) withSymbol {
    NSString *temperatureString = nil;
	if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSArray *dailyForecasts = self.weatherData[@"result"][@"daily"][@"temperature"];
        if (dailyForecasts != nil && dailyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([dailyForecasts firstObject], @"max") unit:[self useMetric]?NSUnitTemperature.celsius:NSUnitTemperature.fahrenheit];
            measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : [measurement measurementByConvertingToUnit:NSUnitTemperature.celsius];
            if (withSymbol) 
                temperatureString = [formatter stringFromMeasurement:measurement];
            else
                temperatureString = [self formatFloat:measurement.doubleValue];
        }
    } else {
        temperatureString = @"--";
    }
    return temperatureString;
}

-(NSString *)windSpeed {
	return [self windSpeed:YES];
}

-(NSString *)windSpeed:(BOOL) withUnit {
    NSString *windSpeedString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.weatherData[@"result"][@"realtime"][@"wind"], @"speed") unit:NSUnitSpeed.kilometersPerHour];
	    measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitSpeed.milesPerHour];
        if (withUnit) 
            windSpeedString = [formatter stringFromMeasurement:measurement];
        else
            windSpeedString = [self formatFloat:measurement.doubleValue];
    } else {
        windSpeedString = @"--";
    }
    return windSpeedString;
}

-(NSString *)windDirection {
	return [self windDirection:NO];
}

-(NSString *)windDirection:(BOOL) shortDescription {
	NSString *windDirectionString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        WeatherWindSpeedFormatter * formatter = [WeatherWindSpeedFormatter convenienceFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        windDirectionString = [formatter stringForWindDirection:getDoubleFromDictKey(self.weatherData[@"result"][@"realtime"][@"wind"], @"direction") shortDescription:shortDescription];
    }
	return windDirectionString ?: @"--";
}

-(NSString *)humidity {
	return [self humidity:NO];
}

-(NSString *)humidity:(BOOL) withSymbol {
    NSString *humidityString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        humidityString = [NSString stringWithFormat:withSymbol ? @"%.0f%%" : @"%.0f", getDoubleFromDictKey(self.weatherData[@"result"][@"realtime"], @"humidity") * 100];
    }
	return humidityString ?: @"--";
}

-(NSString *)visibility {
	return [self visibility:NO];
}

-(NSString *)visibility:(BOOL) withUnit {
    NSString *visibilityString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.weatherData[@"result"][@"realtime"], @"visibility") unit:NSUnitLength.kilometers];
	    measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.miles];
        if (withUnit) 
            visibilityString = [formatter stringFromMeasurement:measurement];
        else
            visibilityString = [NSString stringWithFormat:@"%.1f", measurement.doubleValue];
    } else {
        visibilityString = @"--";
    }
    return visibilityString;
}

-(NSString *)precipitationPast24Hours {
	return [self precipitationPast24Hours:NO];
}

-(NSString *)precipitationPast24Hours:(BOOL) withUnit {
    NSString *precipitationString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSArray *dailyForecasts = self.weatherData[@"result"][@"daily"][@"precipitation"];
        if (dailyForecasts != nil && dailyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey([dailyForecasts firstObject], @"avg") unit:NSUnitLength.millimeters];
            measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.inches];
            if (withUnit) 
                precipitationString = [formatter stringFromMeasurement:measurement];
            else
                precipitationString = [self formatFloat:measurement.doubleValue];
        }
    } else {
        precipitationString = @"--";
    }
    return precipitationString;
}

-(NSString *)precipitationNextHour {
	return [self precipitationNextHour:NO];
}

-(NSString *)precipitationNextHour:(BOOL) withSymbol {
    NSString *precipitationString = nil;
	if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSArray *hourlyForecasts = self.weatherData[@"result"][@"hourly"][@"precipitation"];
        if (hourlyForecasts != nil && hourlyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc]  initWithDoubleValue:getIntFromDictKey([hourlyForecasts firstObject], @"value") unit:NSUnitLength.millimeters];
            measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.inches];
            if (withSymbol) 
                precipitationString = [formatter stringFromMeasurement:measurement];
            else
                precipitationString = [NSString stringWithFormat:@"%.0f", measurement.doubleValue];
        }
    } else {
        precipitationString = @"--";
    }
    return precipitationString;
}

-(NSString *)precipitationPercentNextHour {
	return [self precipitationPercentNextHour:NO];
}

-(NSString *)precipitationPercentNextHour:(BOOL) withSymbol {
    NSString *precipitationString = nil;
	if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSArray *hourlyForecasts = self.weatherData[@"result"][@"hourly"][@"precipitation"];
        if (hourlyForecasts != nil && hourlyForecasts.count > 0) {
            precipitationString = [NSString stringWithFormat:withSymbol ? @"%.0f%%" : @"%.0f", getDoubleFromDictKey([hourlyForecasts firstObject], @"probability", nil)];
        }
    } else {
        precipitationString = @"--";
    }
    return precipitationString;
}

-(NSString *)pressure {
	return [self pressure:NO];
}

-(NSString *)pressure:(BOOL) withUnit {
    NSString *pressureString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.weatherData[@"result"][@"realtime"], @"pressure")/100 unit:NSUnitPressure.hectopascals];
	    measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitPressure.poundsForcePerSquareInch];
        if (withUnit) 
            pressureString = [formatter stringFromMeasurement:measurement];
        else
            pressureString = [NSString stringWithFormat:@"%.0f", measurement.doubleValue];
    } else {
        pressureString = @"--";
    }
    return pressureString;
}

-(NSString *)UVIndex {
    NSString *uvIndexString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        uvIndexString = [NSString stringWithFormat:@"%.0f", getDoubleFromDictKey(self.weatherData[@"result"][@"realtime"][@"life_index"][@"ultraviolet"], @"index")];
    }
	return uvIndexString ?: @"--";
}

-(NSString *)airQualityIndex {
    NSString *airQualityIndexString = nil;
    if (self.weatherData && [self.weatherData[@"status"] isEqualToString:@"ok"]) {
        airQualityIndexString = [NSString stringWithFormat:@"%.0f", getDoubleFromDictKey(self.weatherData[@"result"][@"realtime"][@"air_quality"][@"aqi"], self.useMetric?@"chn":@"usa")];
    }
	return airQualityIndexString ?: @"--";
}

- (NSDictionary *)getWeatherData:(double) fontSize {
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:self.conditionsDescription forKey:@"conditions"];
    [data setObject:[self conditionsImage:fontSize] forKey:@"conditions_image"];
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
	[data setObject:self.airQualityIndex forKey:@"aqi"];
    return data;
}

- (void)updateWeather:(NSString *)location {
    long long nowTime = [self getCurrentTimestamp];
    // NSLog(@"boom time:%lld", nowTime);
    // NSLog(@"boom time:%lld", nowTime - self.lastUpdateTime);

    // NSLog(@"boom location:%@", location);
    // NSLog(@"boom location:%@", self.lastLocation);
    
    // Check if location unchanged or more than 60 seconds since last update.
    if (![self.lastLocation isEqualToString:location] || nowTime - self.lastUpdateTime > 60) {
        // Fetch current, daily, and hourly weather for the location.
        self.weatherData = [self fetchWeatherForLocation:location];
        
        self.city = [WeatherUtils getNameByGeocode:location];
        // Update last update time and location.
        self.lastUpdateTime = nowTime;
        self.lastLocation = location;
    }
}

- (long long)getCurrentTimestamp {
    NSDate *now = [NSDate date];
    NSTimeInterval timestamp = [now timeIntervalSince1970];
    long long longTimestamp = (long long)timestamp;
    return longTimestamp;
}

- (NSString *)getDataFrom:(NSString *)url{
    // NSLog(@"url:%@", url);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:UserAgent forHTTPHeaderField:@"User-Agent"];

    NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;

    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];

    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %li", url, [responseCode statusCode]);
        return nil;
    }

    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding]; 
}

- (NSString *)encodeURIComponent:(NSString *)string
{
    NSString *s = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return s;
}

- (NSString *)formatFloat:(double)f {
    if (fmodf(f, 1)==0) {
        return [NSString stringWithFormat:@"%.0f",f];
    } else {
        return [NSString stringWithFormat:@"%.1f",f];
    }
}


@end