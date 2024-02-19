// https://github.com/DGh0st/HSWidgets
#import "../helpers/private_headers/WeatherHeaders.h"

@class City, WATodayModel;
@protocol HWeatherControllerObserver;

extern NSString *const HWeatherFakeDisplayName;
extern NSString *const HWeatherFakeDescription;
extern NSString *const HWeatherFakeTemperature;

@interface HWeatherController : NSObject <WATodayModelObserver>
@property (nonatomic, retain) WATodayModel *todayModel;
@property (nonatomic, retain) NSBundle *weatherBundle;
@property (nonatomic, retain) NSMutableArray *observers;
@property (nonatomic, retain) WeatherPreferences *weatherPreferences;
@property (nonatomic) BOOL useFahrenheit;
@property (nonatomic) BOOL useMetric;
@property (nonatomic) NSLocale *locale;
+(instancetype)sharedInstance;
-(NSString *)locationName;
-(UIImage *)conditionsImage;
-(UIImage *)conditionsImageLegacy;
-(NSString *)conditionsImageName;
-(NSString *)conditionsDescription;
-(NSString *)temperature;
-(NSString *)temperature:(BOOL) withSymbol;
-(NSString *)feelsLike;
-(NSString *)feelsLike:(BOOL) withSymbol;
-(NSString *)highDescription;
-(NSString *)highDescription:(BOOL) withSymbol;
-(NSString *)lowDescription;
-(NSString *)lowDescription:(BOOL) withSymbol;
-(NSString *)windSpeed;
-(NSString *)windSpeed:(BOOL) withUnit;
-(NSString *)windDirection;
-(NSString *)windDirection:(BOOL) shortDescription;
-(NSString *)humidity;
-(NSString *)humidity:(BOOL) withSymbol;
-(NSString *)visibility;
-(NSString *)visibility:(BOOL) withUnit;
-(NSString *)pressure;
-(NSString *)pressure:(BOOL) withUnit;
-(NSString *)UVIndex;
-(NSString *)precipitation;
-(NSString *)precipitation:(BOOL) withUnit;
-(NSString *)airQualityIndex;
-(NSDictionary *)weatherData;
-(WAForecastModel *)forcastModel;
-(City *)currentCity;

-(void)requestModelUpdate;
-(void)addObserver:(id<HWeatherControllerObserver>)observer;
-(void)removeObserver:(id<HWeatherControllerObserver>)observer;
@end