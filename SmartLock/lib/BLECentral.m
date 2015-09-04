//
//  BLECentral.m
//  ble_test
//
//  Created by toshiyuki on 2014/10/16.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import "BLECentral.h"
#import <UIKit/UIKit.h>
#import "Location.h"
#import "Settings.h"

#define RESTORE_KEY @"SmartLock-BLE-CENTRAL"

#define UNLOCK_PHRASE @"O"
#define LOCK_PHRASE @"C"
#define STATE_PHRASE @"S"
#define PAIRING_PHRASE @"PAIR"
#define PASSPHRASE_PREFIX @"PSS_"

@interface BLECentral() <CBCentralManagerDelegate, CBPeripheralDelegate>
@end

@implementation BLECentral {
    NSDate* lastReconnectTime;
    CBCentralManager* manager;
    CBPeripheral* peripheral;
    CBCharacteristic* readCaracteristic;
    CBCharacteristic* writeCaracteristic;
}

#pragma mark - init

+ (BLECentral*)sharedInstance {
    static BLECentral* instance = nil;
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}

-(id) init {
    peripheral = nil;
    self.isReady = false;
    lastReconnectTime = nil;
    self.isForground = NO;
    manager = [[CBCentralManager alloc] initWithDelegate:self
                                                        queue: dispatch_queue_create("smartlock.central.ios", DISPATCH_QUEUE_SERIAL)
                                                      options:@{ CBCentralManagerOptionRestoreIdentifierKey: RESTORE_KEY }];
    return self;
}

#pragma mark - CentralManagerDelegate

-(void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    for (CBPeripheral* p in dict[CBCentralManagerRestoredStatePeripheralsKey]) {
        peripheral = p; // 回してるけど1個しかない前提。
        [self reconnectPeripheral];
    }
}

- (void) centralManagerDidUpdateState:(CBCentralManager*)centralManager {
    
    if (centralManager.state == CBCentralManagerStatePoweredOn) {
        self.isReady = true;
        if (Settings.alreadyPairing) {
            [self connect];
        }
        return;
    }
    
    if (centralManager.state == CBCentralManagerStatePoweredOff) {
        self.isReady = false;
        [self stopScan];
        return;
    }
    
    self.isReady = false;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)p advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    peripheral = p;
    [self reconnectPeripheral];
    
    NSLog(@"advertisementData: %@", advertisementData);
    
    // 見つかったのでここでスキャンは終了する。
    [self stopScan];
    
    POST(EVENT_FOUND_PERIPHERAL);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)p {
    peripheral.delegate = self;
    [peripheral discoverServices: @[ UUID(SERVICE_UUID) ]];
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // クライアントの接続が切れたら、再接続要求を出す。
    [self connect];
}

-(void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)p error:(NSError *)error {
    [manager connectPeripheral: peripheral options: nil];
}

#pragma mark - Public Methods

-(void) disconnectPeripheral {
    if (peripheral.state != CBPeripheralStateDisconnected) return;
    if (peripheral == nil) return;
    
    if (peripheral.services == nil) {
        [manager cancelPeripheralConnection: peripheral];
        return;
    };
    
    for (CBService *service in peripheral.services) {
        if (service.characteristics == nil) continue;
        for (CBCharacteristic *characteristic in service.characteristics) {
            if (!characteristic.isNotifying) continue;
            [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        }
    }
    [manager cancelPeripheralConnection: peripheral];
}

-(BOOL) connect {
    // 1個しか接続しない前提。
    NSArray* connectedPeripherals = [manager retrieveConnectedPeripheralsWithServices: @[UUID(SERVICE_UUID)]];
    if ([connectedPeripherals count] > 0) {
        // 発見。-> 再接続する
        peripheral = connectedPeripherals[0];
        [self reconnectPeripheral];
        return YES;
    }
    
    NSString* pair = Settings.pairUUID;
    if (pair != nil) {
        NSArray* retrievePeripherals = [manager retrievePeripheralsWithIdentifiers:@[UUID(pair)]];
        if ([retrievePeripherals count] > 0) {
            peripheral = retrievePeripherals[0];
            [self reconnectPeripheral];
            return YES;
        }
    }
    return NO;
}

-(void) reconnectPeripheral {
    if (peripheral.state != CBPeripheralStateDisconnected) {
        [self disconnectPeripheral];
    }
    [manager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
}

-(void) startScan {
    [manager scanForPeripheralsWithServices: /*@[UUID(SERVICE_UUID)]*/nil options: @{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:YES]}];
}

-(void) stopScan {
    [manager stopScan];
}

-(void) writeValue: (NSString*) val {
    NSData* data = [val dataUsingEncoding:NSUTF8StringEncoding];
    [peripheral writeValue:data forCharacteristic:writeCaracteristic
                           type: CBCharacteristicWriteWithoutResponse];
}

-(void) readValue {
    [peripheral readValueForCharacteristic: readCaracteristic];
}

-(BOOL) isConnected {
    return peripheral.state == CBPeripheralStateConnected;
}

-(void) releasePairing {
    [Settings releasePair];
    if (self.isConnected) {
        [self disconnectPeripheral];
    }
}

-(void) reconnected {
    lastReconnectTime = [NSDate date];
    DELAY_RUN(RECONNECT_INTERVAL)
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate: lastReconnectTime];
        if (interval < RECONNECT_INTERVAL) return;
    DELAY_RUN_END
}

