//
//  IWeather.mm
//  Helium
//
//  Created by Fuuko on 2024/4/16.
//

#import "IWeather.h"

@implementation IWeather : NSObject

- (NSString *)formatFloat:(double)f {
    if (fmodf(f, 1) == 0) {
        return [NSString stringWithFormat:@"%.0f", f];
    } else {
        return [NSString stringWithFormat:@"%.1f", f];
    }
}

- (NSMeasurementFormatter *)sharedNSMeasurementFormatter {
    static NSMeasurementFormatter *formatter = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        formatter = [[NSMeasurementFormatter alloc] init];
        [formatter setUnitOptions:NSMeasurementFormatterUnitOptionsProvidedUnit];
        formatter.numberFormatter.maximumFractionDigits = 1;
    });
    return formatter;
}

- (void)updateLocation:(IWeatherLocationCallbackBlock)locationCallback {
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

- (NSString *)conditionsDescription {
    return nil;
}

- (NSString *)conditionsEmoji {
    return nil;
}

- (UIImage *)conditionsImage:(double)fontSize {
    return nil;
}

- (NSString *)feelsLike:(BOOL)withSymbol {
    return nil;
}

- (NSString *)feelsLike {
    return nil;
}

- (NSDictionary *)getWeatherData {
    return nil;
}

- (NSString *)highDescription:(BOOL)withSymbol {
    return nil;
}

- (NSString *)highDescription {
    return nil;
}

- (NSString *)humidity:(BOOL)withSymbol {
    return nil;
}

- (NSString *)humidity {
    return nil;
}

- (NSString *)lowDescription:(BOOL)withSymbol {
    return nil;
}

- (NSString *)lowDescription {
    return nil;
}

- (NSString *)precipitationNextHour:(BOOL)withSymbol {
    return nil;
}

- (NSString *)precipitationNextHour {
    return nil;
}

- (NSString *)precipitationPast24Hours:(BOOL)withUnit {
    return nil;
}

- (NSString *)precipitationPast24Hours {
    return nil;
}

- (NSString *)precipitationPercentNextHour:(BOOL)withSymbol {
    return nil;
}

- (NSString *)precipitationPercentNextHour {
    return nil;
}

- (NSString *)pressure:(BOOL)withUnit {
    return nil;
}

- (NSString *)pressure {
    return nil;
}

- (NSString *)temperature:(BOOL)withSymbol {
    return nil;
}

- (NSString *)temperature {
    return nil;
}

- (NSString *)visibility:(BOOL)withUnit {
    return nil;
}

- (NSString *)visibility {
    return nil;
}

- (NSString *)windDirection {
    return nil;
}

- (NSString *)windSpeed:(BOOL)withUnit {
    return nil;
}

- (NSString *)windSpeed {
    return nil;
}

- (void)updateWeather:(__strong IWeatherDataCallbackBlock)dataCallback {
}

+ (instancetype)sharedInstance {
    return nil;
}

@end
