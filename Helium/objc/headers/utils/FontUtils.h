//
//  FontUtils.h
//  Helium
//
//  Created by Fuuko on 2024/3/25.
//

#ifndef FontUtils_h
#define FontUtils_h

#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FontUtils : NSObject {
    NSMutableArray *allFontNames;
}

+ (instancetype)shared;
- (void)loadFontsFromFolder:(NSString *)fontFolder;
- (NSArray<NSString *> *)allFontNames;
- (UIFont *)loadFontWithName:(NSString *)fontName size:(float)size bold:(BOOL)bold italic:(BOOL)italic;
@end

NS_ASSUME_NONNULL_END

#endif /* FontUtils_h */
