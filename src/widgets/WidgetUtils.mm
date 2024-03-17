#import "WidgetUtils.h"
#import <net/if.h>
#import <ifaddrs.h>
#import <sys/wait.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <IOKit/IOKitLib.h>

#import "../extensions/UsefulFunctions.h"
#import "../extensions/LunarDate.h"
#import "../extensions/MusicPlayerUtils.h"
#import "../extensions/MediaRemoteManager.h"
#import "../extensions/Weather/WeatherUtils.h"
#import "../extensions/Weather/QWeather.h"
#import "../extensions/Weather/ColorfulClouds.h"
#import "../extensions/Weather/TWCWeather.h"

@implementation WidgetUtils
+ (instancetype)sharedInstance {
	static WidgetUtils *_shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_shared = [[self alloc] init];
	});
	return _shared;
}

- (instancetype)init {
	self = [super init];

	if (self != nil) {
		if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
        }
        prevOutputBytes = 0;
        prevInputBytes = 0;
        if (!attributedUploadPrefix)
            attributedUploadPrefix = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:"▲"] stringByAppendingString:@" "]];
        if (!attributedDownloadPrefix)
            attributedDownloadPrefix = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:"▼"] stringByAppendingString:@" "]];
        if (!attributedUploadPrefix2)
            attributedUploadPrefix2 = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:"↑"] stringByAppendingString:@" "]];
        if (!attributedDownloadPrefix2)
            attributedDownloadPrefix2 = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:"↓"] stringByAppendingString:@" "]];
	}
	return self;
}

#pragma mark - Date Widget
- (void)formattedDate:(NSString *)format locale:(NSString *) locale callback:(CallbackBlock) callback {
    @autoreleasepool {
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:locale];
        NSDate *currentDate = [NSDate date];
        NSString *newDateFormat = [LunarDate getChineseCalendarWithDate:currentDate format:format];
        [formatter setDateFormat:newDateFormat];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[formatter stringFromDate:currentDate]];
        attributedString = [self formatString:attributedString];
        callback([attributedString copy]);
    }
}

// Thanks to: https://github.com/lwlsw/NetworkSpeed13
#pragma mark - Net Speed Widgets
- (UpDownBytes)getUpDownBytes {
    struct ifaddrs *ifa_list = 0, *ifa;
    UpDownBytes upDownBytes;
    upDownBytes.inputBytes = 0;
    upDownBytes.outputBytes = 0;
    
    if (getifaddrs(&ifa_list) == -1) return upDownBytes;

    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
    {
        /* Skip invalid interfaces */
        if (ifa->ifa_name == NULL || ifa->ifa_addr == NULL || ifa->ifa_data == NULL)
            continue;
        
        /* Skip interfaces that are not link level interfaces */
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;

        /* Skip interfaces that are not up or running */
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            continue;
        
        /* Skip interfaces that are not ethernet or cellular */
        if (strncmp(ifa->ifa_name, "en", 2) && strncmp(ifa->ifa_name, "pdp_ip", 6))
            continue;
        
        struct if_data *if_data = (struct if_data *)ifa->ifa_data;
        
        upDownBytes.inputBytes += if_data->ifi_ibytes;
        upDownBytes.outputBytes += if_data->ifi_obytes;
    }
    
    freeifaddrs(ifa_list);
    return upDownBytes;
}

- (NSString *)formattedSpeed:(uint64_t)bytes minUnit:(NSInteger) minUnit {
    if (0 == DATAUNIT) {
        // Get min units first
        if (minUnit == 1 && bytes < KILOBYTES) return @"0 KB/s";
        else if (minUnit == 2 && bytes < MEGABYTES) return @"0 MB/s";
        else if (minUnit == 3 && bytes < GIGABYTES) return @"0 GB/s";

        if (bytes < KILOBYTES) return [NSString stringWithFormat:@"%.0f B/s", (double)bytes];
        else if (bytes < MEGABYTES) return [NSString stringWithFormat:@"%.0f KB/s", (double)bytes / KILOBYTES];
        else if (bytes < GIGABYTES) return [NSString stringWithFormat:@"%.2f MB/s", (double)bytes / MEGABYTES];
        else return [NSString stringWithFormat:@"%.2f GB/s", (double)bytes / GIGABYTES];
    } else {
        // Get min units first
        if (minUnit == 1 && bytes < KILOBITS) return @"0 Kb/s";
        else if (minUnit == 2 && bytes < MEGABITS) return @"0 Mb/s";
        else if (minUnit == 3 && bytes < GIGABITS) return @"0 Gb/s";

        if (bytes < KILOBITS) return [NSString stringWithFormat:@"%.0f b/s", (double)bytes];
        else if (bytes < MEGABITS) return [NSString stringWithFormat:@"%.0f Kb/s", (double)bytes / KILOBITS];
        else if (bytes < GIGABITS) return [NSString stringWithFormat:@"%.2f Mb/s", (double)bytes / MEGABITS];
        else return [NSString stringWithFormat:@"%.2f Gb/s", (double)bytes / GIGABITS];
    }
}

