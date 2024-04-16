//
//  WidgetUtils.mm
//  Helium
//
//  Created by Fuuko on 2024/4/13.
//

#import <ifaddrs.h>
#import <IOKit/IOKitLib.h>
#import <mach/mach.h>
#import <net/if.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/wait.h>
#import "WidgetUtils.h"

#import "ColorfulClouds.h"
#import "CryptoCoinUtils.h"
#import "LunarDate.h"
#import "LyricsUtils.h"
#import "MediaRemoteManager.h"
#import "MusicPlayerUtils.h"
#import "OpenWeatherMap.h"
#import "QWeather.h"
#import "TWCWeather.h"
#import "UsefulFunctions.h"
#import "WeatherUtils.h"

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

        if (!attributedUploadPrefix) {
            attributedUploadPrefix = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:"▲"] stringByAppendingString:@" "]];
        }

        if (!attributedDownloadPrefix) {
            attributedDownloadPrefix = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:"▼"] stringByAppendingString:@" "]];
        }

        if (!attributedUploadPrefix2) {
            attributedUploadPrefix2 = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:"↑"] stringByAppendingString:@" "]];
        }

        if (!attributedDownloadPrefix2) {
            attributedDownloadPrefix2 = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:"↓"] stringByAppendingString:@" "]];
        }
    }

    return self;
}

#pragma mark - Date Widget
- (void)formattedDate:(NSString *)format locale:(NSString *)locale callback:(CallbackBlock)callback {
    @autoreleasepool {
        format = [self processWidgetString:format];
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

    if (getifaddrs(&ifa_list) == -1) {
        return upDownBytes;
    }

    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        /* Skip invalid interfaces */
        if (ifa->ifa_name == NULL || ifa->ifa_addr == NULL || ifa->ifa_data == NULL) {
            continue;
        }

        /* Skip interfaces that are not link level interfaces */
        if (AF_LINK != ifa->ifa_addr->sa_family) {
            continue;
        }

        /* Skip interfaces that are not up or running */
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING)) {
            continue;
        }

        /* Skip interfaces that are not ethernet or cellular */
        if (strncmp(ifa->ifa_name, "en", 2) && strncmp(ifa->ifa_name, "pdp_ip", 6)) {
            continue;
        }

        struct if_data *if_data = (struct if_data *)ifa->ifa_data;

        upDownBytes.inputBytes += if_data->ifi_ibytes;
        upDownBytes.outputBytes += if_data->ifi_obytes;
    }

    freeifaddrs(ifa_list);
    return upDownBytes;
}

- (NSString *)formattedSpeed:(uint64_t)bytes minUnit:(NSInteger)minUnit {
    if (0 == DATAUNIT) {
        // Get min units first
        if (minUnit == 1 && bytes < KILOBYTES) {
            return @"0 KB/s";
        } else if (minUnit == 2 && bytes < MEGABYTES) {
            return @"0 MB/s";
        } else if (minUnit == 3 && bytes < GIGABYTES) {
            return @"0 GB/s";
        }

        if (bytes < KILOBYTES) {
            return [NSString stringWithFormat:@"%.0f B/s", (double)bytes];
        } else if (bytes < MEGABYTES) {
            return [NSString stringWithFormat:@"%.0f KB/s", (double)bytes / KILOBYTES];
        } else if (bytes < GIGABYTES) {
            return [NSString stringWithFormat:@"%.2f MB/s", (double)bytes / MEGABYTES];
        } else {
            return [NSString stringWithFormat:@"%.2f GB/s", (double)bytes / GIGABYTES];
        }
    } else {
        // Get min units first
        if (minUnit == 1 && bytes < KILOBITS) {
            return @"0 Kb/s";
        } else if (minUnit == 2 && bytes < MEGABITS) {
            return @"0 Mb/s";
        } else if (minUnit == 3 && bytes < GIGABITS) {
            return @"0 Gb/s";
        }

        if (bytes < KILOBITS) {
            return [NSString stringWithFormat:@"%.0f b/s", (double)bytes];
        } else if (bytes < MEGABITS) {
            return [NSString stringWithFormat:@"%.0f Kb/s", (double)bytes / KILOBITS];
        } else if (bytes < GIGABITS) {
            return [NSString stringWithFormat:@"%.2f Mb/s", (double)bytes / MEGABITS];
        } else {
            return [NSString stringWithFormat:@"%.2f Gb/s", (double)bytes / GIGABITS];
        }
    }
}

