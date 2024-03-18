#import "QWeather.h"
#import "WeatherUtils.h"
#import <CoreLocation/CoreLocation.h>
#import "../UsefulFunctions.h"
#import "../LocationUtils.h"

static NSString *UserAgent = @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5";

@implementation QWeather

+(instancetype)sharedInstance {
	static QWeather *_shared = nil;
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
        self.freeSub = YES;
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

- (NSDictionary *)fetchNowWeatherForLocation:(NSString *)location{
    NSString *res = [self getDataFrom:[NSString stringWithFormat:@"https://%@.qweather.com/v7/weather/now?location=%@&key=%@&lang=%@&unit=%@", self.freeSub?@"devapi":@"api", location, self.apiKey, self.locale, self.useMetric?@"m":@"i"]];
    NSData *data = [res dataUsingEncoding:NSUTF8StringEncoding];
    NSError *erro = nil;
    if (data!=nil) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&erro ];
        return json;
    }
    return nil;
}

- (NSDictionary *)fetchTodayWeatherForLocation:(NSString *)location{
    NSString *res = [self getDataFrom:[NSString stringWithFormat:@"https://%@.qweather.com/v7/weather/3d?location=%@&key=%@&lang=%@&unit=%@", self.freeSub?@"devapi":@"api", location, self.apiKey, self.locale, self.useMetric?@"m":@"i"]];
    NSData *data = [res dataUsingEncoding:NSUTF8StringEncoding];
    NSError *erro = nil;
    if (data!=nil) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&erro ];
        return json;
    }
    return nil;
}

- (NSDictionary *)fetch24HoursWeatherForLocation:(NSString *)location{
    NSString *res = [self getDataFrom:[NSString stringWithFormat:@"https://%@.qweather.com/v7/weather/24h?location=%@&key=%@&lang=%@&unit=%@", self.freeSub?@"devapi":@"api", location, self.apiKey, self.locale, self.useMetric?@"m":@"i"]];
    NSData *data = [res dataUsingEncoding:NSUTF8StringEncoding];
    NSError *erro = nil;
    if (data!=nil) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&erro ];
        return json;
    }
    return nil;
}

-(NSString *)locationName {
	return self.city.subLocality ?: @"--";
}

-(NSString *)temperature {
	return [self temperature:NO];
}

-(NSString *)temperature:(BOOL) withSymbol {
    NSString *temperatureString = nil;
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey(self.now[@"now"], @"temp") unit:[self useMetric]?NSUnitTemperature.celsius:NSUnitTemperature.fahrenheit];
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
	if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey(self.now[@"now"], @"feelsLike") unit:[self useMetric]?NSUnitTemperature.celsius:NSUnitTemperature.fahrenheit];
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
    
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        int weatherCode = getIntFromDictKey(self.now[@"now"], @"icon");
        int hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
        BOOL isDayTime = (hour >= 6 && hour < 18); // Assuming day time is between 6 AM and 6 PM
        
        switch (weatherCode) {
            case 100:
            case 150:
                weatherEmoji = isDayTime ? @"☀️" : @"🌙";
                break;
            case 101 ... 103:
            case 151 ... 153:
                weatherEmoji = isDayTime ? @"⛅️" : @"🌥️";
                break;
            case 104:
                weatherEmoji = @"☁️";
                break;
            case 300:
            case 305:
            case 309:
            case 314:
            case 350:
                weatherEmoji = @"🌦️";
                break;
            case 301:
            case 306:
            case 315:
            case 351:
            case 399:
                weatherEmoji = @"🌧️";
                break;
            case 304:
            case 313:
                weatherEmoji = @"⛈️";
                break;
            case 302 ... 303:
                weatherEmoji = @"🌩️";
                break;
            case 307 ... 308:
            case 310 ... 312:
            case 316 ... 318:
                weatherEmoji = @"⛈️";
                break;
            case 400 ... 403:
            case 407 ... 410:
            case 457:
            case 499:
                weatherEmoji = @"🌨️";
                break;
            case 404 ... 406:
            case 456:
                weatherEmoji = @"🌨️";
                break;
            case 500 ... 501:
            case 509 ... 510:
            case 514 ... 515:
                weatherEmoji = @"🌫️";
                break;
            case 507 ... 508:
                weatherEmoji = @"🌪️";
                break;
            case 502 ... 504:
            case 511 ... 513:
                weatherEmoji = @"🌬️";
                break;
            case 900:
                weatherEmoji = @"🔥";
                break;
            case 901:
                weatherEmoji = @"❄️";
                break;
            default:
                weatherEmoji = @"❓";
                break;
        }
    }
    
    return weatherEmoji;
}

