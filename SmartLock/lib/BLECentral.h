//
//  BLECentral.h
//  ble_test
//
//  Created by toshiyuki on 2014/10/16.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define EVENT_FOUND_PERIPHERAL @"found_peripheral"
#define EVENT_DONE_PAIRING @"done_pairing"
#define EVENT_CHANGE_VALUE @"change_value"
#define RECONNECT_INTERVAL 5.0

@interface BLECentral : NSObject

@property BOOL isReady;
@property BOOL isForground;

+ (BLECentral*) sharedInstance;
-(id) init;
-(void) startScan;
-(void) stopScan;
-(BOOL) connect;
-(void) lock;
-(void) unlock;
-(void) readState;
-(void) enableNotify;
-(void) disableNotify;
-(BOOL) isConnected;
-(void) releasePairing;
@end