- (void)formattedAttributedSpeedString:(BOOL)isUp speedIcon:(NSInteger)speedIcon minUnit:(NSInteger)minUnit hideWhenZero:(BOOL)hideWhenZero callback:(CallbackBlock)callback {
    @autoreleasepool {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
        UpDownBytes upDownBytes = [self getUpDownBytes];
        uint64_t diff;

        if (isUp) {
            if (upDownBytes.outputBytes > prevOutputBytes) {
                diff = upDownBytes.outputBytes - prevOutputBytes;
            } else {
                diff = 0;
            }

            prevOutputBytes = upDownBytes.outputBytes;
        } else {
            if (upDownBytes.inputBytes > prevInputBytes) {
                diff = upDownBytes.inputBytes - prevInputBytes;
            } else {
                diff = 0;
            }

            prevInputBytes = upDownBytes.inputBytes;
        }

        if (DATAUNIT == 1) {
            diff *= 8;
        }

        NSString *speedString = [self formattedSpeed:diff minUnit:minUnit];

        if (!hideWhenZero || ![speedString hasPrefix:@"0"]) {
            if (isUp) {
                [attributedString appendAttributedString:(speedIcon == 0 ? attributedUploadPrefix : attributedUploadPrefix2)];
            } else {
                [attributedString appendAttributedString:(speedIcon == 0 ? attributedDownloadPrefix : attributedDownloadPrefix2)];
            }

            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:speedString]];
        }

        attributedString = [self formatString:attributedString];
        callback([attributedString copy]);
    }
}

#pragma mark - Battery Temp Widget
- (NSDictionary *)getBatteryInfo {
    CFDictionaryRef matching = IOServiceMatching("IOPMPowerSource");
    io_service_t service = IOServiceGetMatchingService(0, matching);
    CFMutableDictionaryRef prop = NULL;

    IORegistryEntryCreateCFProperties(service, &prop, NULL, 0);
    NSDictionary *dict = (__bridge_transfer NSDictionary *)prop;
    IOObjectRelease(service);
    return dict;
}

