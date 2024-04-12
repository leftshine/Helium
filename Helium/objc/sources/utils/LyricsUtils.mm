#import "LRCLyricsParser.h"
#import "LyricsUtils.h"

static NSString *UserAgent = @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5";

@implementation LyricsUtils

+ (instancetype)sharedInstance {
    static LyricsUtils *_shared = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });
    return _shared;
}

- (instancetype)init {
    self = [super init];

    if (self != nil) {
        self.noLyric = -1;
        self.gettingLyric = false;
    }

    return self;
}

- (void)getLyric {
    if (self.title != nil && ![self.title isEqualToString:self.lastTitle]) {
        HMLog(@"切换歌曲");
        self.gettingLyric = false;
        self.noLyric = -1;
        self.lastTitle = self.title;
        self.lastArtist = self.artist;
    }

    if (self.gettingLyric == false && self.noLyric == -1) {
        self.parser = [LRCLyricsParser sharedParser];
        [self.parser cleanLyrics];
        [self.parser parseLRCString:NSLocalizedString(@"get_lyrics", comment: @"")];

        self.gettingLyric = true;
        [self getKugouLyricByName:[self trimTitle:self.title]
                           artist:[self trimArtist:self.artist]
                            album:self.album
                       completion:^(NSString *lyric, NSError *error) {
            HMLog(lyric);

            if (error) {
                HMLog(error);
                [self fallbackNetease];
                return;
            }

            if ([lyric length] > 0) {
                self.parser = [LRCLyricsParser sharedParser];
                [self.parser cleanLyrics];
                [self.parser parseLRCString:lyric];
                self.gettingLyric = false;
                self.noLyric = 0;
            } else {
                [self fallbackNetease];
            }
        }];
    } else {
        if (self.noLyric == 1) {
            self.parser = [LRCLyricsParser sharedParser];
            [self.parser cleanLyrics];
            [self.parser parseLRCString:NSLocalizedString(@"no_lyrics", comment: @"")];
        }
    }
}

- (void)fallbackNetease {
    [self getNetEaseLyricByName:[self trimTitle:self.title]
                         artist:[self trimArtist:self.artist]
                          album:self.album
                     completion:^(NSString *lyric, NSError *error) {
        HMLog(lyric);

        if (error) {
            HMLog(error);
            // [self fallbackKugou];
            self.noLyric = 1;
            self.gettingLyric = false;
            return;
        }

        if ([lyric length] > 0) {
            self.parser = [LRCLyricsParser sharedParser];
            [self.parser cleanLyrics];
            [self.parser parseLRCString:lyric];
            self.gettingLyric = false;
            self.noLyric = 0;
        } else {
            [self fallbackKugou];
        }
    }];
}

- (void)fallbackKugou {
    [self getKugouLyricByName:[self RomajiToHiragana:[self trimTitle:self.title]]
                       artist:[self RomajiToHiragana:[self trimArtist:self.artist]]
                        album:[self RomajiToHiragana:self.album]
                   completion:^(NSString *lyric, NSError *error) {
        HMLog(lyric);

        if (error) {
            HMLog(error);
            [self fallbackNetease2];
            return;
        }

        if ([lyric length] > 0) {
            self.parser = [LRCLyricsParser sharedParser];
            [self.parser cleanLyrics];
            [self.parser parseLRCString:lyric];
            self.gettingLyric = false;
            self.noLyric = 0;
        } else {
            self.gettingLyric = false;
            self.noLyric = 1;
            // [self fallbackNetease2];
        }
    }];
}

- (void)fallbackNetease2 {
    [self getNetEaseLyricByName:[self RomajiToHiragana:[self trimTitle:self.title]]
                         artist:[self RomajiToHiragana:[self trimArtist:self.artist]]
                          album:[self RomajiToHiragana:self.album]
                     completion:^(NSString *lyric, NSError *error) {
        HMLog(lyric);

        if (error) {
            HMLog(error);
            self.noLyric = 1;
            self.gettingLyric = false;
            return;
        }

        if ([lyric length] > 0) {
            self.parser = [LRCLyricsParser sharedParser];
            [self.parser cleanLyrics];
            [self.parser parseLRCString:lyric];
            self.gettingLyric = false;
            self.noLyric = 0;
        } else {
            self.gettingLyric = false;
            self.noLyric = 1;
        }
    }];
}

