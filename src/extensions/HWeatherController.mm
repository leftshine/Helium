// https://github.com/DGh0st/HSWidgets
// https://github.com/CreatureSurvive/CSWeather
// https://github.com/midnightchip/Asteroid
// https://github.com/Tr1Fecta-7/WeatherGround
#import "HWeatherController.h"
#import "UsefulFunctions.h"

enum {
	ConditionImageTypeDefault = 0,
	ConditionImageTypeDay = 1,
	ConditionImageTypeNight = 2
};
typedef NSUInteger ConditionImageType;

@implementation HWeatherController
+(instancetype)sharedInstance {
	static HWeatherController *_sharedController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedController = [[self alloc] init];
	});
	return _sharedController;
}

+(WFTemperatureFormatter *)sharedTemperatureFormatter {
	static WFTemperatureFormatter *_temperatureFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_temperatureFormatter = [[WFTemperatureFormatter alloc] init];
	});
	return _temperatureFormatter;
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

-(instancetype)init {
	self = [super init];

	if (self != nil) {
		self.useFahrenheit = NO;
		self.useMetric = YES;
		[self updateModel];
	}
	return self;
}

-(NSString *)locationName {
	NSString *name = self.todayModel.forecastModel.city.name;
	if (name)
		return name;
	return self.todayModel.forecastModel.location.displayName ?: @"No Data";
}

-(NSString *)temperature {
	return [self temperature:NO];
}

-(NSString *)temperature:(BOOL) withSymbol {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[self useFahrenheit] ? 1 : 2];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:withSymbol];

	NSString *temperatureString = nil;
	temperatureString = [temperatureFormatter stringForObjectValue:self.todayModel.forecastModel.currentConditions.temperature];
	return temperatureString ?: @"--";
}

-(NSString *)feelsLike {
	return [self feelsLike:NO];
}

-(NSString *)feelsLike:(BOOL) withSymbol {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[self useFahrenheit] ? 1 : 2];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:withSymbol];

	NSString *temperatureString = nil;
	temperatureString = [temperatureFormatter stringForObjectValue:self.todayModel.forecastModel.currentConditions.feelsLike];
	return temperatureString ?: @"--";
}

-(UIImage *)conditionsImage {
	NSString *conditionImgName = [self conditionsImageName];
	UIImage *conditionsImg = nil;
	@try {
		ConditionImageType type = [conditionImgName containsString:@"day"] ? ConditionImageTypeDay : [conditionImgName containsString:@"night"] ? ConditionImageTypeNight : ConditionImageTypeDefault;
		NSString *rootName;

		switch (type) {
			case ConditionImageTypeDefault: {
				conditionsImg = [self imageForKey:[conditionImgName stringByAppendingString:@"-white"]];
			} break;

			case ConditionImageTypeDay: {
				rootName = [[conditionImgName stringByReplacingOccurrencesOfString:@"-day" withString:@""] stringByReplacingOccurrencesOfString:@"_day" withString:@""];

				conditionsImg = [self imageForKey:[rootName stringByAppendingString:@"_day-white"]] ? :
				[self imageForKey:[rootName stringByAppendingString:@"-day-white"]];
			} break;

			case ConditionImageTypeNight: {
				rootName = [[conditionImgName stringByReplacingOccurrencesOfString:@"-night" withString:@""] stringByReplacingOccurrencesOfString:@"_night" withString:@""];

				conditionsImg = [self imageForKey:[rootName stringByAppendingString:@"_night-white"]] ? :
				[self imageForKey:[rootName stringByAppendingString:@"-night-white"]];
			} break;
		}
	} @catch (NSException *e) {
		NSLog(@"boom: %@", e);
	}
	return conditionsImg ?: [self imageForKey:@"mostly-sunny-white"];
}

-(NSString *)conditionsImageName {
	if (self.todayModel.forecastModel.currentConditions != nil)
		return [WeatherImageLoader conditionImageNameWithConditionIndex:self.todayModel.forecastModel.currentConditions.conditionCode];
	return [WeatherImageLoader conditionImageNameWithConditionIndex:32];
}

