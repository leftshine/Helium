//
//  WidgetView.mm
//  Helium
//
//  Created by Fuuko on 2024/4/13.
//

#import "WidgetsContainerView.h"
#import "WidgetUtils.h"
#import "WidgetView.h"

#import "FontUtils.h"
#import "UsefulFunctions.h"

@implementation WidgetView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];

    if (self) {
        [self setupView];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setupView];
    }

    return self;
}

- (void)setupView {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.layer.borderColor = [UIColor greenColor].CGColor;

    self.fetchingData = false;

    self.labelView = [[UILabel alloc] initWithFrame:CGRectZero];
    self.labelView.numberOfLines = 0;
    self.labelView.lineBreakMode = NSLineBreakByWordWrapping;
    self.labelView.translatesAutoresizingMaskIntoConstraints = NO;
    // [self.labelView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [self addSubview:self.labelView];

    self.backdropView = [[AnyBackdropView alloc] initWithFrame:CGRectZero];
    self.backdropView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.backdropView];

    self.maskLabelView = [[UILabel alloc] initWithFrame:CGRectZero];
    self.maskLabelView.numberOfLines = 0;
    self.maskLabelView.lineBreakMode = NSLineBreakByWordWrapping;
    self.maskLabelView.translatesAutoresizingMaskIntoConstraints = NO;
    // [self.maskLabelView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [self.backdropView setMaskView:self.maskLabelView];

    [self addConstraints:@[
         [self.topAnchor constraintEqualToAnchor:self.labelView.topAnchor],
         [self.leadingAnchor constraintEqualToAnchor:self.labelView.leadingAnchor],
         [self.bottomAnchor constraintEqualToAnchor:self.labelView.bottomAnchor],
         [self.trailingAnchor constraintEqualToAnchor:self.labelView.trailingAnchor],

         [self.backdropView.topAnchor constraintEqualToAnchor:self.labelView.topAnchor],
         [self.backdropView.leadingAnchor constraintEqualToAnchor:self.labelView.leadingAnchor],
         [self.backdropView.trailingAnchor constraintEqualToAnchor:self.labelView.trailingAnchor],
         [self.backdropView.bottomAnchor constraintEqualToAnchor:self.labelView.bottomAnchor],
    ]];
}

- (void)reloadConfig {
    if (self.viewID) {
        [self loadUserDefaults:YES];

        NSDictionary *config = nil;

        for (NSDictionary *prop in [_userDefaults objectForKey: @"widgetProperties"]) {
            if ([[prop objectForKey:@"id"] isEqualToString:self.parentView.viewID]) {
                config = prop;
                break;
            }
        }

        // global config
        BOOL debugBorder = getBoolFromDictKey(_userDefaults, @"debugBorder", false);
        [self setDebugBorder:debugBorder];
        NSString *locale = getStringFromDictKey(_userDefaults, @"dateLocale", @"en");
        self.locale = locale;
        BOOL freeSub = getBoolFromDictKey(_userDefaults, @"freeSub", false);
        self.freeSub = freeSub;
        NSString *weatherApiKey = getStringFromDictKey(_userDefaults, @"weatherApiKey");
        self.weatherApiKey = weatherApiKey;
        NSInteger weatherProvider = getIntFromDictKey(_userDefaults, @"weatherProvider");
        self.weatherProvider = weatherProvider;
        BOOL dynamicColor = getBoolFromDictKey(config, @"dynamicColor", true);
        [self setDynamicColor:dynamicColor];

        // text config
        NSDictionary *colorDetails = [config valueForKey:@"colorDetails"] ? [config valueForKey:@"colorDetails"] : @{
                @"usesCustomColor": @(NO)
        };
        BOOL usesCustomColor = getBoolFromDictKey(colorDetails, @"usesCustomColor");
        UIColor *textColor = [UIColor whiteColor];

        if (usesCustomColor && [colorDetails valueForKey:@"color"]) {
            NSData *customColorData = [colorDetails valueForKey:@"color"];
            textColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:customColorData error:nil];
        }

        self.fontColor = textColor;
        NSString *fontName = getStringFromDictKey(config, @"fontName", @"System Font");
        double fontSize = getDoubleFromDictKey(config, @"fontSize", 10);
        self.fontSize = fontSize;
        UIFont *textFont = [[FontUtils shared] loadFontWithName:fontName size:fontSize bold:getBoolFromDictKey(config, @"textBold") italic:getBoolFromDictKey(config, @"textItalic")];
        double textAlpha = getDoubleFromDictKey(config, @"textAlpha", 1.0);

        [self setTextColor:textColor];
        [self setTextAlpha:textAlpha];
        [self setTextFont:textFont];

        // widget config
        NSDictionary *widgetconfig = nil;

        for (NSDictionary *prop in [config objectForKey: @"widgetIDs"]) {
            if ([[prop objectForKey:@"id"] isEqualToString:self.viewID]) {
                widgetconfig = prop;
                break;
            }
        }

        self.widgetConfig = widgetconfig;
    }
}