- (NSString *)getLyricByTime:(double)time {
    if (self.parser != nil) {
        return [self.parser currentLyricForTime:time];
    } else {
        return nil;
    }
}

#pragma mark - NetEase
- (void)getSongIDForSong:(NSString *)title artist:(NSString *)artist album:(NSString *)album completion:(void (^)(NSNumber *songID, NSError *error))completion {
    NSString *postString = [NSString stringWithFormat:@"s=%@&offset=0&limit=10&type=1", [NSString stringWithFormat:@"%@ %@", title, artist]];

    [self postDataToURL:@"http://music.163.com/api/search/pc"
             postString:postString
             completion:^(NSString *data, NSError *error) {
        HMLog(data);

        if (error) {
            completion(nil, error);
            return;
        }

        NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                     options:0
                                                                       error:nil];

        NSDictionary *result = jsonResponse[@"result"];
        NSArray *songs = result[@"songs"];

        if (songs.count > 0) {
            // Calculate song match ratio and find the most relevant song
            float maxRatio = 0.2;
            NSDictionary *selectedSong;

            for (NSDictionary *songItem in songs) {
                HMLog(songItem);
                NSString *songName = songItem[@"name"];
                NSString *singerName = songItem[@"artists"][0][@"name"] ? : @"";
                NSString *albumName = songItem[@"album"][@"name"] ? : @"";
                HMLog(songName, title, singerName, artist, albumName, album, [self RomajiToHiragana:title], [self RomajiToHiragana:artist]);
                HMLog([self TCToSC:songName], [self TCToSC:title], [self TCToSC:singerName], [self TCToSC:artist], [self TCToSC:albumName], [self TCToSC:album]);
                HMLog([self KanjoToRomaji:songName], [self KanjoToRomaji:title], [self KanjoToRomaji:singerName], [self KanjoToRomaji:artist], [self KanjoToRomaji:albumName], [self KanjoToRomaji:album]);

                float titleConformRatio = MAX(MAX([self calculateSimilarityBetweenText:title
                                                                               andText:songName],
                                                  [self calculateSimilarityBetweenText:[self TCToSC:title]
                                                                               andText:[self TCToSC:songName]]),
                                              [self calculateSimilarityBetweenText:[self KanjoToRomaji:title]
                                                                           andText:[self KanjoToRomaji:songName]]);
                float artistConformRatio = MAX(MAX([self calculateSimilarityBetweenText:artist
                                                                                andText:singerName],
                                                   [self calculateSimilarityBetweenText:[self TCToSC:artist]
                                                                                andText:[self TCToSC:singerName]]),
                                               [self calculateSimilarityBetweenText:[self KanjoToRomaji:artist]
                                                                            andText:[self KanjoToRomaji:singerName]]);
                float albumConformRatio = MAX(MAX([self calculateSimilarityBetweenText:album
                                                                               andText:albumName],
                                                  [self calculateSimilarityBetweenText:[self TCToSC:album]
                                                                               andText:[self TCToSC:albumName]]),
                                              [self calculateSimilarityBetweenText:[self KanjoToRomaji:album]
                                                                           andText:[self KanjoToRomaji:albumName]]);
                HMLog(titleConformRatio, artistConformRatio, albumConformRatio);

                float ratio = sqrtf(titleConformRatio * artistConformRatio);

                if (titleConformRatio > 0.8 && artistConformRatio == 0) {
                    ratio = albumConformRatio;
                }

                HMLog(ratio);

                if (ratio > maxRatio) {
                    maxRatio = ratio;
                    selectedSong = songItem;
                }
            }

            HMLog(maxRatio, selectedSong);

            if (!selectedSong) {
                completion(nil, nil); // No song found with matching ratio
                return;
            }

            NSNumber *songID = selectedSong[@"id"];
            completion(songID, nil);
        } else {
            NSError *notFoundError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                         code:404
                                                     userInfo:@{ NSLocalizedDescriptionKey: @"No lyrics content found" }];
            completion(nil, notFoundError);
        }
    }];
}

