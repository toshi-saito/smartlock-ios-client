//
//  Loc.m
//  Smart Lock
//
//  Created by toshiyuki on 2014/11/20.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import "Location.h"
#import "Settings.h"

@interface Location() <CLLocationManagerDelegate>
@end

@implementation Location {
    CLLocationManager* manager;
    BOOL isMonitoring;
}

#pragma mark - init
+ (Location*)sharedInstance {
    static Location* instance = nil;
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}

-(id) init {
    manager = [[CLLocationManager alloc] init];
    manager.delegate = self;
    isMonitoring = NO;
    return self;
}

#pragma mark - Public Methods-
-(void) startMonitoring {
    if (!Settings.hasHomeLocation) {
        // 位置未設定の場合は、モニタリングを終了する。
        [self stopMonitoring];
        return;
    }
    
    if (!self.authorized) {
        [self doAuthorize];
    }
    
    if (isMonitoring) return;
    
    manager.distanceFilter = 200;
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    manager.pausesLocationUpdatesAutomatically = YES;
    
    [manager startMonitoringSignificantLocationChanges];
    isMonitoring = YES;
}

-(void) stopMonitoring {
    [manager stopMonitoringSignificantLocationChanges];
    isMonitoring = NO;
}

-(void) doAuthorize {
    [manager requestAlwaysAuthorization];
}


#pragma mark - LocationManagerDelegate
-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    if (!Settings.hasHomeLocation) {
        // 位置未設定の場合は、モニタリングを終了する。
        [self stopMonitoring];
        return;
    }
    
    if (Settings.isAutoUnlock) {
        // 自動アンロックが有効な場合も終了する。
        [self stopMonitoring];
        return;
    }

    CLLocation *recentLocation = locations.lastObject;
    CLLocationDistance m = [recentLocation distanceFromLocation: Settings.homeLocation];
    NSLog(@"distance: %f", m);

    
    if (m >= 250) {
        //250M以上離れたら自動アンロック有効
        SEND_NOTIFICATION(@"自動アンロックが有効になりました。");
        [Settings turnOnAutoUnlock];
        [self stopMonitoring];
    }
}

-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusAuthorizedAlways) {
        NSNotification *n = [NSNotification notificationWithName:LOC_NOT_AUTORIZE object:self];
        [[NSNotificationCenter defaultCenter] postNotification:n];
        self.authorized = NO;
    } else {
        self.authorized = YES;
    }
}

@end