- (void)loadUserDefaults:(BOOL)forceReload {
    if (forceReload || !_userDefaults) {
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:USER_DEFAULTS_PATH] mutableCopy] ? : [NSMutableDictionary dictionary];
    }
}

- (void)setTextFont:(UIFont *)font {
    self.labelView.font = font;
    self.maskLabelView.font = font;
}

- (void)setTextAlignment:(NSInteger)align {
    self.labelView.textAlignment = (NSTextAlignment)align;
    self.maskLabelView.textAlignment = (NSTextAlignment)align;
}

- (void)setTextColor:(UIColor *)color {
    self.labelView.textColor = color;
    self.maskLabelView.textColor = [UIColor whiteColor];
}

- (void)setTextAlpha:(double)alpha {
    self.labelView.alpha = alpha;
    self.maskLabelView.alpha = alpha;
}

- (void)setDynamicColor:(BOOL)isDynamic {
    if (isDynamic) {
        [self.labelView setHidden:YES];
        [self.backdropView setHidden:NO];
        [self.maskLabelView setHidden:NO];
    } else {
        [self.labelView setHidden:NO];
        [self.backdropView setHidden:YES];
        [self.maskLabelView setHidden:YES];
    }
}

- (void)setDebugBorder:(BOOL)show {
    if (show) {
        self.layer.borderWidth = 1.0;
    } else {
        self.layer.borderWidth = 0;
    }
}

- (void)setContentHighPriority:(BOOL)isHigh {
    [self.labelView setContentHuggingPriority:isHigh ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.maskLabelView setContentHuggingPriority:isHigh ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.labelView setContentCompressionResistancePriority:isHigh ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.maskLabelView setContentCompressionResistancePriority:isHigh ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.labelView setText:text];
        [self.maskLabelView setText:text];
    });
}

- (void)setAttributedText:(NSMutableAttributedString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.labelView setAttributedText:text];
        [self.maskLabelView setAttributedText:text];
    });
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.maskLabelView.frame = CGRectMake(self.maskLabelView.frame.origin.x, self.maskLabelView.frame.origin.y, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    self.maskLabelView.center = [self convertPoint:self.center fromView:self.superview];
}

/*
    Widget Identifiers:
    0 = None
    1 = Date
    2 = Network Up/Down
    3 = Device Temp
    4 = Battery Detail
    5 = Time
    6 = Text
    7 = Battery Percentage
    8 = Charging Symbol
    9 = Weather
    10 = Lyrics
    11 = CPU&MEM
    12 = Crypto Coin
 */