- (void)formattedAttributedSpeedString:(BOOL)isUp speedIcon:(NSInteger) speedIcon minUnit:(NSInteger) minUnit hideWhenZero:(BOOL) hideWhenZero callback:(CallbackBlock) callback {
    @autoreleasepool {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
        UpDownBytes upDownBytes = [self getUpDownBytes];
        uint64_t diff;
        
        if (isUp) {
            if (upDownBytes.outputBytes > prevOutputBytes)
                diff = upDownBytes.outputBytes - prevOutputBytes;
            else
                diff = 0;
            prevOutputBytes = upDownBytes.outputBytes;
        } else {
            if (upDownBytes.inputBytes > prevInputBytes)
                diff = upDownBytes.inputBytes - prevInputBytes;
            else
                diff = 0;
            prevInputBytes = upDownBytes.inputBytes;
        }
        
        if (DATAUNIT == 1)
            diff *= 8;
        
        NSString *speedString = [self formattedSpeed:diff minUnit:minUnit];
        if (!hideWhenZero || ![speedString hasPrefix:@"0"]) {
            if (isUp)
                [attributedString appendAttributedString:(speedIcon == 0 ? attributedUploadPrefix : attributedUploadPrefix2)];
            else
                [attributedString appendAttributedString:(speedIcon == 0 ? attributedDownloadPrefix : attributedDownloadPrefix2)];
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:speedString]];
        }
        attributedString = [self formatString:attributedString];
        callback([attributedString copy]);
    }
}

#pragma mark - Battery Temp Widget
- (NSDictionary *) getBatteryInfo {
    CFDictionaryRef matching = IOServiceMatching("IOPMPowerSource");
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
    CFMutableDictionaryRef prop = NULL;
    IORegistryEntryCreateCFProperties(service, &prop, NULL, 0);
    NSDictionary* dict = (__bridge_transfer NSDictionary*)prop;
    IOObjectRelease(service);
    return dict;
}

- (void)formattedTemp:(BOOL)useFahrenheit callback:(CallbackBlock) callback {
    @autoreleasepool {
        NSString *result = useFahrenheit ? @"??ºF" : @"??ºC";
        NSDictionary *batteryInfo = [self getBatteryInfo];
        if (batteryInfo) {
            // AdapterDetails.Watts.Description.Temperature
            double temp = [batteryInfo[@"Temperature"] doubleValue] / 100.0;
            if (temp) {
                if (useFahrenheit) {
                    temp = (temp * 9.0/5.0) + 32;
                    result = [NSString stringWithFormat: @"%.1fºF", temp];
                } else {
                    result = [NSString stringWithFormat: @"%.1fºC", temp];
                }
            }
        }
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:result];
        attributedString = [self formatString:attributedString];
        callback([attributedString copy]);
    }
}

#pragma mark - Battery Widget
/*
 Battery Widget Identifiers:
 0 = Watts
 1 = Charging Current
 2 = Regular Amperage
 3 = Charge Cycles
 */
- (void)formattedBattery:(NSInteger)valueType callback:(CallbackBlock) callback {
    @autoreleasepool {
        NSString *result = @"??";
        NSDictionary *batteryInfo = [self getBatteryInfo];
        if (batteryInfo) {
            if (valueType == 0) {
                // Watts
                int watts = [batteryInfo[@"AdapterDetails"][@"Watts"] longLongValue];
                if (watts) {
                    result = [NSString stringWithFormat: @"%d W", watts];
                } else {
                    result = @"0 W";
                }
            } else if (valueType == 1) {
                // Charging Current
                double current = [batteryInfo[@"AdapterDetails"][@"Current"] doubleValue];
                if (current) {
                    result = [NSString stringWithFormat: @"%.0f mA", current];
                } else {
                    result = @"0 mA";
                }
            } else if (valueType == 2) {
                // Regular Amperage
                double amps = [batteryInfo[@"Amperage"] doubleValue];
                if (amps) {
                    result = [NSString stringWithFormat: @"%.0f mA", amps];
                } else {
                    result = @"0 mA";
                }
            } else if (valueType == 3) {
                // Charge Cycles
                result = [batteryInfo[@"CycleCount"] stringValue];
            } else {
                result = @"??";
            }
        }
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:result];
        attributedString = [self formatString:attributedString];
        callback([attributedString copy]);
    }
}

