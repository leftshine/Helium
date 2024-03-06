#import "QWeather.h"
#import "UsefulFunctions.h"

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

- (NSString *)getWeatherIcon:(NSString *)text {
    NSString *weatherIcon = @"🌤️";
    NSArray *weatherIconList = @[@"☀️", @"☁️", @"⛅️",
                                 @"☃️", @"⛈️", @"🏜️", @"🏜️", @"🌫️", @"🌫️", @"🌪️", @"🌧️"];
    NSArray *weatherType = @[@"晴|sunny", @"阴|overcast", @"云|cloudy", @"雪|snow", @"雷|thunder", @"沙|sand", @"尘|dust", @"雾|foggy", @"霾|haze", @"风|wind", @"雨|rain"];
    
    NSRegularExpression *regex;
    for (int i = 0; i < weatherType.count; i++) {
        NSString *pattern = [NSString stringWithFormat:@".*%@.*", weatherType[i]];
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        if ([regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])] > 0) {
            weatherIcon = weatherIconList[i];
            break;
        }
    }
    
    return weatherIcon;
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
	id data = [self.city[@"location"] firstObject];
	return data ? data[@"name"] : @"No Data";
}

-(NSString *)temperature {
	return [self temperature:NO];
}

-(NSString *)temperature:(BOOL) withSymbol {
    NSString *temperatureString = nil;
    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.locale];
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey(self.now[@"now"], @"temp") unit:NSUnitTemperature.celsius];
        measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : measurement;
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
        NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey(self.now[@"now"], @"feelsLike") unit:NSUnitTemperature.celsius];
        measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : measurement;
        if (withSymbol) 
            temperatureString = [formatter stringFromMeasurement:measurement];
        else
            temperatureString = [self formatFloat:measurement.doubleValue];
    } else {
        temperatureString = @"--";
    }
    return temperatureString;
}

-(NSString *)conditionsEmoji {
    NSString *weatherEmoji = @"";

    if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        int weatherCode = getIntFromDictKey(self.now[@"now"], @"icon");
        int hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
        BOOL isDayTime = (hour >= 6 && hour < 18);
        
        switch (weatherCode) {
            case 100:
            case 150:
                weatherEmoji = isDayTime ? @"🌞" : @"🌜";
                break;
            case 101 ... 103:
            case 151 ... 153:
                weatherEmoji = @"🌥️";
                break;
            case 104:
                weatherEmoji = @"☁️";
                break;
            case 300 ... 318:
                weatherEmoji = @"⛈️";
                break;
            case 350 ... 351:
                weatherEmoji = @"⛈️";
                break;
            case 399:
                weatherEmoji = @"🌧️";
                break;
            case 400 ... 410:
            case 456:
            case 457:
            case 499:
                weatherEmoji = @"❄️";
                break;
            case 500 ... 504:
                weatherEmoji = @"🌫️";
                break;
            case 507 ... 508:
                weatherEmoji = @"🌪️";
                break;
            case 509 ... 515:
                weatherEmoji = @"🌫️";
                break;
            case 900:
                weatherEmoji = @"🌡️";
                break;
            case 901:
                weatherEmoji = @"❄️";
                break;
            default:
                weatherEmoji = @"❔";
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
        
        switch (weatherCode) {
            case 100:
            case 150:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"sun.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"moon.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 101 ... 103:
            case 151 ... 153:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"cloud.sun.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"cloud.moon.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 104:
                weatherImage = [UIImage systemImageNamed:@"cloud.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 300 ... 318:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"cloud.sun.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"cloud.moon.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 350 ... 351:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"cloud.sun.heavyrain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"cloud.moon.heavyrain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 399:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"cloud.sun.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"cloud.moon.rain.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 400 ... 410:
            case 456:
            case 457:
            case 499:
                weatherImage = isDayTime ? [UIImage systemImageNamed:@"cloud.sun.snow.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]] : [UIImage systemImageNamed:@"cloud.moon.snow.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 500 ... 504:
                weatherImage = [UIImage systemImageNamed:@"cloud.fog.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 507 ... 508:
                weatherImage = [UIImage systemImageNamed:@"cloud.sun.duststorm.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 509 ... 515:
                weatherImage = [UIImage systemImageNamed:@"cloud.fog.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 900:
                weatherImage = [UIImage systemImageNamed:@"thermometer.sun.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            case 901:
                weatherImage = [UIImage systemImageNamed:@"thermometer.snowflake" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
            default:
                weatherImage = [UIImage systemImageNamed:@"exclamationmark.triangle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
                break;
        }
    } else {
        weatherImage = [UIImage systemImageNamed:@"exclamationmark.triangle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
    }
    
    return weatherImage;
}

-(NSString *)conditionsDescription {
	if (self.now && [self.now[@"code"] isEqualToString:@"200"]) {
        return getStringFromDictKey(self.now[@"now"], @"text", @"Sun");
    }
    return @"Sun";
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
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([dailyForecasts firstObject], @"tempMin") unit:NSUnitTemperature.celsius];
            measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : measurement;
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
            NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:getIntFromDictKey([dailyForecasts firstObject], @"tempMax") unit:NSUnitTemperature.celsius];
            measurement = [self useFahrenheit] ? [measurement measurementByConvertingToUnit:NSUnitTemperature.fahrenheit] : measurement;
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

- (void) updateWeather:(NSString *)location {
    self.now = [self fetchNowWeatherForLocation:location];
    self.daily = [self fetchTodayWeatherForLocation:location];
    self.hourly = [self fetch24HoursWeatherForLocation:location];
    NSData *data = [self fetchLocationIDForName:location];
    NSError *erro = nil;
    if (data!=nil) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&erro ];
        self.city = json;
    }
}

- (NSString *)getDataFrom:(NSString *)url{
    // NSLog(@"url:%@", url);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];

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