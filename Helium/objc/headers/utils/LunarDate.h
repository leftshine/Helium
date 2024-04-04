//
//  LunarDate.h
//  Helium
//
//  Created by Fuuko on 2024/3/25.
//

#ifndef LunarDate_h
#define LunarDate_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LunarDate : NSObject

+ (NSCalendar *)chineseCalendar;
+ (NSString *)getChineseCalendarWithDate:(NSDate *)date format:(NSString *)format;

@end

NS_ASSUME_NONNULL_END

#endif /* LunarDate_h */
