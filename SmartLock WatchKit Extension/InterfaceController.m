//
//  InterfaceController.m
//  SmartLock WatchKit Extension
//
//  Created by toshiyuki on 2015/04/11.
//  Copyright (c) 2015年 toshiyuki. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceButton *unlock;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *lock;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [WKInterfaceController openParentApplication:@{@"action": @"state"} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSNumber* isConnected = [replyInfo objectForKey:@"state"];
        if (isConnected.boolValue) {
            [self locked];
        } else {
            [self unlocked];
        }
    }];
}

- (void) locked {
    [self.lock setBackgroundColor: UIColor.grayColor];
    [self.unlock setBackgroundColor: UIColor.blackColor];
}

- (void) unlocked {
    [self.lock setBackgroundColor: UIColor.blackColor];
    [self.unlock setBackgroundColor: UIColor.grayColor];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}
- (IBAction)unlockAction {
    [WKInterfaceController openParentApplication:@{@"action": @"unlock"} reply:^(NSDictionary *replyInfo, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self unlocked];
        });
    }];
}
- (IBAction)lockAction {
    [WKInterfaceController openParentApplication:@{@"action": @"lock"} reply:^(NSDictionary *replyInfo, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self locked];
        });
    }];
}



@end



