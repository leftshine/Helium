@class CLLocation;

@interface WFLocation : NSObject // iOS 10 - 13
@property NSInteger archiveVersion; // ivar: _archiveVersion
@property (copy, nonatomic) NSString *city; // ivar: _city
@property (copy, nonatomic) NSString *country; // ivar: _country
@property (copy, nonatomic) NSString *countryAbbreviation; // ivar: _countryAbbreviation
@property (copy, nonatomic) NSString *county; // ivar: _county
@property (retain, nonatomic) NSDate *creationDate; // ivar: _creationDate
@property (copy, nonatomic) NSString *displayName; // ivar: _displayName
@property (copy, nonatomic) CLLocation *geoLocation; // ivar: _geoLocation
@property (copy, nonatomic) NSString *locationID; // ivar: _locationID
@property (readonly, nonatomic) BOOL needsGeocoding;
@property (readonly, nonatomic) BOOL shouldQueryForAirQualityData;
@property (copy, nonatomic) NSString *state; // ivar: _state
@property (copy, nonatomic) NSString *stateAbbreviation; // ivar: _stateAbbreviation
@property (retain, nonatomic) NSTimeZone *timeZone; // ivar: _timeZone
@property (copy, nonatomic) NSString *weatherDisplayName; // ivar: _weatherDisplayName
@property (copy, nonatomic) NSString *weatherLocationName; // ivar: _weatherLocationName
@property (readonly, nonatomic) NSString *wf_weatherChannelGeocodeValue;
@end
