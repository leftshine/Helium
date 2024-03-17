#import <Foundation/Foundation.h>

typedef struct {
    uint64_t inputBytes;
    uint64_t outputBytes;
} UpDownBytes;

typedef void (^CallbackBlock)(NSMutableAttributedString *attributedString);

static uint8_t DATAUNIT = 0;

#define KILOBITS 1000
#define MEGABITS 1000000
#define GIGABITS 1000000000
#define KILOBYTES (1 << 10)
#define MEGABYTES (1 << 20)
#define GIGABYTES (1 << 30)

@interface WidgetUtils : NSObject {
    NSDateFormatter *formatter;

    uint64_t prevOutputBytes, prevInputBytes;
    NSAttributedString *attributedUploadPrefix;
    NSAttributedString *attributedDownloadPrefix;
    NSAttributedString *attributedUploadPrefix2;
    NSAttributedString *attributedDownloadPrefix2;
}

+ (instancetype)sharedInstance;
- (void)formattedDate:(NSString *)format locale:(NSString *) locale callback:(CallbackBlock) callback;
- (void)formattedAttributedSpeedString:(BOOL)isUp speedIcon:(NSInteger) speedIcon minUnit:(NSInteger) minUnit hideWhenZero:(BOOL) hideWhenZero callback:(CallbackBlock) callback;
- (void)formattedTemp:(BOOL)useFahrenheit callback:(CallbackBlock) callback;
- (void)formattedBattery:(NSInteger)valueType callback:(CallbackBlock) callback;
- (void)formattedCurrentCapacity:(BOOL)showPercentage callback:(CallbackBlock) callback;
-(void)formattedChargingSymbolImage:(BOOL)filled fontSize:(double)  fontSize textColor:(UIColor *) textColor callback:(CallbackBlock) callback;
- (void)formattedWeatherString:(NSString *)location format:(NSString *) format useCurrentLocation:(BOOL) useCurrentLocation useMetric:(BOOL) useMetric useFahrenheit:(BOOL) useFahrenheit locale:(NSString *) locale fontSize:(double) fontSize textColor:(UIColor *) textColor weatherProvider:(NSInteger) weatherProvider weatherApiKey:(NSString *) weatherApiKey freeSub:(BOOL) freeSub callback:(CallbackBlock) callback;
- (void)formattedLyricsString:(NSInteger)lyricsType bluetoothType:(NSInteger) bluetoothType wiredType:(NSInteger) wiredType unsupported:(BOOL) unsupported callback:(CallbackBlock) callback;

- (NSMutableAttributedString *)formatString:(NSMutableAttributedString *) attributedString;
@end