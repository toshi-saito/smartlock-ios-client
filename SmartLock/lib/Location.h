//
//  Loc.h
//  Smart Lock
//
//  Created by toshiyuki on 2014/11/20.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#define LOC_NOT_AUTORIZE @"loc_not_authroze"

@interface Location : NSObject
@property BOOL authorized;
+ (Location*) sharedInstance;
-(id) init;
-(void) startMonitoring;
-(void) stopMonitoring;
-(void) doAuthorize;
@end