- (void)downloadLyricForSongID:(NSNumber *)songID completion:(DataCompletionHandler)completionHandler {
    NSString *lyricURLString = [NSString stringWithFormat:@"https://music.163.com/api/song/lyric?lv=-1&id=%@", songID];

    [self getDataFrom:lyricURLString
           completion:^(NSString *data, NSError *error) {
        if (error) {
            completionHandler(nil, error);
        } else {
            completionHandler(data, nil);
        }
    }];
}

- (void)getNetEaseLyricByName:(NSString *)title artist:(NSString *)artist album:(NSString *)album completion:(void (^)(NSString *lyric, NSError *error))completion {
    [self getSongIDForSong:title
                    artist:artist
                     album:album
                completion:^(NSNumber *songID, NSError *error) {
        if (error) {
            completion(nil, error);
        } else {
            [self downloadLyricForSongID:songID
                              completion:^(NSString *responseData, NSError *error) {
                if (error) {
                    completion(nil, error);
                } else {
                    NSData *data = [responseData dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *jsonError;
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:0
                                                                               error:&jsonError];
                    HMLog(jsonDict);

                    if (jsonError) {
                        HMLog(jsonError.localizedDescription);
                        completion(nil, jsonError);
                        return;
                    }

                    completion(jsonDict[@"lrc"][@"lyric"], nil);
                }
            }];
        }
    }];
}

#pragma mark - Kugou
- (void)getHashForSong:(NSString *)title artist:(NSString *)artist album:(NSString *)album completion:(void (^)(NSString *songHash, NSError *error))completion {
    NSString *url = [NSString stringWithFormat:@"https://songsearch.kugou.com/song_search_v2?keyword=%@&page=1&pagesize=10&userid=0&clientver=&platform=WebFilter&filter=2&iscorrection=1&privilege_filter=0&area_code=1", [self encodeURIComponent:[NSString stringWithFormat:@"%@ %@", title, artist]]];

    [self getDataFrom:url
           completion:^(NSString *data, NSError *error) {
        HMLog(data);

        if (error) {
            completion(nil, error);
            return;
        }

        NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                     options:0
                                                                       error:nil];

        NSDictionary *result = jsonResponse[@"data"];
        NSArray *songs = result[@"lists"];

        if (songs.count > 0) {
            // Calculate song match ratio and find the most relevant song
            float maxRatio = 0.2;
            NSDictionary *selectedSong;

            for (NSDictionary *songItem in songs) {
                HMLog(songItem);
                NSString *songName = songItem[@"SongName"];
                NSString *singerName = songItem[@"SingerName"] ? : @"";
                NSString *albumName = songItem[@"AlbumName"] ? : @"";
                HMLog(songName, title, singerName, artist, albumName, album, [self RomajiToHiragana:title], [self RomajiToHiragana:artist]);
                HMLog([self TCToSC:songName], [self TCToSC:title], [self TCToSC:singerName], [self TCToSC:artist], [self TCToSC:albumName], [self TCToSC:album]);
                HMLog([self KanjoToRomaji:songName], [self KanjoToRomaji:title], [self KanjoToRomaji:singerName], [self KanjoToRomaji:artist], [self KanjoToRomaji:albumName], [self KanjoToRomaji:album]);

                float titleConformRatio = MAX(MAX([self calculateSimilarityBetweenText:title
                                                                               andText:songName],
                                                  [self calculateSimilarityBetweenText:[self TCToSC:title]
                                                                               andText:[self TCToSC:songName]]),
                                              [self calculateSimilarityBetweenText:[self KanjoToRomaji:title]
                                                                           andText:[self KanjoToRomaji:songName]]);
                float artistConformRatio = MAX(MAX([self calculateSimilarityBetweenText:artist
                                                                                andText:singerName],
                                                   [self calculateSimilarityBetweenText:[self TCToSC:artist]
                                                                                andText:[self TCToSC:singerName]]),
                                               [self calculateSimilarityBetweenText:[self KanjoToRomaji:artist]
                                                                            andText:[self KanjoToRomaji:singerName]]);
                float albumConformRatio = MAX(MAX([self calculateSimilarityBetweenText:album
                                                                               andText:albumName],
                                                  [self calculateSimilarityBetweenText:[self TCToSC:album]
                                                                               andText:[self TCToSC:albumName]]),
                                              [self calculateSimilarityBetweenText:[self KanjoToRomaji:album]
                                                                           andText:[self KanjoToRomaji:albumName]]);
                HMLog(titleConformRatio, artistConformRatio, albumConformRatio);

                float ratio = sqrtf(titleConformRatio * artistConformRatio);

                if (titleConformRatio == 1 && artistConformRatio == 0) {
                    ratio = albumConformRatio;
                }

                HMLog(ratio);

                if (ratio > maxRatio) {
                    maxRatio = ratio;
                    selectedSong = songItem;
                }
            }

            HMLog(maxRatio, selectedSong);

            if (!selectedSong) {
                completion(nil, nil); // No song found with matching ratio
                return;
            }

            NSString *songHash = selectedSong[@"FileHash"];
            completion(songHash, nil);
        } else {
            NSError *notFoundError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                         code:404
                                                     userInfo:@{ NSLocalizedDescriptionKey: @"No lyrics content found" }];
            completion(nil, notFoundError);
        }
    }];
}

