//
//  MainController.m
//  Central
//
//  Created by toshiyuki on 2014/10/22.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import "MainController.h"
#import "BLECentral.h"
#import "Location.h"
#import "Settings.h"

@interface MainController ()
@property (strong, nonatomic) IBOutlet UIView *bg;
@property (weak, nonatomic) IBOutlet UIButton *unlockButton;
@property (weak, nonatomic) IBOutlet UIButton *lockButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UIButton *reScanButton;
@property (weak, nonatomic) IBOutlet UILabel *autoUnlockLabel;
@end

#pragma mark - ViewController
@implementation MainController
- (void)viewDidLoad {
    [super viewDidLoad];

    self.indicator.hidesWhenStopped = YES;
    [self.indicator startAnimating];
    
    self.unlockButton.layer.borderColor = [UIColor greenColor].CGColor;
    self.unlockButton.layer.borderWidth = 2.0f;
    self.unlockButton.layer.cornerRadius = 50.0f;
    self.unlockButton.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.unlockButton.enabled = NO;

    self.lockButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.lockButton.layer.borderWidth = 2.0f;
    self.lockButton.layer.cornerRadius = 50.0f;
    self.lockButton.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.lockButton.enabled = NO;
    
    self.reScanButton.hidden = YES;
    
    self.autoUnlockLabel.text = @"";
    
    self.autoUnlockLabel.tag = 10;
    self.autoUnlockLabel.userInteractionEnabled = YES;
    [self updateAutoUnlockLabel];
    
    // BLEからの通知をうける
    OBSERVE(EVENT_CHANGE_VALUE, currentState:);
    OBSERVE(EVENT_DO_PAIRING, connected);
    
    // lock / unlock を読み取って背景色を変更する
    if ([BLECentral sharedInstance].isConnected) {
        [self connected];
    } else {
        [self reconnect];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Event
- (IBAction)clickUnlock:(id)sender {
    if (![BLECentral sharedInstance].isConnected) {
        [self reconnect];
    } else {
        [[BLECentral sharedInstance] unlock];
    }
}

- (IBAction)clickLock:(id)sender {
    if (![BLECentral sharedInstance].isConnected) {
        [self reconnect];
    } else {
        [[BLECentral sharedInstance] lock];
    }
}

- (IBAction)clickReScan:(id)sender {
    [[BLECentral sharedInstance] releasePairing];
    REMOVE_OBSERVERS();
    PRESENT_VIEW_CONTROLLER(@"Search");
}

- (IBAction)gotoMap:(id)sender {
    REMOVE_OBSERVERS();
    PRESENT_VIEW_CONTROLLER(@"Map");
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ( touch.view.tag == self.autoUnlockLabel.tag ) {
        [self toggleAutoUnlock];
    }
}

-(void) toggleAutoUnlock {
    if (!Settings.hasHomeLocation) return;
    
    if (Settings.isAutoUnlock) {
        [Settings turnOffAutoUnlock];
        [[Location sharedInstance] startMonitoring];
    } else {
        [Settings turnOnAutoUnlock];
        [[Location sharedInstance] stopMonitoring];
    }
    [self updateAutoUnlockLabel];
}

-(void) updateAutoUnlockLabel {
    if (!Settings.hasHomeLocation) {
        self.autoUnlockLabel.text = @"Disable Auto Unlock";
    } else {
        if (Settings.isAutoUnlock) {
            self.autoUnlockLabel.text = @"AutoUnlock: ON";
        } else {
            self.autoUnlockLabel.text = @"AutoUnlock: OFF";
        }
    }
}

-(void) resume {
    self.reScanButton.hidden = YES;
    [self updateAutoUnlockLabel];
    [self reconnect];
}

#pragma mark - NotificationCenter

-(void) lockAnimation {
    [UIView animateWithDuration:1.0f
                     animations:^{
                         self.bg.backgroundColor = [UIColor blackColor];
                         self.autoUnlockLabel.textColor = [UIColor whiteColor];
                         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                     }];
}

-(void) unlockAnimation {
    [UIView animateWithDuration:1.0f
                     animations:^{
                         self.bg.backgroundColor = [UIColor greenColor];
                         self.autoUnlockLabel.textColor = [UIColor blackColor];
                         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                     }];
}

-(void) connected {
    [[BLECentral sharedInstance] enableNotify];
    DELAY_RUN(1)
        [[BLECentral sharedInstance] readState];
    DELAY_RUN_END
}

-(void)currentState:(NSNotification*)notification {
    // 通知の送信側から送られた値を取得する
    NSString *value = [[notification userInfo] objectForKey:@"val"];
    
    if ([value isEqualToString:@"PAIR"]) {
        // 未ペアリング状態
        REMOVE_OBSERVERS();
        DELAY_RUN(0)
        PRESENT_VIEW_CONTROLLER(@"Search");
        DELAY_RUN_END
        return;
    }
    
    DELAY_RUN(0)
        [self.indicator stopAnimating];
        self.indicator.hidden = YES;
        self.unlockButton.enabled = YES;
        self.lockButton.enabled = YES;

        if ([value isEqualToString: @"O"]) {
            [self unlockAnimation];
        } else {
            [self lockAnimation];
        }
    DELAY_RUN_END;
}

-(void) reconnect {
    [UIView animateWithDuration:0.3f
                     animations:^{
                         self.bg.backgroundColor = [UIColor whiteColor];
                         self.autoUnlockLabel.textColor = [UIColor blackColor];
                         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                     }];

    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    self.unlockButton.enabled = NO;
    self.lockButton.enabled = NO;

    self.reScanButton.hidden = YES;
    
    [[BLECentral sharedInstance] connect];
    DELAY_RUN(10)
        [self connectTimeout];
    DELAY_RUN_END;
}

- (void) connectTimeout {
    if ([BLECentral sharedInstance].isConnected) return;
    self.reScanButton.alpha = 0;
    self.reScanButton.hidden = NO;
    [UIView animateWithDuration:0.7f
                     animations:^{
                         self.reScanButton.alpha = 1;
                     }];
}

@end