-(NSString *)conditionsEmoji {
	NSString *weatherString = nil;
	if (self.todayModel.forecastModel.currentConditions != nil) {
	NSInteger currentCode = self.todayModel.forecastModel.currentConditions.conditionCode;
	int hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];

	if (currentCode <= 2)
		weatherString = @"🌪";
	else if (currentCode <= 4)
		weatherString = @"⛈";
	else if (currentCode <= 8)
		weatherString = @"🌨";
	else if (currentCode == 9)
		weatherString = @"🌧";
	else if (currentCode == 10)
		weatherString = @"🌨";
	else if (currentCode <= 12)
		weatherString = @"🌧";
	else if (currentCode <= 18)
		weatherString = @"🌨";
	else if (currentCode <= 22)
		weatherString = @"🌫";
	else if (currentCode <= 24)
		weatherString = @"💨";
	else if (currentCode == 25)
		weatherString = @"❄️";
	else if (currentCode == 26)
		weatherString = @"☁️";
	else if (currentCode <= 28)
		weatherString = @"🌥";
	else if (currentCode <= 30)
		weatherString = @"⛅️";
	else if (currentCode <= 32 && (hour >= 18 || hour <= 6))
		weatherString = @"🌙";
	else if (currentCode <= 32)
		weatherString = @"☀️";
	else if (currentCode <= 34)
		weatherString = @"🌤";
	else if (currentCode == 35)
		weatherString = @"🌧";
	else if (currentCode == 36)
		weatherString = @"🔥";
	else if (currentCode <= 38)
		weatherString = @"🌩";
	else if (currentCode == 39)
		weatherString = @"🌦";
	else if (currentCode == 40)
		weatherString = @"🌧";
	else if (currentCode <= 43)
		weatherString = @"🌨";
	} else
		weatherString = @"N/A";
	return weatherString;
}