#pragma mark - Current Capacity Widget
- (void)formattedCurrentCapacity:(BOOL)showPercentage callback:(CallbackBlock) callback {
    @autoreleasepool {
        NSString *result = @"??%";
        NSDictionary *batteryInfo = [self getBatteryInfo];
        if (batteryInfo) {
            result = [
                NSString stringWithFormat: @"%@%@",
                [batteryInfo[@"CurrentCapacity"] stringValue],
                showPercentage ? @"%" : @""
                ];
        }
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:result];
        attributedString = [self formatString:attributedString];
        callback([attributedString copy]);
    }
}

#pragma mark - Charging Symbol Widget
- (NSString *)formattedChargingSymbol:(BOOL)filled {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled: YES];
    if ([[UIDevice currentDevice] batteryState] != UIDeviceBatteryStateUnplugged) {
        if (filled) {
            return @"bolt.fill";
        } else {
            return @"bolt";
        }
    }
    return @"";
}

-(void)formattedChargingSymbolImage:(BOOL)filled fontSize:(double)  fontSize textColor:(UIColor *) textColor callback:(CallbackBlock) callback {
    @autoreleasepool {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
        NSTextAttachment *imageAttachment;
        NSString *sfSymbolName = [self formattedChargingSymbol:filled];
        if (![sfSymbolName isEqualToString:@""]) {
            imageAttachment = [[NSTextAttachment alloc] init];
            imageAttachment.image = [
                [
                    UIImage systemImageNamed:sfSymbolName
                    withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize]
                ]
                imageWithTintColor:textColor
            ];
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:imageAttachment]];
        }
        attributedString = [self formatString:attributedString];
        callback([attributedString copy]);
    }
}

#pragma mark - Weather Widget
- (NSMutableAttributedString *)replaceWeatherImage:(NSString *)formattedText replacement:(NSAttributedString *) replacement {
    @autoreleasepool {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{([^}]+)\\}" options:NSRegularExpressionAnchorsMatchLines error:nil];
        NSArray *matches = [regex matchesInString:formattedText options:kNilOptions range:NSMakeRange(0, formattedText.length)];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:formattedText];
        for (NSTextCheckingResult *result in [matches reverseObjectEnumerator])
        {
            NSString *match = [formattedText substringWithRange:result.range];
            if ([match isEqual:@"{i}"]) {
                [attributedString replaceCharactersInRange:result.range withAttributedString:replacement];
            }
        }
        return [attributedString copy];
    }
}

- (NSAttributedString *)formattedWeatherData:(NSDictionary *)weatherData format:(NSString *) format textColor:(UIColor *) textColor {
    @autoreleasepool {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
        NSTextAttachment *imageAttachment;
        if (weatherData != nil) {
            format = [WeatherUtils formatWeatherData:weatherData format:format];
            // NSLog(@"boom format:%@", format);

            UIImage *weatherImage = weatherData[@"conditions_image"];
            if (weatherImage) {
                imageAttachment = [[NSTextAttachment alloc] init];
                // CGFloat imgH = font.pointSize;// * 1.4f;
                // CGFloat imgW = (weatherImage.size.width / weatherImage.size.height) * imgH;
                // [imageAttachment setBounds:CGRectMake(0, roundf(font.capHeight - imgH)/2.f, imgW, imgH)];
                weatherImage = [weatherImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                imageAttachment.image = [weatherImage 
                    imageWithTintColor:textColor
                ];
                [attributedString appendAttributedString:[self replaceWeatherImage:format
                    replacement: [NSAttributedString attributedStringWithAttachment:imageAttachment]
                ]];
            } else {
                [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:format]];
            }
        }
        return [attributedString copy];
    }
}