- (void)formattedTemp:(BOOL)useFahrenheit callback:(CallbackBlock)callback {
    @autoreleasepool {
        NSString *result = useFahrenheit ? @"??ºF" : @"??ºC";
        NSDictionary *batteryInfo = [self getBatteryInfo];

        if (batteryInfo) {
            // AdapterDetails.Watts.Description.Temperature
            double temp = [batteryInfo[@"Temperature"] doubleValue] / 100.0;

            if (temp) {
                if (useFahrenheit) {
                    temp = (temp * 9.0 / 5.0) + 32;
                    result = [NSString stringWithFormat:@"%.1fºF", temp];
                } else {
                    result = [NSString stringWithFormat:@"%.1fºC", temp];
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
- (void)formattedBattery:(NSInteger)valueType callback:(CallbackBlock)callback {
    @autoreleasepool {
        NSString *result = @"??";
        NSDictionary *batteryInfo = [self getBatteryInfo];

        if (batteryInfo) {
            if (valueType == 0) {
                // Watts
                long long watts = [batteryInfo[@"AdapterDetails"][@"Watts"] longLongValue];

                if (watts) {
                    result = [NSString stringWithFormat:@"%lld W", watts];
                } else {
                    result = @"0 W";
                }
            } else if (valueType == 1) {
                // Charging Current
                double current = [batteryInfo[@"AdapterDetails"][@"Current"] doubleValue];

                if (current) {
                    result = [NSString stringWithFormat:@"%.0f mA", current];
                } else {
                    result = @"0 mA";
                }
            } else if (valueType == 2) {
                // Regular Amperage
                double amps = [batteryInfo[@"Amperage"] doubleValue];

                if (amps) {
                    result = [NSString stringWithFormat:@"%.0f mA", amps];
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
- (void)formattedCurrentCapacity:(BOOL)showPercentage callback:(CallbackBlock)callback {
    @autoreleasepool {
        NSString *result = @"??%";
        NSDictionary *batteryInfo = [self getBatteryInfo];

        if (batteryInfo) {
            result = [
                NSString stringWithFormat:@"%@%@",
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
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];

    if ([[UIDevice currentDevice] batteryState] != UIDeviceBatteryStateUnplugged) {
        if (filled) {
            return @"bolt.fill";
        } else {
            return @"bolt";
        }
    }

    return @"";
}

- (void)formattedChargingSymbolImage:(BOOL)filled fontSize:(double)fontSize textColor:(UIColor *)textColor callback:(CallbackBlock)callback {
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
- (NSMutableAttributedString *)replaceWeatherImage:(NSString *)formattedText replacement:(NSAttributedString *)replacement {
    @autoreleasepool {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{([^}]+)\\}" options:NSRegularExpressionAnchorsMatchLines error:nil];
        NSArray *matches = [regex matchesInString:formattedText options:kNilOptions range:NSMakeRange(0, formattedText.length)];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:formattedText];

        for (NSTextCheckingResult *result in [matches reverseObjectEnumerator]) {
            NSString *match = [formattedText substringWithRange:result.range];

            if ([match isEqual:@"{i}"]) {
                [attributedString replaceCharactersInRange:result.range withAttributedString:replacement];
            }
        }

        return [attributedString copy];
    }
}

- (NSAttributedString *)formattedWeatherData:(NSDictionary *)weatherData format:(NSString *)format textColor:(UIColor *)textColor {
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
                                                                       replacement:[NSAttributedString attributedStringWithAttachment:imageAttachment]
                 ]];
            } else {
                [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:format]];
            }
        }

        return [attributedString copy];
    }
}

- (void)formattedWeatherString:(NSString *)location format:(NSString *)format useCurrentLocation:(BOOL)useCurrentLocation useMetric:(BOOL)useMetric useFahrenheit:(BOOL)useFahrenheit locale:(NSString *)locale fontSize:(double)fontSize textColor:(UIColor *)textColor weatherProvider:(NSInteger)weatherProvider weatherApiKey:(NSString *)weatherApiKey freeSub:(BOOL)freeSub callback:(CallbackBlock)callback {
    @autoreleasepool {
        format = [self processWidgetString:format];

        if (weatherProvider == 0) {
            TWCWeather *twcWeather = [TWCWeather sharedInstance];
            twcWeather.locale = [[NSLocale alloc] initWithLocaleIdentifier:locale];
            twcWeather.useFahrenheit = useFahrenheit;
            twcWeather.useMetric = useMetric;
            twcWeather.fontSize = fontSize;
            [twcWeather updateModel:^(NSDictionary *weatherData) {
                if (weatherData != nil) {
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self formattedWeatherData:weatherData
                                                                                                                                                  format:format
                                                                                                                                               textColor:textColor]];
                    attributedString = [self formatString:attributedString];
                    callback([attributedString copy]);
                } else {
                    callback(nil);
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
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self formattedWeatherData:weatherData
                                                                                                                                                  format:format
                                                                                                                                               textColor:textColor]];
                    attributedString = [self formatString:attributedString];
                    callback([attributedString copy]);
                } else {
                    callback(nil);
                }
            }];
        } else if (weatherProvider == 2) {
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
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self formattedWeatherData:weatherData
                                                                                                                                                  format:format
                                                                                                                                               textColor:textColor]];
                    attributedString = [self formatString:attributedString];
                    callback([attributedString copy]);
                } else {
                    callback(nil);
                }
            }];
        } else if (weatherProvider == 3) {
            OpenWeatherMap *openWeatherMap = [OpenWeatherMap sharedInstance];
            openWeatherMap.useMetric = useMetric;
            openWeatherMap.useFahrenheit = useFahrenheit;
            openWeatherMap.apiKey = weatherApiKey;
            openWeatherMap.locale = locale;
            openWeatherMap.fontSize = fontSize;
            openWeatherMap.useCurrentLocation = useCurrentLocation;
            openWeatherMap.location = location;
            [openWeatherMap updateWeather:^(NSDictionary *weatherData) {
                if (weatherData != nil) {
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self formattedWeatherData:weatherData
                                                                                                                                                  format:format
                                                                                                                                               textColor:textColor]];
                    attributedString = [self formatString:attributedString];
                    callback([attributedString copy]);
                } else {
                    callback(nil);
                }
            }];
        } else {
            callback(nil);
        }
    }
}