- (UIImage *)conditionsImage:(double)fontSize {
    UIImage *weatherImage = nil;
    
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        int weatherCode = getIntFromDictKey(self.now[@"now"], @"icon");
        int hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
        BOOL isDayTime = (hour >= 6 && hour < 18); // Assuming day time is between 6 AM and 6 PM
        // NSLog(@"boom %d", weatherCode);
        switch (weatherCode) {
            case 100:
            case 150:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"sun.max.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"moon.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 101 ... 103:
            case 151 ... 153:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"cloud.sun.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"cloud.moon.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 104:
                weatherImage = [UIImage systemImageNamed:@"cloud.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 300:
            case 305:
            case 309:
            case 314:
            case 350:
                weatherImage = [UIImage systemImageNamed:@"cloud.drizzle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 301:
            case 306:
            case 315:
            case 351:
            case 399:
                weatherImage = [UIImage systemImageNamed:@"cloud.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 304:
            case 313:
                weatherImage = [UIImage systemImageNamed:@"cloud.hail.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 302 ... 303:
                weatherImage = [UIImage systemImageNamed:@"cloud.bolt.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 307 ... 308:
            case 310 ... 312:
            case 316 ... 318:
                weatherImage = [UIImage systemImageNamed:@"cloud.heavyrain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 400 ... 403:
            case 407 ... 410:
            case 457:
            case 499:
                weatherImage = [UIImage systemImageNamed:@"cloud.snow.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 404 ... 406:
            case 456:
                weatherImage = [UIImage systemImageNamed:@"cloud.sleet.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 500 ... 501:
            case 509 ... 510:
            case 514 ... 515:
                weatherImage = [UIImage systemImageNamed:@"cloud.fog.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 507 ... 508:
                weatherImage = [UIImage systemImageNamed:@"smoke.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 502 ... 504:
            case 511 ... 513:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"sun.dust.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"moon.dust.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 900:
                weatherImage = [UIImage systemImageNamed:@"thermometer.sun.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 901:
                weatherImage = [UIImage systemImageNamed:@"thermometer.snowflake" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            default:
                weatherImage = [UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
        }
    }
    
    if (!weatherImage) {
        weatherImage = [UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
    }
    
    return weatherImage;
}

-(NSString *)conditionsDescription {
	if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        return getStringFromDictKey(self.now[@"now"], @"text", NSLocalizedString(@"UNKNOWN", comment:@""));
    }
    return NSLocalizedString(@"UNKNOWN", comment:@"");
}

-(NSString *)lowDescription {
	return [self lowDescription:NO];
}

-(NSString *)lowDescription:(BOOL) withSymbol {
    NSString *temperatureString = nil;
	if (self.daily && [self.daily[@"code"] isEqualToString:@"200"]) {
        NSArray *dailyForecasts = self.daily[@"daily"];
        if (dailyForecasts != nil && dailyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([dailyForecasts firstObject], @"tempMin") unit:[self useMetric]?NSUnitTemperature.celsius:NSUnitTemperature.fahrenheit];
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
	if (self.daily && [self.daily[@"code"] isEqualToString:@"200"]) {
        NSArray *dailyForecasts = self.daily[@"daily"];
        if (dailyForecasts != nil && dailyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([dailyForecasts firstObject], @"tempMax") unit:[self useMetric]?NSUnitTemperature.celsius:NSUnitTemperature.fahrenheit];
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
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.now[@"now"], @"windSpeed") unit:NSUnitSpeed.kilometersPerHour];
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

-(NSString *)windScale {
    NSString *windScaleString = nil;
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        windScaleString = getStringFromDictKey(self.now[@"now"], @"windScale", nil);
    }
	return windScaleString ?: @"--";
}

-(NSString *)windDirection {
    NSString *windDirectionString = nil;
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        windDirectionString = getStringFromDictKey(self.now[@"now"], @"windDir", nil);
    }
	return windDirectionString ?: @"--";
}

-(NSString *)humidity {
	return [self humidity:NO];
}

-(NSString *)humidity:(BOOL) withSymbol {
    NSString *humidityString = nil;
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        humidityString = [NSString stringWithFormat:withSymbol ? @"%.0f%%" : @"%.0f", getDoubleFromDictKey(self.now[@"now"], @"humidity", nil)];
    }
	return humidityString ?: @"--";
}

-(NSString *)visibility {
	return [self visibility:NO];
}

-(NSString *)visibility:(BOOL) withUnit {
    NSString *visibilityString = nil;
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.now[@"now"], @"vis") unit:NSUnitLength.kilometers];
	    measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.miles];
        if (withUnit) 
            visibilityString = [formatter stringFromMeasurement:measurement];
        else
            visibilityString = [NSString stringWithFormat:@"%.0f", measurement.doubleValue];
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
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.now[@"now"], @"precip") unit:NSUnitLength.millimeters];
	    measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.inches];
        if (withUnit) 
            precipitationString = [formatter stringFromMeasurement:measurement];
        else
            precipitationString = [self formatFloat:measurement.doubleValue];
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
	if (self.hourly && [self.hourly[@"code"] isEqualToString:@"200"]) {
        NSArray *hourlyForecasts = self.hourly[@"hourly"];
        if (hourlyForecasts != nil && hourlyForecasts.count > 0) {
            NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
            NSMeasurement *measurement = [[NSMeasurement alloc]  initWithDoubleValue:getIntFromDictKey([hourlyForecasts firstObject], @"pop") unit:NSUnitLength.millimeters];
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
	if (self.hourly && [self.hourly[@"code"] isEqualToString:@"200"]) {
        NSArray *hourlyForecasts = self.hourly[@"hourly"];
        if (hourlyForecasts != nil && hourlyForecasts.count > 0) {
            precipitationString = [NSString stringWithFormat:withSymbol ? @"%.0f%%" : @"%.0f", getDoubleFromDictKey([hourlyForecasts firstObject], @"pop", nil)];
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
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getDoubleFromDictKey(self.now[@"now"], @"pressure") unit:NSUnitPressure.hectopascals];
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

    [data setObject:self.windDirection forKey:@"wind_direction"];

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
    return data;
}

- (void)updateWeather:(QWeatherDataCallbackBlock) dataCallback {
    __weak typeof(self) weakSelf = self;
    long long nowTime = [self getCurrentTimestamp];
    dispatch_queue_t concurrentQueue = dispatch_queue_create("weatherQueue", DISPATCH_QUEUE_SERIAL);
    if (self.useCurrentLocation) {
        [self updateLocation:^(NSString *location) {
            dispatch_async(concurrentQueue, ^{
                // NSLog(@"boom location %@", location);
                if (nowTime - weakSelf.lastUpdateTime > 60) {
                    // Fetch current, daily, and hourly weather for the location.
                    weakSelf.now = [weakSelf fetchNowWeatherForLocation:location!=nil?location:weakSelf.lastLocation];
                    weakSelf.daily = [weakSelf fetchTodayWeatherForLocation:location!=nil?location:weakSelf.lastLocation];
                    weakSelf.hourly = [weakSelf fetch24HoursWeatherForLocation:location!=nil?location:weakSelf.lastLocation];
                    
                    weakSelf.city = [WeatherUtils getPlacemarkByGeocode:location!=nil?location:weakSelf.lastLocation];
                    // NSLog(@"boom city %@", weakSelf.city);
                    
                    // Update last update time and location.
                    weakSelf.lastLocation = location!=nil?location:weakSelf.lastLocation;
                    weakSelf.lastUpdateTime = nowTime;
                }
                dataCallback([weakSelf getWeatherData]);
            });
        }];
    } else {
        // Check if location unchanged or more than 60 seconds since last update.
        if ((self.location != nil && [self.location length] > 0) && (![self.lastLocation isEqualToString:self.location] || nowTime - self.lastUpdateTime > 60)) {
            // Fetch current, daily, and hourly weather for the location.
            self.now = [self fetchNowWeatherForLocation:self.location];
            self.daily = [self fetchTodayWeatherForLocation:self.location];
            self.hourly = [self fetch24HoursWeatherForLocation:self.location];
            
            self.city = [WeatherUtils getPlacemarkByGeocode:self.location];
            
            // Update last update time and location.
            self.lastUpdateTime = nowTime;
            self.lastLocation = self.location;
        }
        dataCallback([self getWeatherData]);
    }
}

- (void)updateLocation:(QWeatherLocationCallbackBlock) locationCallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LocationUtils sharedInstance] getCurrentLocation: ^(NSError *error, NSString *location) {
            if (!error) {
                // NSLog(@"boom %@", location);
                locationCallback(location);
            } else {
                // NSLog(@"boom error:%@", error);
                locationCallback(nil);
            }
        }];
    });
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