- (void)formattedWeatherString:(NSString *)location format:(NSString *) format useCurrentLocation:(BOOL) useCurrentLocation useMetric:(BOOL) useMetric useFahrenheit:(BOOL) useFahrenheit locale:(NSString *) locale fontSize:(double) fontSize textColor:(UIColor *) textColor weatherProvider:(NSInteger) weatherProvider weatherApiKey:(NSString *) weatherApiKey freeSub:(BOOL) freeSub callback:(CallbackBlock) callback {
    @autoreleasepool {
        if (weatherProvider == 0) {
            TWCWeather *twcWeather = [TWCWeather sharedInstance];
            twcWeather.locale = [[NSLocale alloc] initWithLocaleIdentifier:locale];
            twcWeather.useFahrenheit = useFahrenheit;
            twcWeather.useMetric = useMetric;
            twcWeather.fontSize = fontSize;
            [twcWeather updateModel:^(NSDictionary *weatherData) {
                if (weatherData != nil) {
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self formattedWeatherData:weatherData format:format textColor:textColor]];
                    attributedString = [self formatString:attributedString];
                    callback([attributedString copy]);
                }
            }];
        } else if (weatherProvider == 1) {
            QWeather *qweather = [QWeather sharedInstance];
            qweather.useMetric = useMetric;
            qweather.useFahrenheit = useFahrenheit;
            qweather.apiKey = weatherApiKey;
            qweather.freeSub = freeSub;
            qweather.locale = locale;
            qweather.fontSize = fontSize;
            qweather.useCurrentLocation = useCurrentLocation;
            qweather.location = location;
            [qweather updateWeather:^(NSDictionary *weatherData) {
                if (weatherData != nil) {
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self formattedWeatherData:weatherData format:format textColor:textColor]];
                    attributedString = [self formatString:attributedString];
                    callback([attributedString copy]);
                }
            }];
        } else if(weatherProvider == 2) {
            ColorfulClouds *colorfulClouds = [ColorfulClouds sharedInstance];
            colorfulClouds.useMetric = useMetric;
            colorfulClouds.useFahrenheit = useFahrenheit;
            colorfulClouds.apiKey = weatherApiKey;
            colorfulClouds.locale = locale;
            colorfulClouds.fontSize = fontSize;
            colorfulClouds.useCurrentLocation = useCurrentLocation;
            colorfulClouds.location = location;
            [colorfulClouds updateWeather:^(NSDictionary *weatherData) {
                if (weatherData != nil) {
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self formattedWeatherData:weatherData format:format textColor:textColor]];
                    attributedString = [self formatString:attributedString];
                    callback([attributedString copy]);
                }
            }];
        } else {
            callback(nil);
        }
    }
}

#pragma mark - Lyrics Widget
- (void)formattedLyricsString:(NSInteger)lyricsType bluetoothType:(NSInteger) bluetoothType wiredType:(NSInteger) wiredType unsupported:(BOOL) unsupported callback:(CallbackBlock) callback {
    @autoreleasepool {
        MediaRemoteManager *manager = [MediaRemoteManager sharedManager];
        [manager getNowPlayingApplicationIsPlayingWithCompletion:^(BOOL isPlaying) {
            if (isPlaying) {
                [manager getBundleIdentifierWithCompletion:^(NSString *bundleIdentifier) {
                    NSString *lyricsKey = [MusicPlayerUtils getLyricsKeyByBundleIdentifier:bundleIdentifier lyricsType:lyricsType bluetoothType:bluetoothType wiredType:wiredType unsupported:unsupported];
                    [manager getNowPlayingInfoWithCompletion:^(NSDictionary *info) {
                        if (info) {
                            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:info[lyricsKey]];
                            attributedString = [self formatString:attributedString];
                            callback([attributedString copy]);
                        } else {
                            callback(nil);
                        }
                    }];
                }];
            } else {
                callback(nil);
            }
        }];
    }
}

#pragma mark - Other Functions
- (NSAttributedString *)emptyAtributedWhitespace {
    // You can put any random string there or how many spaces you want
    return [[NSAttributedString alloc] initWithString:@"." attributes:@{ NSForegroundColorAttributeName : [UIColor clearColor]}];
}

- (NSMutableAttributedString *)formatString:(NSMutableAttributedString *)attributedString {
    NSString *text = attributedString.string;
    NSInteger length = text.length;
    
    if (length > 0 && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[text characterAtIndex:length - 1]]) {
        [attributedString replaceCharactersInRange:NSMakeRange(length - 1, 1) withAttributedString:[self emptyAtributedWhitespace]];
    }
    
    return attributedString;
}
@end