#pragma mark - Lyrics Widget
- (void)formattedLyricsString:(NSInteger)unsupported unLyricsType:(NSInteger)unLyricsType unBluetoothType:(NSInteger)unBluetoothType unWiredType:(NSInteger)unWiredType supported:(NSInteger)supported lyricsType:(NSInteger)lyricsType bluetoothType:(NSInteger)bluetoothType wiredType:(NSInteger)wiredType callback:(CallbackBlock)callback {
    @autoreleasepool {
        MediaRemoteManager *manager = [MediaRemoteManager sharedManager];
        [manager getNowPlayingApplicationIsPlayingWithCompletion:^(BOOL isPlaying) {
            if (isPlaying) {
                [manager getBundleIdentifierWithCompletion:^(NSString *bundleIdentifier) {
                    NSString *lyricsKey = [MusicPlayerUtils getLyricsKeyByBundleIdentifier:bundleIdentifier
                                                                                lyricsType:lyricsType
                                                                             bluetoothType:bluetoothType
                                                                                 wiredType:wiredType
                                                                               unsupported:false
                                                                              autoDetected:supported == 0];

                    NSString *unLyricsKey = [MusicPlayerUtils getLyricsKeyByBundleIdentifier:bundleIdentifier
                                                                                  lyricsType:unLyricsType
                                                                               bluetoothType:unBluetoothType
                                                                                   wiredType:unWiredType
                                                                                 unsupported:true
                                                                                autoDetected:false];

                    [manager getNowPlayingInfoWithCompletion:^(NSDictionary *info) {
                        NSString *currentLyric = nil;

                        if (info) {
                            if (supported == 2 || (lyricsKey == nil && unsupported == 2)) {
                                NSString *title = info[@"kMRMediaRemoteNowPlayingInfoTitle"];
                                NSString *artist = info[@"kMRMediaRemoteNowPlayingInfoArtist"];
                                NSString *album = info[@"kMRMediaRemoteNowPlayingInfoAlbum"];
                                double duration = [(info[@"kMRMediaRemoteNowPlayingInfoDuration"] ? : @"0") doubleValue];

                                CFAbsoluteTime timeStarted = CFDateGetAbsoluteTime((CFDateRef)info[@"kMRMediaRemoteNowPlayingInfoTimestamp"]);
                                double lastStoredTime = [info[@"kMRMediaRemoteNowPlayingInfoElapsedTime"] doubleValue];
                                double realTimeElapsed = (CFAbsoluteTimeGetCurrent() - timeStarted) + (lastStoredTime > 1 ? lastStoredTime : 0);

                                LyricsUtils *lyricsUtils = [LyricsUtils sharedInstance];
                                lyricsUtils.title = title;
                                lyricsUtils.artist = artist;
                                lyricsUtils.album = album;
                                lyricsUtils.duration = duration;

                                [lyricsUtils getLyric];

                                currentLyric = [lyricsUtils getLyricByTime:realTimeElapsed];
                                // HMLog(currentLyric);
                            } else {
                                if (unsupported == 1) {
                                    currentLyric = info[unLyricsKey];
                                } else {
                                    currentLyric = info[lyricsKey];
                                }
                            }
                        }

                        if (currentLyric) {
                            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", currentLyric]];
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

#pragma mark - CPU MEM Widget
- (double)applicationCPU {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;

    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);

    if (kr != KERN_SUCCESS) {
        return 0;
    }

    // task_basic_info_t      basic_info;
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;

    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;

    thread_basic_info_t basic_info_th;
    // uint32_t stat_thread = 0; // Mach threads

    // basic_info = (task_basic_info_t)tinfo;

    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);

    if (kr != KERN_SUCCESS) {
        return 0;
    }

    // if (thread_count > 0)
    //     stat_thread += thread_count;

    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;

    for (j = 0; j < (int)thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);

        if (kr != KERN_SUCCESS) {
            return 0;
        }

        basic_info_th = (thread_basic_info_t)thinfo;

        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
    } // for each thread

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);

    return tot_cpu;
}

- (double)applicationMemory {
    struct mach_task_basic_info info;
    mach_msg_type_number_t count = sizeof(info) / sizeof(integer_t);

    if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &count) == KERN_SUCCESS) {
        return info.resident_size / NBYTE_PER_MB;
    }

    return 0;
}

- (double)systemCPU {
    kern_return_t kr;
    mach_msg_type_number_t count;
    static host_cpu_load_info_data_t previous_info = {
        0, 0, 0, 0
    };
    host_cpu_load_info_data_t info;

    count = HOST_CPU_LOAD_INFO_COUNT;

    kr = host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&info, &count);

    if (kr != KERN_SUCCESS) {
        return 0;
    }

    natural_t user = info.cpu_ticks[CPU_STATE_USER] - previous_info.cpu_ticks[CPU_STATE_USER];
    natural_t nice = info.cpu_ticks[CPU_STATE_NICE] - previous_info.cpu_ticks[CPU_STATE_NICE];
    natural_t system = info.cpu_ticks[CPU_STATE_SYSTEM] - previous_info.cpu_ticks[CPU_STATE_SYSTEM];
    natural_t idle = info.cpu_ticks[CPU_STATE_IDLE] - previous_info.cpu_ticks[CPU_STATE_IDLE];
    natural_t total = user + nice + system + idle;
    previous_info = info;

    return (user + nice + system) * 100.0 / total;
}

- (double)systemMemoryUsage {
    vm_statistics64_data_t vmstat;
    natural_t size = HOST_VM_INFO64_COUNT;

    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vmstat, &size) == KERN_SUCCESS) {
        double free = vmstat.free_count * PAGE_SIZE / NBYTE_PER_MB;
        // double wired = vmstat.wire_count * PAGE_SIZE / NBYTE_PER_MB;
        // double active = vmstat.active_count * PAGE_SIZE / NBYTE_PER_MB;
        double inactive = vmstat.inactive_count * PAGE_SIZE / NBYTE_PER_MB;
        // double compressed = vmstat.compressor_page_count * PAGE_SIZE / NBYTE_PER_MB;
        // double total = [NSProcessInfo processInfo].physicalMemory / NBYTE_PER_MB;

        return free + inactive;
    }

    return 0;
}

- (double)systemMemoryTotal {
    return [NSProcessInfo processInfo].physicalMemory / NBYTE_PER_MB;
}

- (void)formattedCPUMEM:(NSInteger)type callback:(CallbackBlock)callback {
    @autoreleasepool {
        NSString *result = nil;

        if (type == 0) { //System CPU Usage
            result = [NSString stringWithFormat:@"%.0f%%", [self systemCPU]];
        } else if (type == 1) { // System Memory Total
            result = [NSString stringWithFormat:@"%.0fMB", [self systemMemoryTotal]];
        } else if (type == 2) { // System Memory Usage
            result = [NSString stringWithFormat:@"%.0fMB", [self systemMemoryUsage]];
        } else if (type == 3) { // Application CPU Usage
            result = [NSString stringWithFormat:@"%.0f%%", [self applicationCPU]];
        } else if (type == 4) { // Application Memory Usage
            result = [NSString stringWithFormat:@"%.0fMB", [self applicationMemory]];
        } else {
            result = @"??";
        }

        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:result];
        attributedString = [self formatString:attributedString];
        callback([attributedString copy]);
    }
}

