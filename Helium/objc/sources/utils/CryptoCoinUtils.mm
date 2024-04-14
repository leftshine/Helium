//
//  CryptoCoinUtils.mm
//  Helium
//
//  Created by Fuuko on 2024/3/25.
//

#import "CryptoCoinUtils.h"
#import "NetworkUtils.h"

static NSString *UserAgent = @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5";

@implementation CryptoCoinUtils

+ (NSDictionary *)getMarkPriceByIDs:(NSString *)instIds
{
    NSString *res = [NetworkUtils getDataFrom:[NSString stringWithFormat:@"https://data-api.binance.vision/api/v3/ticker/price?symbols=%@", [NetworkUtils encodeURIComponent:[self getIDArray:instIds]]]];
    NSData *data = [res dataUsingEncoding:NSUTF8StringEncoding];
    NSError *erro = nil;

    if (data != nil) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&erro ];
        NSLog(@"mark price:%@", json);
        return json;
    }

    return nil;
}

+ (NSString *)getIDArray:(NSString *)ids {
    if (ids.length == 0) {
        return @"[]";
    }

    NSArray<NSString *> *idArray = [ids componentsSeparatedByString:@","];
    NSMutableArray<NSString *> *formattedArray = [NSMutableArray array];

    for (NSString *idString in idArray) {
        NSString *trimmedID = [idString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [formattedArray addObject:[NSString stringWithFormat:@"\"%@\"", trimmedID]];
    }

    NSString *resultString = [NSString stringWithFormat:@"[%@]", [formattedArray componentsJoinedByString:@","]];
    return resultString;
}

@end
