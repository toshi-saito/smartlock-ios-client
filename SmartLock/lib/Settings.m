//
//  Settings.m
//  SmartLock
//
//  Created by toshiyuki on 2014/11/26.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import "Settings.h"


#define PAIR_UUID @"pear_device"
#define AUTO_UNLOCK @"auto_unlock"
#define UNLOCK_LOCATION_LAT @"unlock_location_lat"
#define UNLOCK_LOCATION_LNG @"unlock_location_lng"
#define PASSPHRASE @"passphrase"

@implementation Settings

+(NSUserDefaults*) defaults {
    return [NSUserDefaults standardUserDefaults];
}

+(void) with_synctonize: (void (^)(NSUserDefaults *d)) block {
    NSUserDefaults* d = self.defaults;
    block(d);
    [d synchronize];
}

+(NSString*) pairUUID {
    return [self.defaults stringForKey:PAIR_UUID];
}

+(void) savePairUUID: (NSString*) uuid {
    [self with_synctonize:^(NSUserDefaults *d) {
        [d setValue: uuid forKey: PAIR_UUID];
    }];
}

+(BOOL) alreadyPairing {
    return self.pairUUID != nil;
}

+(void) releasePair {
    [self with_synctonize:^(NSUserDefaults *d) {
        [d removeObjectForKey:PAIR_UUID];
    }];
}

+(void) turnOnAutoUnlock {
    [self with_synctonize:^(NSUserDefaults *d) {
        [d setObject:@"1" forKey:AUTO_UNLOCK];
    }];
}

+(void) turnOffAutoUnlock {
    [self with_synctonize:^(NSUserDefaults *d) {
        [d setObject:@"0" forKey:AUTO_UNLOCK];
    }];
}

+(BOOL) isAutoUnlock {
    return [@"1" isEqualToString: [self.defaults objectForKey:AUTO_UNLOCK]];
}

+(void) saveHomeLocation: (CLLocationCoordinate2D) loc {
    [self with_synctonize:^(NSUserDefaults *d) {
        [d setObject: [NSNumber numberWithDouble: loc.latitude] forKey:UNLOCK_LOCATION_LAT];
        [d setObject: [NSNumber numberWithDouble: loc.longitude] forKey:UNLOCK_LOCATION_LNG];
    }];
}

+(CLLocation*) homeLocation {
    NSUserDefaults *d = self.defaults;
    NSNumber* lat = [d objectForKey: UNLOCK_LOCATION_LAT];
    NSNumber* lng = [d objectForKey: UNLOCK_LOCATION_LNG];
    if (lat == nil) return nil;
    return [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue];
}

+(BOOL) hasHomeLocation {
    return self.homeLocation != nil;
}

+(NSString*) passphrase {
    NSString* p = [self.defaults stringForKey:PASSPHRASE];
    if (p == nil) p = @"";
    return p;
}

+(void) savePassphrase: (NSString*) passphrase {
    [self with_synctonize:^(NSUserDefaults *d) {
        [d setValue: passphrase forKey: PASSPHRASE];
    }];
}

@end
