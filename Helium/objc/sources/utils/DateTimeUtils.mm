//
//  DateTimeUtils.mm
//  Helium
//
//  Created by Fuuko on 2024/4/16.
//

#import "DateTimeUtils.h"

@implementation DateTimeUtils

+ (long long)getCurrentTimestamp {
    NSDate *now = [NSDate date];
    NSTimeInterval timestamp = [now timeIntervalSince1970];
    long long longTimestamp = (long long)timestamp;

    return longTimestamp;
}

@end