#pragma mark - Crypto Coin Widget
- (void)formattedCryptoCoin:(NSString *)coinIDs callback:(CallbackBlock)callback {
    @autoreleasepool {
        NSMutableArray *array = [[NSMutableArray alloc] init];

        NSDictionary *data = [CryptoCoinUtils getMarkPriceByIDs:coinIDs];
        HMLog(data);

        if (data) {
            for (NSDictionary *da in data) {
                NSString *temp = [NSString stringWithFormat:@"%@:%@", da[@"symbol"], [self removeExtraZerosFromDouble:[da[@"price"] doubleValue]]];
                [array addObject:temp];
                HMLog(temp);
            }
        }

        if ([array count] > 0) {
            HMLog(array);
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[array componentsJoinedByString:@"\n"]];
            attributedString = [self formatString:attributedString];
            callback([attributedString copy]);
        } else {
            callback(nil);
        }
    }
}

#pragma mark - Other Functions
- (NSAttributedString *)emptyAtributedWhitespace {
    // You can put any random string there or how many spaces you want
    return [[NSAttributedString alloc] initWithString:@"." attributes:@{ NSForegroundColorAttributeName: [UIColor clearColor] }];
}

- (NSMutableAttributedString *)formatString:(NSMutableAttributedString *)attributedString {
    NSString *text = attributedString.string;
    NSInteger length = text.length;

    if (length > 0 && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[text characterAtIndex:length - 1]]) {
        [attributedString replaceCharactersInRange:NSMakeRange(length - 1, 1) withAttributedString:[self emptyAtributedWhitespace]];
    }

    return attributedString;
}

- (NSString *)processWidgetString:(NSString *)widgetString {
    NSString *processedString = [widgetString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];

    processedString = [processedString stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
    return processedString;
}

- (NSString *)removeExtraZerosFromDouble:(double)value {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];

    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMinimumFractionDigits:0];
    [formatter setMaximumFractionDigits:16];
    [formatter setUsesGroupingSeparator:NO];
    return [formatter stringFromNumber:@(value)];
}

@end
