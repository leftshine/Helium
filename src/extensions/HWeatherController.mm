// https://github.com/DGh0st/HSWidgets
// https://github.com/CreatureSurvive/CSWeather
// https://github.com/midnightchip/Asteroid
#import "HWeatherController.h"
#import "HWeatherControllerObserver.h"
#import "UsefulFunctions.h"

#import <CoreLocation/CLLocation.h>
#import <CoreLocation/CLLocationManager.h>

#define FAKE_PAD_WEATHER @"FakePadWeather"
#define FAKE_PAD_WEATHER_LATITUDE @"FakePadWeatherLatitude"
#define FAKE_PAD_WEATHER_LONGITUDE @"FakePadWeatherLongitude"
#define FAKE_PAD_WEATHER_DISPLAY_NAME @"FakePadWeatherDisplayName"
#define FAKE_PAD_WEATHER_CONDITION_TEMPERATURE @"FakePadWeatherConditionTemperature"
#define FAKE_PAD_WEATHER_CONDITION_DESCRIPTION @"FakePadWeatherConditionDescription"
#define FAKE_PAD_WEATHER_CONDITION @"FakePadWeatherCondition"
#define FAKE_LATITUDE 37.3333702
#define FAKE_LONGITUDE -122.029488

NSString *const HWeatherFakeDisplayName = @"Cupertino, CA";
NSString *const HWeatherFakeDescription = @"Sunny";
NSString *const HWeatherFakeTemperature = @"--";

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
		self.todayModel = nil;
		[self _setupWeatherModel];
		self.observers = [NSMutableArray array];
		self.useFahrenheit = NO;
		self.useMetric = YES;

		// TODO: find out if this notification is ever posted or if updating location tracking is enough
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_cityDidUpdate:) name:kCityNotificationNameDidUpdate object:nil];
	}
	return self;
}

-(NSString *)locationName {
	if ([self _shouldFakeWeather]) {
		return [[WeatherInternalPreferences sharedInternalPreferences] objectForKey:FAKE_PAD_WEATHER_DISPLAY_NAME] ?: HWeatherFakeDisplayName;
	} else {
		NSString *name = self.todayModel.forecastModel.city.name;
		if (name)
			return name;
		return self.todayModel.forecastModel.location.displayName ?: HWeatherFakeDisplayName;
	}
}

-(NSString *)temperature {
	return [self temperature:NO];
}

-(NSString *)temperature:(BOOL) withSymbol {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[self useFahrenheit] ? 1 : 2];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:withSymbol];

	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	id fakeConditionTemperature = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION_TEMPERATURE];

	NSString *temperatureString = nil;
	if ([self _shouldFakeWeather] && fakeConditionTemperature != nil)
		temperatureString = [temperatureFormatter stringForObjectValue:fakeConditionTemperature];
	else
		temperatureString = [temperatureFormatter stringForObjectValue:self.todayModel.forecastModel.currentConditions.temperature];
	return temperatureString ?: HWeatherFakeTemperature;
}

-(NSString *)feelsLike {
	return [self feelsLike:NO];
}

-(NSString *)feelsLike:(BOOL) withSymbol {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[self useFahrenheit] ? 1 : 2];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:withSymbol];

	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	id fakeConditionTemperature = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION_TEMPERATURE];

	NSString *temperatureString = nil;
	if ([self _shouldFakeWeather] && fakeConditionTemperature != nil)
		temperatureString = [temperatureFormatter stringForObjectValue:fakeConditionTemperature];
	else
		temperatureString = [temperatureFormatter stringForObjectValue:self.todayModel.forecastModel.currentConditions.feelsLike];
	return temperatureString ?: HWeatherFakeTemperature;
}

-(UIImage *)conditionsImageLegacy {
	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	if ([self _shouldFakeWeather]) {
		NSNumber *condition = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION];
		if (condition != nil)
			return WAImageForLegacyConditionCode([condition intValue]);
	}

	if (self.todayModel.forecastModel.currentConditions != nil)
		return WAImageForLegacyConditionCode(self.todayModel.forecastModel.currentConditions.conditionCode);
	return WAImageForLegacyConditionCode(32);
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
	} @catch (NSException *e) {}
	return conditionsImg;
}

-(NSString *)conditionsImageName {
	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	if ([self _shouldFakeWeather]) {
		NSNumber *condition = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION];
		if (condition != nil)
			return [WeatherImageLoader conditionImageNameWithConditionIndex:[condition intValue]];
	}

	if (self.todayModel.forecastModel.currentConditions != nil)
		return [WeatherImageLoader conditionImageNameWithConditionIndex:self.todayModel.forecastModel.currentConditions.conditionCode];
	return [WeatherImageLoader conditionImageNameWithConditionIndex:32];
}

