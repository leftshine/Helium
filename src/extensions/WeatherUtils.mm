#import "WeatherUtils.h"

@implementation WeatherUtils
+ (NSString*)formatWeatherData:(NSDictionary *)data format:(NSString *)format {
    if(data) {
        @try {
            format = [format stringByReplacingOccurrencesOfString:@"{n}" withString:data[@"conditions"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{e}" withString:data[@"conditions_emoji"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{l}" withString:data[@"location"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{uvi}" withString:data[@"uv_index"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{aqi}" withString:data[@"aqi"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{t}" withString:data[@"temperature"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{ts}" withString:data[@"temperature_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{bt}" withString:data[@"feels_like"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{bts}" withString:data[@"feels_like_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{lt}" withString:data[@"low_temperature"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{lts}" withString:data[@"low_temperature_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{ht}" withString:data[@"high_temperature"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{hts}" withString:data[@"high_temperature_with_symbol"]?:@""];
            
            format = [format stringByReplacingOccurrencesOfString:@"{ws}" withString:data[@"wind_speed"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{wsu}" withString:data[@"wind_speed_with_unit"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{wd}" withString:data[@"wind_direction"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{wds}" withString:data[@"wind_direction_short"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{h}" withString:data[@"humidity"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{hs}" withString:data[@"humidity_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{v}" withString:data[@"visibility"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{vu}" withString:data[@"visibility_with_unit"]?:@""];
            
            format = [format stringByReplacingOccurrencesOfString:@"{pp}" withString:data[@"precipitation_next_hour"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{pps}" withString:data[@"precipitation_next_hour_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{ppn}" withString:data[@"precipitation_percent_next_hour"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{ppns}" withString:data[@"precipitation_percent_next_hour_with_symbol"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{pp24}" withString:data[@"precipitation_24h"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{pp24u}" withString:data[@"precipitation_24h_with_unit"]?:@""];

            format = [format stringByReplacingOccurrencesOfString:@"{ps}" withString:data[@"pressure"]?:@""];
            format = [format stringByReplacingOccurrencesOfString:@"{psu}" withString:data[@"pressure_with_unit"]?:@""];
        }
        @catch (NSException *exception) {
            NSLog(@"[ERROR]\nstr[%@]\nexception[%@]", format, exception);
            format = NSLocalizedString(@"error", comment:@"");
        }
    } else {
        format = NSLocalizedString(@"error", comment:@"");
    }
    return format;
}

@end