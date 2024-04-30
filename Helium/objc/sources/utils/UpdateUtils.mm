//
//  UpdateUtils.m
//  Helium
//
//  Created by Fuuko on 2024/4/30.
//

#import "UpdateUtils.h"

@implementation UpdateUtils

+ (void)fetchLatestReleaseForRepo:(NSString *)repo isPreRelease:(BOOL)isPreRelease completionHandler:(void (^)(NSDictionary *result))completionHandler {
    NSString *urlString;

    if (isPreRelease) {
        urlString = [NSString stringWithFormat:@"https://api.github.com/repos/%@/releases", repo];
    } else {
        urlString = [NSString stringWithFormat:@"https://api.github.com/repos/%@/releases/latest", repo];
    }

    NSURL *githubLatestAPIURL = [NSURL URLWithString:urlString];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:githubLatestAPIURL
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error && [response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSError *jsonError;
            id jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                              options:0
                                                                error:&jsonError];

            if (!jsonError) {
                NSString *latestVersion;
                NSString *assetUrl;

                if (isPreRelease) {
                    if ([jsonResponse isKindOfClass:[NSArray class]] && [(NSArray *)jsonResponse count] > 0) {
                        NSDictionary *latestRelease = [(NSArray *)jsonResponse
                                                       objectAtIndex:0];
                        NSString *tagName = latestRelease[@"tag_name"];
                        NSNumber *preRelease = latestRelease[@"prerelease"];

                        if ([preRelease isKindOfClass:[NSNumber class]] && [preRelease boolValue]) {
                            latestVersion = tagName;
                            assetUrl = latestRelease[@"assets"][0][@"browser_download_url"];
                        }
                    }
                } else {
                    if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
                        latestVersion = jsonResponse[@"tag_name"];
                        assetUrl = jsonResponse[@"assets"][0][@"browser_download_url"];
                    }
                }

                if (latestVersion && assetUrl) {
                    completionHandler(@{ @"latestVersion": latestVersion, @"assetUrl": assetUrl });
                    return;
                }
            }

            if (jsonError) {
                completionHandler(@{ @"error": jsonError.localizedDescription });
            } else {
                completionHandler(@{ @"error": @"Unable to fetch latest release." });
            }
        }
    }];

    [task resume];
}

@end