- (void)getSongByHash:(NSString *)hash completion:(void (^)(NSString *lyrics, NSError *error))completionHandler {
    NSString *url = [NSString stringWithFormat:@"http://lyrics.kugou.com/search?ver=1&man=yes&client=pc&hash=%@", hash];

    [self getDataFrom:url
           completion:^(NSString *responseData, NSError *error) {
        HMLog(responseData);

        if (error) {
            completionHandler(nil, error);
            return;
        }

        NSError *jsonError = nil;
        id responseBody = [NSJSONSerialization JSONObjectWithData:[responseData dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:NSJSONReadingMutableContainers
                                                            error:&jsonError];

        if (jsonError || !responseBody) {
            NSError *parsingError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                        code:NSPropertyListReadCorruptError
                                                    userInfo:@{ NSLocalizedDescriptionKey: @"Error parsing JSON" }];
            completionHandler(nil, parsingError);
            return;
        }

        NSInteger status = [[responseBody objectForKey:@"status"] integerValue];

        if (status != 200) {
            NSError *statusError = [NSError errorWithDomain:NSURLErrorDomain
                                                       code:status
                                                   userInfo:nil];
            completionHandler(nil, statusError);
            return;
        }

        NSArray *searchList = [responseBody objectForKey:@"candidates"];

        if (searchList.count <= 0) {
            NSError *noResultError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                         code:NSURLErrorNoPermissionsToReadFile
                                                     userInfo:@{ NSLocalizedDescriptionKey: @"No search results found" }];
            completionHandler(nil, noResultError);
            return;
        }

        NSDictionary *bestDict = [searchList firstObject];

        NSString *ID = [bestDict objectForKey:@"id"];
        NSString *accesskey = [bestDict objectForKey:@"accesskey"];

        [self getLyricsByID:ID
                  accesskey:accesskey
                 completion:completionHandler];
    }];
}

