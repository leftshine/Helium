#import <Foundation/Foundation.h>

@interface LRCLyricsParser : NSObject
@property (nonatomic, strong) NSDictionary *lyricsDictionary;
@property (nonatomic, strong) NSArray *sortedTimestamps;

+ (instancetype)sharedParser;

- (void)parseLRCString:(NSString *)lrcString;
- (NSString *)currentLyricForTime:(NSTimeInterval)currentTime;
- (void)cleanLyrics;
@end