- (void)updateWidget:(NSDictionary *)config callback:(CallbackBlock)callback {
    NSInteger parsedID = [config valueForKey:@"widgetID"] ? [[config valueForKey:@"widgetID"] integerValue] : 0;

    __weak typeof(self) weakSelf = self;
    switch (parsedID) {
        case 1:
        case 5:
            // Date/Time
        {
            [[WidgetUtils sharedInstance] formattedDate:
             getStringFromDictKey(config, @"dateFormat", (parsedID == 1 ? NSLocalizedString(@"E MMM dd", comment: @"") : @"hh:mm"))
                                                 locale:weakSelf.locale
                                               callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        };
            break;

        case 2:
            // Network Speed
        {
            [[WidgetUtils sharedInstance] formattedAttributedSpeedString:
             getBoolFromDictKey(config, @"isUp", NO)
                                                               speedIcon:getIntFromDictKey(config, @"speedIcon", 0)
                                                                 minUnit:getIntFromDictKey(config, @"minUnit", 1)
                                                            hideWhenZero:getBoolFromDictKey(config, @"hideSpeedWhenZero", NO)
                                                                callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;

        case 3:
            // Device Temp
        {
            [[WidgetUtils sharedInstance] formattedTemp:
             getBoolFromDictKey(config, @"useFahrenheit", NO)
                                               callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;

        case 4:
            // Battery Stats
        {
            [[WidgetUtils sharedInstance] formattedBattery:
             getIntFromDictKey(config, @"batteryValueType", 0)
                                                  callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;

        case 6:
            // Text
        {
            @autoreleasepool {
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:
                                                               getStringFromDictKey(config, @"text", NSLocalizedString(@"Example", comment: @""))
                    ];
                attributedString = [[WidgetUtils sharedInstance] formatString:attributedString];
                weakSelf.fetchingData = false;
                callback([attributedString copy]);
            }
        }
        break;

        case 7:
            // Current Capacity
        {
            [[WidgetUtils sharedInstance] formattedCurrentCapacity:
             getBoolFromDictKey(config, @"showPercentage", YES)
                                                          callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;

        case 8:
            // Charging Symbol
        {
            [[WidgetUtils sharedInstance] formattedChargingSymbolImage:
             getBoolFromDictKey(config, @"filled", YES)
                                                              fontSize:weakSelf.fontSize
                                                             textColor:weakSelf.fontColor
                                                              callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;

        case 9:
            // Weather
        {
            [[WidgetUtils sharedInstance] formattedWeatherString:
             getStringFromDictKey(config, @"location")
                                                          format:getStringFromDictKey(config, @"format", @"{i}{n}{lt}°~{ht}°({t}°,{bt}°)💧{h}%")
                                              useCurrentLocation:getBoolFromDictKey(config, @"useCurrentLocation", NO)
                                                       useMetric:getBoolFromDictKey(config, @"useMetric", YES)
                                                   useFahrenheit:getBoolFromDictKey(config, @"useFahrenheit", NO)
                                                          locale:weakSelf.locale
                                                        fontSize:weakSelf.fontSize
                                                       textColor:weakSelf.fontColor
                                                 weatherProvider:weakSelf.weatherProvider
                                                   weatherApiKey:weakSelf.weatherApiKey
                                                         freeSub:weakSelf.freeSub
                                                        callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;

        case 10:
            // Lyrics
        {
            [[WidgetUtils sharedInstance] formattedLyricsString:
             getIntFromDictKey(config, @"unsupported", 0)
                                                   unLyricsType:getIntFromDictKey(config, @"unLyricsType", 1)
                                                unBluetoothType:getIntFromDictKey(config, @"unBluetoothType", 1)
                                                    unWiredType:getIntFromDictKey(config, @"unWiredType", 1)
                                                      supported:getIntFromDictKey(config, @"supported", 0)
                                                     lyricsType:getIntFromDictKey(config, @"lyricsType", 1)
                                                  bluetoothType:getIntFromDictKey(config, @"bluetoothType", 1)
                                                      wiredType:getIntFromDictKey(config, @"wiredType", 1)
                                                       callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;

        case 11:
            // CPU&MEM
        {
            [[WidgetUtils sharedInstance] formattedCPUMEM:
             getIntFromDictKey(config, @"displayType", 0)
                                                 callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;

        case 12:
            // Crypto Coin
        {
            [[WidgetUtils sharedInstance] formattedCryptoCoin:
             getStringFromDictKey(config, @"coinID")
                                                     callback: ^(NSMutableAttributedString *attributedString) {
                weakSelf.fetchingData = false;
                callback(attributedString);
            }
            ];
        }
        break;
    }
}

- (void)updateLabel {
    @autoreleasepool {
        if (!self.fetchingData) {
            self.fetchingData = true;
            [self updateWidget:self.widgetConfig
                      callback:^(NSMutableAttributedString *attributedString) {
                if (attributedString && [attributedString length] > 0) {
                    [self setAttributedText:attributedString];
                    [self setHidden:NO];
                } else {
                    [self setText:@" "];
                    [self setHidden:YES];
                }

                [self.parentView showOrHide];
            }];
        }
    }
}

@end
