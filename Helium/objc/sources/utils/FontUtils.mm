//
//  FontUtils.m
//  Helium
//
//  Created by Fuuko on 2024/3/25.
//

#import "FontUtils.h"

@implementation FontUtils

+ (instancetype)shared {
    static FontUtils *_shared = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });
    return _shared;
}

- (instancetype)init {
    self = [super init];

    if (self != nil) {
        allFontNames = [NSMutableArray array];
    }

    return self;
}

- (void)loadFontsFromFolder:(NSString *)fontFolder {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:fontFolder error:NULL];

    for (NSString *filename in contents) {
        if ([filename.pathExtension isEqualToString:@"ttf"] || [filename.pathExtension isEqualToString:@"otf"]) {
            NSString *fontPath = [fontFolder stringByAppendingPathComponent:filename];

            NSData *fontData = [NSData dataWithContentsOfFile:fontPath];
            CFErrorRef error;
            CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)fontData);
            CGFontRef font = CGFontCreateWithDataProvider(provider);

            if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
                CFStringRef errorDescription = CFErrorCopyDescription(error);
                NSLog(@"Failed to load font: %@", errorDescription);
                CFSafeRelease(errorDescription);
            }

            CFSafeRelease(font);
            CFSafeRelease(provider);
        }
    }
}

- (void)loadAllFonts {
    NSArray *familyNames = [UIFont familyNames];

    [allFontNames removeAllObjects];
    [allFontNames addObjectsFromArray:familyNames];
}

- (NSArray<NSString *> *)allFontNames {
    NSMutableArray *copyArray = [[NSMutableArray alloc] init];

    [self loadAllFonts];
    copyArray = [allFontNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)].mutableCopy;
    [copyArray insertObject:@"System Font" atIndex:0];
    return copyArray;
}

- (UIFont *)loadFontWithName:(NSString *)fontName size:(float)size bold:(BOOL)bold italic:(BOOL)italic {
    UIFont *font = [UIFont fontWithDescriptor:[UIFontDescriptor fontDescriptorWithName:fontName size:size] size:size];

    if ([fontName isEqualToString:@"System Font"]) {
        font = [UIFont systemFontOfSize:size];
    }

    UIFontDescriptorSymbolicTraits symbolicTraits = 0;

    if (bold) {
        symbolicTraits |= UIFontDescriptorTraitBold;
    }

    if (italic) {
        symbolicTraits |= UIFontDescriptorTraitItalic;
    }

    UIFont *specialFont = [UIFont fontWithDescriptor:[[font fontDescriptor] fontDescriptorWithSymbolicTraits:symbolicTraits] size:size];
    return specialFont;
}

void CFSafeRelease(CFTypeRef cf) {
    if (cf != NULL) {
        CFRelease(cf);
    }
}

@end
