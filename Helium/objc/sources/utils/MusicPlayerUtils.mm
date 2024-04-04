#import "MusicPlayerUtils.h"

@implementation MusicPlayerUtils

static NSDictionary *bundleids = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      // 1: title, 2: artist, 3: album
                                      @{ @"default": @2, @"bluetooth": @1, @"wired": @1 }, @"com.soda.music", //汽水音乐

                                  @{ @"default": @2, @"bluetooth": @1, @"wired": @2 }, @"com.tencent.QQMusic", //QQ音乐
                                  @{ @"default": @2, @"bluetooth": @1, @"wired": @2 }, @"com.yeelion.kwplayer", //酷我音乐
                                  @{ @"default": @2, @"bluetooth": @1, @"wired": @2 }, @"com.yeelion.kwplayersimple", //酷我音乐纯净版
                                  @{ @"default": @2, @"bluetooth": @1, @"wired": @2 }, @"com.migu.migumobilemusic", //咪咕音乐
                                  @{ @"default": @2, @"bluetooth": @1, @"wired": @2 }, @"com.wenyu.bodian", //波点音乐

                                  @{ @"default": @2, @"bluetooth": @2, @"wired": @2 }, @"com.douban.DoubanRadio", //豆瓣FM

                                  @{ @"default": @1, @"bluetooth": @1, @"wired": @1 }, @"com.netease.cloudmusic", //网易云音乐
                                  @{ @"default": @1, @"bluetooth": @1, @"wired": @1 }, @"com.kugou.kugou1002", //酷狗音乐
                                  @{ @"default": @1, @"bluetooth": @1, @"wired": @1 }, @"com.kugou.kgyouth", //酷狗概念版
                                  @{ @"default": @1, @"bluetooth": @1, @"wired": @1 }, @"com.kugou.kugoupure", //酷狗音速版
                                  @{ @"default": @1, @"bluetooth": @1, @"wired": @1 }, @"com.kugou.viper", //VIPER HiFi
                                  @{ @"default": @1, @"bluetooth": @1, @"wired": @1 }, @"com.zhangchao.AudioPlayer", //Ever Play
                                  nil];

+ (BOOL)hasBluetoothHeadset {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];

    for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
        if ([[output portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            return YES;
        }
    }

    return NO;
}

+ (BOOL)hasWiredHeadset {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];

    for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
        if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            return YES;
        }
    }

    return NO;
}

+ (NSString *)getLyricsKeyByBundleIdentifier:(NSString *)bundleid lyricsType:(NSInteger)lyricsType bluetoothType:(NSInteger)bluetoothType wiredType:(NSInteger)wiredType unsupported:(BOOL)unsupported autoDetected:(BOOL)autoDetected {
    if (unsupported) {
        if (self.hasWiredHeadset) {
            return [self getLyricsKeyByType:wiredType];
        } else if (self.hasBluetoothHeadset) {
            return [self getLyricsKeyByType:bluetoothType];
        } else {
            return [self getLyricsKeyByType:lyricsType];
        }
    } else {
        if (bundleid) {
            NSDictionary *item = bundleids[bundleid];

            if (item) {
                if (self.hasWiredHeadset) {
                    return [self getLyricsKeyByType:autoDetected ? [item[@"wired"] integerValue] : wiredType];
                } else if (self.hasBluetoothHeadset) {
                    return [self getLyricsKeyByType:autoDetected ? [item[@"bluetooth"] integerValue] : bluetoothType];
                } else {
                    return [self getLyricsKeyByType:autoDetected ? [item[@"default"] integerValue] : lyricsType];
                }
            }
        }
    }

    return nil;
}

+ (NSString *)getLyricsKeyByType:(NSInteger)type {
    if (type == 2) {
        return @"kMRMediaRemoteNowPlayingInfoArtist";
    } else if (type == 3) {
        return @"kMRMediaRemoteNowPlayingInfoAlbum";
    } else {
        return @"kMRMediaRemoteNowPlayingInfoTitle";
    }
}

@end
