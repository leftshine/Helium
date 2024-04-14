//
//  NetworkUtils.h
//  Helium
//
//  Created by Fuuko on 2024/4/13.
//

#ifndef NetworkUtils_h
#define NetworkUtils_h

@interface NetworkUtils : NSObject
+ (NSString *)getDataFrom:(NSString *)url;
+ (NSString *)encodeURIComponent:(NSString *)string;
@end

#endif /* NetworkUtils_h */
