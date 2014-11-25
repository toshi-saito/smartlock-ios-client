//
//  WellcomeController.m
//  Central
//
//  Created by toshiyuki on 2014/11/05.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import "WellcomeController.h"
#import "BLECentral.h"

@interface WellcomeController ()

@end

@implementation WellcomeController

- (void)viewDidLoad {
    [super viewDidLoad];
    [BLECentral sharedInstance];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier
                                  sender:(id)sender {
    if (![BLECentral sharedInstance].isReady) {
        ERROR_ALERT(@"BLUETOOTHを有効にしてください。");
        return false;
    }
    [[BLECentral sharedInstance] releasePairing];
    
    return true;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
