#import "LRCLyricsParser.h"

@implementation LRCLyricsParser

+ (instancetype)sharedParser {
    static LRCLyricsParser *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
    }

    return self;
}

- (void)parseLRCString:(NSString *)lrcString {
    NSMutableDictionary *parsedLyricsDictionary = [NSMutableDictionary dictionary];
    NSMutableArray *timestamps = [NSMutableArray array];
    NSInteger timeOffset = 0; // Initialize time offset

    @try {
        NSArray *lines = [lrcString componentsSeparatedByString:@"\n"];

        for (NSString *line in lines) {
            if (![line hasPrefix:@"["]) {
                continue; // Skip lines that don't start with '['
            }

            // Check if the line starts with a numeric character
            if (![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[line characterAtIndex:1]]) {
                if ([line hasPrefix:@"[offset"]) {
                    // Extract offset value
                    NSRange offsetRangeStart = [line rangeOfString:@"["];
                    NSRange offsetRangeEnd = [line rangeOfString:@"]"];

                    if (offsetRangeStart.location != NSNotFound && offsetRangeEnd.location != NSNotFound) {
                        NSString *offsetString = [line substringWithRange:NSMakeRange(offsetRangeStart.location + 1, offsetRangeEnd.location - offsetRangeStart.location - 1)];
                        timeOffset = [offsetString integerValue];
                    }
                }

                continue;
            }

            NSRange timeRangeStart = [line rangeOfString:@"["];
            NSRange timeRangeEnd = [line rangeOfString:@"]"];

            if (timeRangeStart.location != NSNotFound && timeRangeEnd.location != NSNotFound) {
                NSString *timeString = [line substringWithRange:NSMakeRange(timeRangeStart.location + 1, timeRangeEnd.location - timeRangeStart.location - 1)];
                NSArray *timeComponents = [timeString componentsSeparatedByString:@":"];

                if (timeComponents.count == 2) {
                    NSString *minutesString = timeComponents[0];
                    NSString *secondsAndMillisecondsString = timeComponents[1];

                    NSInteger minutes = [minutesString integerValue];

                    NSArray *secondsAndMillisecondsComponents = [secondsAndMillisecondsString componentsSeparatedByString:@"."];
                    NSInteger seconds = [secondsAndMillisecondsComponents[0] integerValue];
                    NSInteger milliseconds = [secondsAndMillisecondsComponents[1] integerValue];

                    NSTimeInterval timestamp = minutes * 60 + seconds + milliseconds / 1000.0 + timeOffset;

                    NSString *lyric = [line substringFromIndex:timeRangeEnd.location + 1];
                    lyric = [lyric stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    [parsedLyricsDictionary setObject:lyric forKey:@(timestamp)];
                    [timestamps addObject:@(timestamp)];
                }
            }
        }

        // Sort timestamps in ascending order
        NSArray *sortedTimestampsArray = [timestamps sortedArrayUsingSelector:@selector(compare:)];

        // Store sorted timestamps and parsed lyrics
        self.sortedTimestamps = sortedTimestampsArray;
        self.lyricsDictionary = [NSDictionary dictionaryWithDictionary:parsedLyricsDictionary];
    } @catch (NSException *exception) {
        HMLog(exception);
    }
}

- (NSString *)currentLyricForTime:(NSTimeInterval)currentTime {
    NSString *currentLyric = nil;

    @try {
        if (self.lyricsDictionary && self.sortedTimestamps) {
            // Find the nearest timestamp that is less than or equal to the current time
            NSNumber *nearestTimestamp = nil;

            for (NSNumber *timestamp in self.sortedTimestamps) {
                if ([timestamp doubleValue] <= currentTime) {
                    nearestTimestamp = timestamp;
                } else {
                    break;
                }
            }

            if (nearestTimestamp) {
                currentLyric = [self.lyricsDictionary objectForKey:nearestTimestamp];
            }
        }
    } @catch (NSException *exception) {
        HMLog(exception);
    }

    return currentLyric;
}

- (void)cleanLyrics {
    if (self.lyricsDictionary) {
        self.lyricsDictionary = nil;
    }

    if (self.sortedTimestamps) {
        self.sortedTimestamps = nil;
    }
}

@end
