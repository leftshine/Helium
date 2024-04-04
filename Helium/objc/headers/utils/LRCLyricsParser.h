//
//  LRCLyricsParser.h
//  Helium
//
//  Created by Fuuko on 2024/3/28.
//

#ifndef LRCLyricsParser_h
#define LRCLyricsParser_h
#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

@interface LRCLyricsParser : NSObject
@property (nonatomic, strong) NSDictionary *lyricsDictionary;
@property (nonatomic, strong) NSArray *sortedTimestamps;

+ (instancetype)sharedParser;

- (void)parseLRCString:(NSString *)lrcString;
- (NSString *)currentLyricForTime:(NSTimeInterval)currentTime;
- (void)cleanLyrics;
@end

//NS_ASSUME_NONNULL_END

#endif /* LRCLyricsParser_h */
