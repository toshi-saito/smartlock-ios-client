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
    OBSERVE(EVENT_DONE_PAIRING, donePairing);
    
    isFound = NO;
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

- (void) donePairing {
    [self.pairingIndicator stopAnimating];
    self.pairingCheck.hidden = NO;
    
    DELAY_RUN(2)
        PRESENT_VIEW_CONTROLLER(@"Main");
    DELAY_RUN_END
}

@end
