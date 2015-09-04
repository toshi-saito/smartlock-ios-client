//
//  AppDelegate.m
//  SmartLock
//
//  Created by toshiyuki on 2014/11/25.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import "AppDelegate.h"

#import "BLECentral.h"
#import "Location.h"
#import "Settings.h"

@interface AppDelegate ()

@end

@implementation AppDelegate {
    __block UIBackgroundTaskIdentifier bgTask;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [BLECentral sharedInstance];
    if (Settings.hasHomeLocation && !Settings.isAutoUnlock) {
        [[Location sharedInstance] startMonitoring];
    }
    
    UIViewController *viewController;
    if (Settings.alreadyPairing) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        viewController = [storyboard instantiateInitialViewController];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Search" bundle:nil];
        viewController = [storyboard instantiateInitialViewController];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [BLECentral sharedInstance].isForground = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [BLECentral sharedInstance].isForground = YES;
    id vc = (id) self.window.rootViewController;
    if ([vc respondsToSelector:@selector(resume)]) {
        [vc resume];
    }

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

void (^stateReply)(NSDictionary *);

- (void) application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply {
    
    NSString* action = [userInfo objectForKey:@"action"];
    
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        if ([action isEqualToString:@"state"]) {
            [[BLECentral sharedInstance] enableNotify];
            stateReply = reply;
            BOOL isConnected = [BLECentral sharedInstance].isConnected;
            if (isConnected) {
                [self connected];
            } else {
                [self reconnect];
            }
            return;
        } else if ([action isEqualToString:@"lock"]) {
            [[BLECentral sharedInstance] lock];
            reply(nil);
        } else if ([action isEqualToString:@"unlock"]) {
            [[BLECentral sharedInstance] unlock];
            reply(nil);
        }
        bgTask = UIBackgroundTaskInvalid;
    });
    
    NSLog(@"action: %@", action);
}

- (void) connected {
    OBSERVE(EVENT_CHANGE_VALUE, currentState:);
    DELAY_RUN(1)
    [[BLECentral sharedInstance] readState];
    DELAY_RUN_END
}

-(void) reconnect {
    OBSERVE(EVENT_DO_PAIRING, connected);
    [[BLECentral sharedInstance] enableNotify];
    [[BLECentral sharedInstance] connect];
}

-(void)currentState:(NSNotification*)notification {
    NSString *value = [[notification userInfo] objectForKey:@"val"];
    
    if ([value isEqualToString: @"O"]) {
        stateReply(@{@"state": @1});
    } else {
        stateReply(@{@"state": @0});
    }
    bgTask = UIBackgroundTaskInvalid;
}


@end