- (void)getLyricsByID:(NSString *)ID accesskey:(NSString *)accesskey completion:(void (^)(NSString *lyrics, NSError *error))completionHandler {
    NSString *url = [NSString stringWithFormat:@"http://lyrics.kugou.com/download?ver=1&client=pc&id=%@&accesskey=%@&fmt=lrc&charset=utf8", ID, accesskey];

    [self getDataFrom:url
           completion:^(NSString *responseData, NSError *error) {
        if (error) {
            completionHandler(nil, error);
            return;
        }

        NSError *jsonError = nil;
        id responseBody = [NSJSONSerialization JSONObjectWithData:[responseData dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:NSJSONReadingMutableContainers
                                                            error:&jsonError];

        if (jsonError || !responseBody) {
            NSError *parsingError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                        code:NSPropertyListReadCorruptError
                                                    userInfo:@{ NSLocalizedDescriptionKey: @"Error parsing JSON" }];
            completionHandler(nil, parsingError);
            return;
        }

        NSInteger status = [[responseBody objectForKey:@"status"] integerValue];

        if (status != 200) {
            NSError *statusError = [NSError errorWithDomain:NSURLErrorDomain
                                                       code:status
                                                   userInfo:nil];
            completionHandler(nil, statusError);
            return;
        }

        NSString *lrcContent = [responseBody objectForKey:@"content"];

        if (lrcContent.length <= 0) {
            NSError *noContentError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                          code:NSURLErrorResourceUnavailable
                                                      userInfo:@{ NSLocalizedDescriptionKey: @"No lyrics content found" }];
            completionHandler(nil, noContentError);
            return;
        }

        NSData *lyricsData = [[NSData alloc] initWithBase64EncodedString:lrcContent
                                                                 options:0];
        NSString *lyrics = [[NSString alloc] initWithData:lyricsData
                                                 encoding:NSUTF8StringEncoding];

        if (!lyrics) {
            NSError *decodingError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                         code:NSFileReadInapplicableStringEncodingError
                                                     userInfo:@{ NSLocalizedDescriptionKey: @"Error decoding lyrics content" }];
            completionHandler(nil, decodingError);
            return;
        }

        completionHandler(lyrics, nil);
    }];
}

- (void)getKugouLyricByName:(NSString *)title artist:(NSString *)artist album:(NSString *)album completion:(void (^)(NSString *lyric, NSError *error))completion {
    [self getHashForSong:title
                  artist:artist
                   album:album
              completion:^(NSString *songHash, NSError *error) {
        if (error) {
            completion(nil, error);
        } else {
            [self getSongByHash:songHash
                     completion:^(NSString *responseData, NSError *error) {
                if (error) {
                    completion(nil, error);
                } else {
                    completion(responseData, nil);
                }
            }];
        }
    }];
}

#pragma mark - Other Functions
- (void)getDataFrom:(NSString *)urlString completion:(DataCompletionHandler)completionHandler {
    HMLog(urlString);

    // Cancel previous task
    [self.currentTask cancel];

    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:UserAgent forHTTPHeaderField:@"User-Agent"];

    NSURLSession *session = [NSURLSession sharedSession];

    self.currentTask = [session dataTaskWithRequest:request
                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            HMLog(error.localizedDescription);
            completionHandler(nil, error);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if ([httpResponse statusCode] != 200) {
            HMLog(@"Error getting %@, HTTP status code %li", urlString, (long)[httpResponse statusCode]);
            NSError *statusError = [NSError errorWithDomain:NSURLErrorDomain
                                                       code:[httpResponse statusCode]
                                                   userInfo:nil];
            completionHandler(nil, statusError);
            return;
        }

        NSString *responseData = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        completionHandler(responseData, nil);
    }];

    [self.currentTask resume];
}