-(void) lock {
    [self writeValue: [LOCK_PHRASE stringByAppendingString: Settings.passphrase]];
}

-(void) unlock {
    [self writeValue: [UNLOCK_PHRASE stringByAppendingString: Settings.passphrase]];
}

-(void) readState {
    [self writeValue: [STATE_PHRASE stringByAppendingString: Settings.passphrase]];
}

-(void) pairing {
    [self writeValue: PAIRING_PHRASE];
}

-(void) sendPassphrase: (NSString*) passphrase {
    [Settings savePassphrase: passphrase];
    [self writeValue: [PASSPHRASE_PREFIX stringByAppendingString:passphrase]];
}

-(void) enableNotify {
    [peripheral setNotifyValue:YES forCharacteristic:readCaracteristic];
}

-(void) disableNotify {
    [peripheral setNotifyValue:NO forCharacteristic:readCaracteristic];
}

#pragma mark - PeripheralDelegate
- (void)peripheral:(CBPeripheral *)p didDiscoverServices:(NSError *)error {
    for (CBService * service in peripheral.services) {
        [peripheral discoverCharacteristics:@[UUID(CHARA_TX_UUID)] forService:service];
        [peripheral discoverCharacteristics:@[UUID(CHARA_RX_UUID)] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)p didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    // ここまできたら、完全にクライアントは想定している機器と判断し保存する
    [Settings savePairUUID: [[peripheral identifier] UUIDString]];

    /// Characteristic に対して Notify を受け取れるようにする
    for (CBService *service in peripheral.services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString: CHARA_TX_UUID]) {
                readCaracteristic = characteristic;
            } else {
                writeCaracteristic = characteristic;
            }
        }
    }
    
    if (readCaracteristic != nil && writeCaracteristic != nil) {
        NSNotification *n = [NSNotification notificationWithName:EVENT_DO_PAIRING object:self];
        [[NSNotificationCenter defaultCenter] postNotification:n];
        
        // Auto Unlock
        if (Settings.isAutoUnlock && !self.isForground) {
            DELAY_RUN(2)
                [self unlock];
                SEND_NOTIFICATION(@"鍵を開けました。");
                // ロケーションモニタリングを開始。
                [[Location sharedInstance] startMonitoring];
            DELAY_RUN_END;
            [Settings turnOffAutoUnlock];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    unsigned char data[20];
    
    static char buf[512];
    static int len = 0;
    NSInteger data_len;
    
    if (error) {
        NSLog(@"%@ %@", error, characteristic.value);
        return;
    }

    data_len = characteristic.value.length;
    [characteristic.value getBytes:data length:data_len];
    
    if (data_len == 20) {
        memcpy(&buf[len], data, 20);
        len += data_len;
        
        if (len >= 64) {
            [self bleDidReceiveData:buf length:len];
            len = 0;
        }
    } else if (data_len < 20) {
        memcpy(&buf[len], data, data_len);
        len += data_len;
        
        [self bleDidReceiveData:buf length:len];
        len = 0;
    }
}

- (void) bleDidReceiveData:(const char*) data length:(int) len {
    NSString *s = [[NSString alloc] initWithCString:data encoding: NSUTF8StringEncoding];
    POST_WITH_DATA(EVENT_CHANGE_VALUE, @{@"val": s});
    NSLog(@"receive: %@", s);
}

@end