- (UIImage *)conditionsImage2:(double) fontSize {
    UIImage *weatherImage = nil;
    
    if (self.todayModel.forecastModel.currentConditions != nil) {
        NSInteger currentCode = self.todayModel.forecastModel.currentConditions.conditionCode;
        int hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];

        if (currentCode <= 2)
            weatherImage = [UIImage systemImageNamed:@"tornado"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 4)
            weatherImage = [UIImage systemImageNamed:@"cloud.bolt.rain.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 8)
            weatherImage = [UIImage systemImageNamed:@"cloud.sleet.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode == 9)
            weatherImage = [UIImage systemImageNamed:@"cloud.drizzle.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode == 10)
            weatherImage = [UIImage systemImageNamed:@"cloud.sleet.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 12)
            weatherImage = [UIImage systemImageNamed:@"cloud.rain.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 18)
            weatherImage = [UIImage systemImageNamed:@"cloud.sleet.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 22)
            weatherImage = [UIImage systemImageNamed:@"cloud.fog.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 24)
            weatherImage = [UIImage systemImageNamed:@"wind"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode == 25)
            weatherImage = [UIImage systemImageNamed:@"snow"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode == 26)
            weatherImage = [UIImage systemImageNamed:@"cloud.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 28)
            weatherImage = [UIImage systemImageNamed:@"cloud.sun.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 30)
            weatherImage = [UIImage systemImageNamed:@"cloud.sun.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 32 && (hour >= 18 || hour <= 6))
            weatherImage = [UIImage systemImageNamed:@"thermometer.sun.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 32)
            weatherImage = [UIImage systemImageNamed:@"moon.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 34)
            weatherImage = [UIImage systemImageNamed:@"cloud.sun.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode == 35)
            weatherImage = [UIImage systemImageNamed:@"cloud.sleet.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode == 36)
            weatherImage = [UIImage systemImageNamed:@"thermometer.sun.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 38)
            weatherImage = [UIImage systemImageNamed:@"cloud.bolt.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode == 39)
            weatherImage = [UIImage systemImageNamed:@"cloud.sun.rain.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode == 40)
            weatherImage = [UIImage systemImageNamed:@"cloud.heavyrain.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
        else if (currentCode <= 43)
            weatherImage = [UIImage systemImageNamed:@"cloud.snow.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
    } else {
        weatherImage = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]];
    }
    
    return weatherImage;
}

-(NSString *)conditionsDescription {
	if (self.todayModel.forecastModel.currentConditions != nil)
		return WAConditionsLineStringFromCurrentForecasts(self.todayModel.forecastModel.currentConditions) ?: @"Sun";
	return @"Sun";
}

-(NSString *)lowDescription {
	return [self lowDescription:NO];
}

-(NSString *)lowDescription:(BOOL) withSymbol {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[self useFahrenheit] ? 1 : 2];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:withSymbol];

	NSString *lowTemperature = @"--";

	NSArray *dailyForecasts = self.todayModel.forecastModel.dailyForecasts;
	if (dailyForecasts != nil && dailyForecasts.count > 0) {
		WADayForecast *todayForecast = dailyForecasts.firstObject;
		lowTemperature = [temperatureFormatter stringForObjectValue:todayForecast.low];
	}

	return lowTemperature;
}

-(NSString *)highDescription {
	return [self highDescription:NO];
}

-(NSString *)highDescription:(BOOL) withSymbol {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[self useFahrenheit] ? 1 : 2];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:withSymbol];

	NSString *highTemperature = @"--";

	NSArray *dailyForecasts = self.todayModel.forecastModel.dailyForecasts;
	if (dailyForecasts != nil && dailyForecasts.count > 0) {
		WADayForecast *todayForecast = dailyForecasts.firstObject;
		highTemperature = [temperatureFormatter stringForObjectValue:todayForecast.high];
	}

	return highTemperature;
}

-(NSString *)windSpeed {
	return [self windSpeed:YES];
}

-(NSString *)windSpeed:(BOOL) withUnit {
	NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
	formatter.locale = self.locale;
	NSString *windSpeedString = nil;
	NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:self.todayModel.forecastModel.currentConditions.windSpeed unit:NSUnitSpeed.kilometersPerHour];
	measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitSpeed.milesPerHour];
	if (withUnit) {
		windSpeedString = [formatter stringFromMeasurement:measurement];
	} else
		windSpeedString = [self formatFloat:measurement.doubleValue];
	return windSpeedString ?: @"--";
}

-(NSString *)windDirection {
	return [self windDirection:NO];
}

-(NSString *)windDirection:(BOOL) shortDescription {
	WeatherWindSpeedFormatter * formatter = [WeatherWindSpeedFormatter convenienceFormatter];
	// formatter.locale = self.locale;
	NSString *windDirectionString = nil;
	windDirectionString = [formatter stringForWindDirection:self.todayModel.forecastModel.currentConditions.windDirection shortDescription:shortDescription];
	return windDirectionString ?: @"--";
}

-(NSString *)humidity {
	return [self humidity:NO];
}

-(NSString *)humidity:(BOOL) withSymbol {
	if (self.todayModel.forecastModel.currentConditions != nil)
		return [NSString stringWithFormat:withSymbol ? @"%.0f%%" : @"%.0f", self.todayModel.forecastModel.currentConditions.humidity];
	return @"--";
}

-(NSString *)visibility {
	return [self visibility:NO];
}

-(NSString *)visibility:(BOOL) withUnit {
	NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
	formatter.locale = self.locale;
	NSString *visibilityString = nil;
	NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:self.todayModel.forecastModel.currentConditions.visibility unit:NSUnitLength.kilometers];
	measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.miles];
	if (withUnit) 
		visibilityString = [formatter stringFromMeasurement:measurement];
	else
		visibilityString = [self formatFloat:measurement.doubleValue];
	return visibilityString ?: @"--";
}

-(NSString *)precipitationPast24Hours {
	return [self precipitationPast24Hours:NO];
}

-(NSString *)precipitationPast24Hours:(BOOL) withUnit {
	NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
	formatter.locale = self.locale;
	NSString *precipitationString = nil;
	NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:self.todayModel.forecastModel.currentConditions.precipitationPast24Hours unit:NSUnitLength.millimeters];
	measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitLength.inches];
	if (withUnit) 
		precipitationString = [formatter stringFromMeasurement:measurement];
	else
		precipitationString = [self formatFloat:measurement.doubleValue];
	return precipitationString ?: @"--";
}

-(NSString *)precipitationNextHour {
	return [self precipitationNextHour:NO];
}

-(NSString *)precipitationNextHour:(BOOL) withSymbol {
	NSArray *hourlyForecasts = self.todayModel.forecastModel.hourlyForecasts;
	if (hourlyForecasts.count > 0) {
		WAHourlyForecast *hourlyForecast = [hourlyForecasts firstObject];
		return [NSString stringWithFormat:withSymbol ? @"%.0f%%" : @"%.0f", hourlyForecast.percentPrecipitation];
	}
	return @"--";
}

-(NSString *)pressure {
	return [self pressure:NO];
}

-(NSString *)pressure:(BOOL) withUnit {
	NSMeasurementFormatter *formatter = [[self class] sharedNSMeasurementFormatter];
	formatter.locale = self.locale;
	NSString *pressureString = nil;
	NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:self.todayModel.forecastModel.currentConditions.pressure unit:NSUnitPressure.hectopascals];
	measurement = [self useMetric] ? measurement : [measurement measurementByConvertingToUnit:NSUnitPressure.poundsForcePerSquareInch];
	if (withUnit) 
		pressureString = [formatter stringFromMeasurement:measurement];
	else
		pressureString = [self formatFloat:measurement.doubleValue];
	return pressureString ?: @"--";
}

-(NSString *)UVIndex {
	if (self.todayModel.forecastModel.currentConditions != nil)
		return [NSString stringWithFormat:@"%llu", self.todayModel.forecastModel.currentConditions.UVIndex];
	return @"--";
}

-(NSString *)airQualityIndex {
	if (self.todayModel.forecastModel.airQualityConditions != nil)
		return [NSString stringWithFormat:@"%lu", self.todayModel.forecastModel.airQualityConditions.localizedAirQualityIndex];
	return @"--";
}

-(NSDictionary *)weatherData:(double) fontSize {
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	[data setObject:self.conditionsDescription forKey:@"conditions"];
	[data setObject:self.conditionsImage forKey:@"conditions_image"];
	[data setObject:[self conditionsImage2:fontSize] forKey:@"conditions_image2"];
	[data setObject:self.conditionsEmoji forKey:@"conditions_emoji"];
	[data setObject:self.locationName forKey:@"location"];
	[data setObject:self.UVIndex forKey:@"uv_index"];
	[data setObject:self.airQualityIndex forKey:@"aqi"];

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

	[data setObject:self.precipitationPast24Hours forKey:@"precipitation_24h"];
	[data setObject:[self precipitationPast24Hours:YES] forKey:@"precipitation_24h_with_unit"];

	[data setObject:self.pressure forKey:@"pressure"];
	[data setObject:[self pressure:YES] forKey:@"pressure_with_unit"];
	return [data copy];
}

-(WAForecastModel *)forcastModel {
	return self.todayModel.forecastModel;
}

- (NSBundle *)weatherBundle {
	if (!_weatherBundle) {
		_weatherBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Weather.framework"];
		[_weatherBundle load];
	}
	
	return _weatherBundle;
}

- (UIImage *)imageForKey:(NSString *)key {
	return [UIImage imageNamed:key inBundle:[self weatherBundle] compatibleWithTraitCollection:nil];
}

- (NSString *)formatFloat:(double)f {
    if (fmodf(f, 1)==0) {
        return [NSString stringWithFormat:@"%.0f",f];
    } else {
        return [NSString stringWithFormat:@"%.1f",f];
    }
}

-(void)updateModel {
	if (!self.widgetVC) {
        self.widgetVC = [[WALockscreenWidgetViewController alloc] init];

        if ([self.widgetVC respondsToSelector:@selector(_setupWeatherModel)]) {
            [self.widgetVC _setupWeatherModel];
        }
    }

    if (self.widgetVC) {
        if ([self.widgetVC.todayModel respondsToSelector:@selector(executeModelUpdateWithCompletion:)]) {
            
            if ([self.widgetVC.todayModel isKindOfClass:[WATodayAutoupdatingLocationModel class]]) {
				WeatherPreferences *preferences = [WeatherPreferences sharedPreferences];
                WATodayAutoupdatingLocationModel *autoUpdatingModel = (WATodayAutoupdatingLocationModel *)self.widgetVC.todayModel;
				autoUpdatingModel.preferences = preferences;
				[autoUpdatingModel setLocationServicesActive:YES];
				[autoUpdatingModel setIsLocationTrackingEnabled:YES];

                if ([autoUpdatingModel respondsToSelector:@selector(updateLocationTrackingStatus)]) {
			        [autoUpdatingModel updateLocationTrackingStatus];
                }
            }
           
            [self.widgetVC.todayModel executeModelUpdateWithCompletion:nil];
        }
        if ([self.widgetVC respondsToSelector:@selector(todayModelWantsUpdate:)] && self.widgetVC.todayModel) {
            [self.widgetVC todayModelWantsUpdate:self.widgetVC.todayModel];
        }
        if ([self.widgetVC respondsToSelector:@selector(updateWeather)]) {
            [self.widgetVC updateWeather];
        }
        if ([self.widgetVC respondsToSelector:@selector(_updateTodayView)]) {
		    [self.widgetVC _updateTodayView];
        }
        if ([self.widgetVC respondsToSelector:@selector(_updateWithReason:)]) {
            [self.widgetVC _updateWithReason:nil];
        }
        
        /*if ([self.widgetVC respondsToSelector:@selector(_temperature)]) {
		    self.currentTemperature = [self.widgetVC _temperature];
	    }

        if ([self.widgetVC respondsToSelector:@selector(_locationName)]) {
		    self.myCity = [self.widgetVC _locationName];
	    }*/
    }

    if (self.widgetVC.todayModel.forecastModel.city) {
        self.myCity = self.widgetVC.todayModel.forecastModel.city;
    }

	if (self.widgetVC.todayModel.forecastModel.city) {
        self.todayModel = self.widgetVC.todayModel;
    }
}

@end