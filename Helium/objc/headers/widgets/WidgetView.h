//
//  WidgetView.h
//  Helium
//
//  Created by Fuuko on 2024/3/28.
//

#ifndef WidgetView_h
#define WidgetView_h
#import <Foundation/Foundation.h>
#import "AnyBackdropView.h"
@class WidgetsContainerView;

@interface WidgetView : UIView {
    NSMutableDictionary *_userDefaults;
}

@property (nonatomic, strong) NSString *viewID;
@property (nonatomic, strong) WidgetsContainerView *parentView;
@property (nonatomic, strong) UILabel *labelView;
@property (nonatomic, strong) AnyBackdropView *backdropView;
@property (nonatomic, strong) UILabel *maskLabelView;

// @property (nonatomic, strong) NSMutableAttributedString *attributedString;
@property (nonatomic) BOOL fetchingData;
// @property (nonatomic, copy) CallbackBlock callback;
@property (nonatomic, strong) NSString *locale;
@property (nonatomic, strong) NSString *weatherApiKey;
@property (nonatomic) BOOL freeSub;
@property (nonatomic) NSInteger weatherProvider;
@property (nonatomic, strong) NSDictionary *widgetConfig;
@property (nonatomic, strong) UIColor *fontColor;
@property (nonatomic) double fontSize;

- (void)setupView;
- (void)reloadConfig;
- (void)updateLabel;

- (void)setText:(NSString *)text;
- (void)setAttributedText:(NSMutableAttributedString *)text;

- (void)setTextFont:(UIFont *)font;
- (void)setTextAlignment:(NSInteger)align;
- (void)setTextColor:(UIColor *)color;
- (void)setTextAlpha:(double)alpha;

- (void)setDynamicColor:(BOOL)isDynamic;
- (void)setContentHighPriority:(BOOL)isHigh;
@end

#endif /* WidgetView_h */
