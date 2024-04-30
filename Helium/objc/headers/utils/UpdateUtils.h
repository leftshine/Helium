//
//  UpdateUtils.h
//  Helium
//
//  Created by Fuuko on 2024/4/30.
//

#ifndef UpdateUtils_h
#define UpdateUtils_h

@interface UpdateUtils : NSObject

+ (void)fetchLatestReleaseForRepo:(NSString *)repo isPreRelease:(BOOL)isPreRelease completionHandler:(void (^)(NSDictionary *result))completionHandler;

@end

#endif /* UpdateUtils_h */
