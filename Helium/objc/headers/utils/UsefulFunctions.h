//
//  UsefulFunctions.h
//  Helium
//
//  Created by lemin on 12/8/23.
//

#ifndef UsefulFunctions_h
#define UsefulFunctions_h
BOOL getBoolFromDictKey(NSDictionary *dict, NSString *key, BOOL defaultValue);
BOOL getBoolFromDictKey(NSDictionary *dict, NSString *key);

NSInteger getIntFromDictKey(NSDictionary *dict, NSString *key, NSInteger defaultValue);
NSInteger getIntFromDictKey(NSDictionary *dict, NSString *key);

double getDoubleFromDictKey(NSDictionary *dict, NSString *key, double defaultValue);
double getDoubleFromDictKey(NSDictionary *dict, NSString *key);

NSString * getStringFromDictKey(NSDictionary *dict, NSString *key, NSString *defaultValue);
NSString * getStringFromDictKey(NSDictionary *dict, NSString *key);

#endif /* UsefulFunctions_h */
