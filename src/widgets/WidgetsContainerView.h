#import <Foundation/Foundation.h>
#import "WidgetView.h"

@interface WidgetsContainerView : UIView {
    NSMutableDictionary *_userDefaults;
}
@property (nonatomic, strong) NSString *viewID;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) NSMutableArray<WidgetView *> *widgetViews;
@property (nonatomic) BOOL isEnabled;
@property (nonatomic) BOOL isLandscape;
@property (nonatomic) NSInteger orientationMode;

- (void)setupView;
- (void)reloadConfig;
- (void)reloadWidgets;
- (void)showOrHide;

- (void)setHasBlur:(BOOL) hasBlur;
- (void)setBlurEffect:(BOOL) isDark;
- (void)setBlurAlpha:(double) alpha;
- (void)setBlurCornerRadius:(double) radius;

- (void)setLandscape:(BOOL) landscape;

- (void)cancleTimer;
- (void)resumeTimer;
- (void)pauseTimer;
@end
