//
//  CryptoCoinUtils.h
//  Helium
//
//  Created by Fuuko on 2024/3/25.
//

#ifndef CryptoCoinUtils_h
#define CryptoCoinUtils_h

#import <Foundation/Foundation.h>

@interface CryptoCoinUtils : NSObject
+ (NSDictionary *)getMarkPriceByIDs:(NSString *)ids;
@end

#endif /* CryptoCoinUtils_h */
