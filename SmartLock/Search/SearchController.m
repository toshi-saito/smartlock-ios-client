//
//  SearchController.m
//  Central
//
//  Created by toshiyuki on 2014/11/05.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import "SearchController.h"
#import "BLECentral.h"

@interface SearchController ()
@property (weak, nonatomic) IBOutlet UILabel *seachingLabel;
@property (weak, nonatomic) IBOutlet UILabel *pairingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchingIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *pairingIndicator;
@property (weak, nonatomic) IBOutlet UILabel *searchingCheck;
@property (weak, nonatomic) IBOutlet UILabel *pairingCheck;
@end

@implementation SearchController {
    BOOL isFound;
    BOOL sendPairing;
}

#pragma mark - ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchingIndicator.hidesWhenStopped = YES;
    self.pairingIndicator.hidesWhenStopped = YES;
    
    // init
    [self.searchingIndicator startAnimating];
    [self.pairingIndicator stopAnimating];
    self.searchingCheck.hidden = YES;
    self.pairingCheck.hidden = YES;
    
    OBSERVE(EVENT_FOUND_PERIPHERAL, foundPeripheral);
    OBSERVE(EVENT_DO_PAIRING, doPairing);
    OBSERVE(EVENT_CHANGE_VALUE, changeValue:);
    
    isFound = NO;
    sendPairing = NO;
    if (![[BLECentral sharedInstance] connect]) {
        [[BLECentral sharedInstance] startScan];
    }
    // タイムアウト設定
    DELAY_RUN(7)
        [self scanTimeout];
    DELAY_RUN_END
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) scanTimeout {
    if (isFound) return;
    [[BLECentral sharedInstance] stopScan];
    ERROR_ALERT(@"見つかりませんでした。");
    REMOVE_OBSERVERS();
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - NSNotificationCenter
- (void) foundPeripheral {
    isFound = YES;
    [self.searchingIndicator stopAnimating];
    [self.pairingIndicator startAnimating];
    self.searchingCheck.hidden = NO;
}

- (void) doPairing {
    isFound = YES;
    if (sendPairing) return;
    sendPairing = YES;
    [self.searchingIndicator stopAnimating];
    [self.pairingIndicator startAnimating];
    self.searchingCheck.hidden = NO;
    [[BLECentral sharedInstance] pairing];
}

- (void) changeValue: (NSNotification*) notification {
    NSString *value = [[notification userInfo] objectForKey:@"val"];
    DELAY_RUN(0)
    if ([value isEqualToString:@"ALREADY"]) {
        ERROR_ALERT(@"別の端末とペアリング済みです。\nこの端末でペアリングするには、SmartLockの電源を切ってください。");
    } else if ([value isEqualToString: @"PHRASE"]) {
        [[[UIAlertView alloc] initWithTitle: @"ペアリング確認" \
                                    message:@"ペアリングを行います。対象のSmatLockのLEDが点滅していることを確認の上OKボタンを押してください。" delegate: self
                                    cancelButtonTitle:nil otherButtonTitles:@"OK", @"Cancel", nil] show];
    }
    DELAY_RUN_END;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // create random string length=10
        char cs[11];
        cs[10] = '\0';
        for (int i = 0; i < 10; i++) {
            cs[i] = arc4random() % (126 - 33) + 33; //33=! 126=~
        }
        [[BLECentral sharedInstance] sendPassphrase: [NSString stringWithCString: cs encoding:NSUTF8StringEncoding]];

        REMOVE_OBSERVERS();
        {
            DELAY_RUN(0)
            [self.pairingIndicator stopAnimating];
            self.pairingCheck.hidden = NO;
            DELAY_RUN_END
        }
        
        DELAY_RUN(2)
        PRESENT_VIEW_CONTROLLER(@"Main");
        DELAY_RUN_END
    } else if (buttonIndex == 1) {
        REMOVE_OBSERVERS();
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

@end
