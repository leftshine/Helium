//
//  LyricsUtils.h
//  Helium
//
//  Created by Fuuko on 2024/3/28.
//

#ifndef LyricsUtils_h
#define LyricsUtils_h
#import <Foundation/Foundation.h>
@class LRCLyricsParser;

//NS_ASSUME_NONNULL_BEGIN

typedef void (^DataCompletionHandler)(NSString *data, NSError *error);
typedef void (^LyricCompletionHandler)(NSArray *lyrics, NSError *error);

@interface LyricsUtils : NSObject
@property (nonatomic, strong) LRCLyricsParser *parser;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *album;
@property (nonatomic) double duration;
@property (nonatomic, strong) NSString *lastTitle;
@property (nonatomic, strong) NSString *lastArtist;
@property (nonatomic) NSInteger noLyric;
@property (nonatomic) BOOL gettingLyric;
@property (nonatomic, strong) NSURLSessionDataTask *currentTask;

+ (instancetype)sharedInstance;

- (void)getLyric;
- (NSString *)getLyricByTime:(double)time;
@end

//NS_ASSUME_NONNULL_END

#endif /* LyricsUtils_h */