-(NSString *)conditionsDescription {
	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	if ([self _shouldFakeWeather])
		return [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION_DESCRIPTION] ?: HWeatherFakeDescription;

	if ([internalPreferences respondsToSelector:@selector(isV3Enabled)] && [internalPreferences isV3Enabled]) {
		WFAQIScaleCategory *airQualityScaleCategory = self.todayModel.forecastModel.city.airQualityScaleCategory;
		NSString *longDescription = airQualityScaleCategory.longDescription;		
		if (longDescription != nil && airQualityScaleCategory.categoryIndex > airQualityScaleCategory.warningLevel)
			return longDescription;
	}

	if (self.todayModel.forecastModel.currentConditions != nil)
		return WAConditionsLineStringFromCurrentForecasts(self.todayModel.forecastModel.currentConditions) ?: HWeatherFakeDescription;
	return HWeatherFakeDescription;
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

	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	id fakeConditionTemperature = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION_TEMPERATURE];
	if ([self _shouldFakeWeather] && fakeConditionTemperature != nil) {
		lowTemperature = [temperatureFormatter stringForObjectValue:fakeConditionTemperature];
	} else {
		NSArray *dailyForecasts = self.todayModel.forecastModel.dailyForecasts;
		if (dailyForecasts != nil && dailyForecasts.count > 0) {
			WADayForecast *todayForecast = dailyForecasts.firstObject;
			lowTemperature = [temperatureFormatter stringForObjectValue:todayForecast.low];
		}
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

	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	id fakeConditionTemperature = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION_TEMPERATURE];
	if ([self _shouldFakeWeather] && fakeConditionTemperature != nil) {
		highTemperature = [temperatureFormatter stringForObjectValue:fakeConditionTemperature];
	} else {
		NSArray *dailyForecasts = self.todayModel.forecastModel.dailyForecasts;
		if (dailyForecasts != nil && dailyForecasts.count > 0) {
			WADayForecast *todayForecast = dailyForecasts.firstObject;
			highTemperature = [temperatureFormatter stringForObjectValue:todayForecast.high];
		}
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

-(NSString *)precipitation {
	return [self precipitation:NO];
}

-(NSString *)precipitation:(BOOL) withUnit {
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

-(NSDictionary *)weatherData {
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	[data setObject:self.conditionsDescription forKey:@"conditions"];
	[data setObject:self.conditionsImage forKey:@"conditions_image"];
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

	[data setObject:self.precipitation forKey:@"precipitation"];
	[data setObject:[self precipitation:YES] forKey:@"precipitation_with_unit"];

	[data setObject:self.pressure forKey:@"pressure"];
	[data setObject:[self pressure:YES] forKey:@"pressure_with_unit"];
	return data;
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

-(void)requestModelUpdate {
	[self _updateLocationTracking];
	__block typeof(self) widgetController = self;
	[self.todayModel executeModelUpdateWithCompletion:^{
		[widgetController _todayModelWasUpdated];
	}];
}

-(void)addObserver:(id<HWeatherControllerObserver>)observer {
	[self.observers addObject:observer];
}

-(void)removeObserver:(id<HWeatherControllerObserver>)observer {
	[self.observers removeObject:observer];
}

-(City *)currentCity {
	return self.todayModel.forecastModel.city;
}

-(void)_todayModelWasUpdated {
	for (id<HWeatherControllerObserver> observer in self.observers)
		[observer weatherModelUpdatedForController:self];
}

-(void)_setupWeatherModel {
	if ([self _shouldFakeWeather]) {
		WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
		NSNumber *fakeLatitude = [internalPreferences objectForKey:FAKE_PAD_WEATHER_LATITUDE];
		NSNumber *fakeLongitude = [internalPreferences objectForKey:FAKE_PAD_WEATHER_LONGITUDE];
		
		CGFloat latitude;
		CGFloat longitude;
		if (fakeLatitude != nil && fakeLongitude != nil) {
			latitude = [fakeLatitude floatValue];
			longitude = [fakeLongitude floatValue];
		} else {
			latitude = FAKE_LATITUDE;
			longitude = FAKE_LONGITUDE;
		}

		CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
		WFLocation *weatherLocation = [[WFLocation alloc] init];
		[weatherLocation setGeoLocation:location];

		NSString *displayName = [internalPreferences objectForKey:FAKE_PAD_WEATHER_DISPLAY_NAME] ?: HWeatherFakeDisplayName;
		[weatherLocation setDisplayName:displayName];

		self.todayModel = [WATodayModel modelWithLocation:weatherLocation];
		[self requestModelUpdate];
	} else {
		WeatherPreferences *preferences = [[WeatherPreferences alloc] init];
		WATodayAutoupdatingLocationModel *todayModel = [WATodayModel autoupdatingLocationModelWithPreferences:preferences effectiveBundleIdentifier:nil];
		[todayModel setLocationServicesActive:[self _locationServicesActive]];
		self.todayModel = todayModel;
		[self requestModelUpdate];
	}

	[self.todayModel addObserver:self];
}

-(BOOL)_shouldFakeWeather {
	return [[[WeatherInternalPreferences sharedInternalPreferences] objectForKey:FAKE_PAD_WEATHER] boolValue];
}

-(BOOL)_locationServicesActive {
	return YES;
}

-(void)_updateLocationTracking {
	if ([self.todayModel isKindOfClass:[WATodayAutoupdatingLocationModel class]]) {
		WATodayAutoupdatingLocationModel *autoUpdatingTodayModel = (WATodayAutoupdatingLocationModel *)self.todayModel;
		if ([autoUpdatingTodayModel respondsToSelector:@selector(updateLocationTrackingStatus)]) {
			[autoUpdatingTodayModel updateLocationTrackingStatus];
		} else {
			autoUpdatingTodayModel.isLocationTrackingEnabled = [CLLocationManager locationServicesEnabled];
		}
	}
}

-(void)todayModelWantsUpdate:(WATodayModel *)model {
	[self requestModelUpdate];
}

-(void)todayModel:(WATodayModel *)model forecastWasUpdated:(id)forecast {
	[self _todayModelWasUpdated];
}

-(void)_cityDidUpdate:(id)object {
	[self requestModelUpdate];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kCityNotificationNameDidUpdate object:nil];

	if (self.todayModel != nil) {
		[self.todayModel removeObserver:self];
		self.todayModel = nil;
	}

	self.observers = nil;
}
@end