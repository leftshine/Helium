//
//  NetworkUtils.mm
//  Helium
//
//  Created by Fuuko on 2024/4/13.
//

#import "NetworkUtils.h"

static NSString *UserAgent = @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5";

@implementation NetworkUtils

+ (NSString *)getDataFrom:(NSString *)url {
    return [self getDataFrom:url userAgent:UserAgent];
}

+ (NSString *)getDataFrom:(NSString *)url userAgent:(NSString *)userAgent {
    HMLog(url);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSString *responseData = nil;

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];

    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            HMLog(url, error);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            if ([httpResponse statusCode] == 200) {
                responseData = [[NSString alloc] initWithData:data
                                                     encoding:NSUTF8StringEncoding];
            } else {
                HMLog(url, (long)[httpResponse statusCode]);
            }
        }

        dispatch_semaphore_signal(semaphore);
    }];

    [task resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)));

    return responseData;
}

+ (NSString *)encodeURIComponent:(NSString *)string
{
    NSString *s = [string stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];

    return s;
}

@end
