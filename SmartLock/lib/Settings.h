//
//  Settings.h
//  SmartLock
//
//  Created by toshiyuki on 2014/11/26.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Settings : NSObject

+(NSString*) pairUUID;
+(void) savePairUUID:(NSString*) uuid;
+(BOOL) alreadyPairing;
+(void) releasePair;

+(void) turnOnAutoUnlock;
+(void) turnOffAutoUnlock;
+(BOOL) isAutoUnlock;

+(void) saveHomeLocation: (CLLocationCoordinate2D) loc;
+(CLLocation*) homeLocation;
+(BOOL) hasHomeLocation;

+(NSString*) passphrase;
+(void) savePassphrase: (NSString*) passphrase;

@end