- (void)postDataToURL:(NSString *)urlString postString:(NSString *)postString completion:(DataCompletionHandler)completionHandler {
    HMLog(urlString);
    [self.currentTask cancel];

    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    // 设置请求头
    [request setValue:UserAgent forHTTPHeaderField:@"User-Agent"];

    NSURLSession *session = [NSURLSession sharedSession];

    self.currentTask = [session dataTaskWithRequest:request
                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            HMLog(error.localizedDescription);
            completionHandler(nil, error);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if ([httpResponse statusCode] != 200) {
            HMLog(@"Error posting data to %@, HTTP status code %li", urlString, (long)[httpResponse statusCode]);
            NSError *statusError = [NSError errorWithDomain:NSURLErrorDomain
                                                       code:[httpResponse statusCode]
                                                   userInfo:nil];
            completionHandler(nil, statusError);
            return;
        }

        NSString *responseData = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        completionHandler(responseData, nil);
    }];

    [self.currentTask resume];
}

- (NSString *)encodeURIComponent:(NSString *)string {
    NSString *s = [string stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];

    return s;
}

- (NSString *)trimTitle:(NSString *)title {
    // Find the index of the first occurrence of '('
    NSRange range = [title rangeOfString:@"("];

    // If '(' found, substring from the beginning to just before '('
    if (range.location != NSNotFound) {
        title = [title substringToIndex:range.location];
    }

    // Trim leading and trailing whitespace after removing parentheses and their content
    NSString *trimmedTitle = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    return trimmedTitle;
}

- (NSString *)trimArtist:(NSString *)artist {
    NSString *artistWithComma = [artist stringByReplacingOccurrencesOfString:@"/" withString:@","];

    artistWithComma = [artist stringByReplacingOccurrencesOfString:@"、" withString:@","];
    artistWithComma = [artist stringByReplacingOccurrencesOfString:@"&" withString:@"_"];

    // Trim leading and trailing whitespace after removing characters after ','
    NSString *trimmedArtist = [artistWithComma stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    return trimmedArtist;
}

- (NSString *)KanjoToRomaji:(NSString *)kanji {
    return [kanji stringByApplyingTransform:@"Any-Latin; Latin-ASCII; Lower" reverse:NO];
}

- (NSString *)RomajiToHiragana:(NSString *)romaji {
    return [romaji stringByApplyingTransform:@"Any-Hiragana" reverse:NO];
}

- (NSString *)TCToSC:(NSString *)tc {
    return [tc stringByApplyingTransform:@"Hant-Hans" reverse:NO];
}

- (float)calculateSimilarityBetweenText:(NSString *)text1 andText:(NSString *)text2 {
    NSString *lowercaseText1 = [text1 lowercaseString];
    NSString *lowercaseText2 = [text2 lowercaseString];

    NSUInteger length1 = [lowercaseText1 length];
    NSUInteger length2 = [lowercaseText2 length];

    if (length1 == 0 || length2 == 0) {
        return 0.0;
    }

    NSMutableArray *distanceMatrix = [NSMutableArray arrayWithCapacity:length1 + 1];

    for (int i = 0; i < length1 + 1; i++) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:length2 + 1];

        for (int j = 0; j < length2 + 1; j++) {
            [row addObject:@(0)];
        }

        [distanceMatrix addObject:row];
    }

    for (int i = 0; i <= length1; i++) {
        distanceMatrix[i][0] = @(i);
    }

    for (int j = 0; j <= length2; j++) {
        distanceMatrix[0][j] = @(j);
    }

    for (int i = 1; i <= length1; i++) {
        unichar char1 = [lowercaseText1 characterAtIndex:i - 1];

        for (int j = 1; j <= length2; j++) {
            unichar char2 = [lowercaseText2 characterAtIndex:j - 1];

            if (char1 == char2) {
                distanceMatrix[i][j] = distanceMatrix[i - 1][j - 1];
            } else {
                int deletion = [distanceMatrix[i - 1][j] intValue] + 1;
                int insertion = [distanceMatrix[i][j - 1] intValue] + 1;
                int substitution = [distanceMatrix[i - 1][j - 1] intValue] + 1;
                distanceMatrix[i][j] = @(MIN(MIN(deletion, insertion), substitution));
            }
        }
    }

    float similarity = 1.0 - ([distanceMatrix[length1][length2] floatValue] / MAX(length1, length2));
    return similarity;
}

@end
