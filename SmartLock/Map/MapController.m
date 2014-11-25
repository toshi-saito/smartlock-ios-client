//
//  MapController.m
//  Smart Lock
//
//  Created by toshiyuki on 2014/11/20.
//  Copyright (c) 2014年 toshiyuki. All rights reserved.
//

#import "MapController.h"
#import <MapKit/MapKit.h>
#import "Location.h"
#import "Settings.h"

@interface MapController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *map;

@end

@implementation MapController {
    UILongPressGestureRecognizer* gesture;
    MKPointAnnotation* pin;
    MKCircle* circle;
}

#pragma mark - ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.map.delegate = self;
    self.map.showsUserLocation = YES;
    [self.map setUserTrackingMode:MKUserTrackingModeFollow];
    
    gesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(setPin:)];
    [self.view addGestureRecognizer:gesture];
    
    pin = nil;
    CLLocation* loc = Settings.homeLocation;
    if (loc != nil) {
        [self putPin: loc.coordinate];
    }

    OBSERVE(LOC_NOT_AUTORIZE, notAutorized);
    [[Location sharedInstance] doAuthorize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - NotificationCenter
-(void) notAutorized {
    ERROR_ALERT(@"位置情報サービスを有効にしてください。");
    [self gotoMain];
}

#pragma mark - Event
- (IBAction)clickBack:(id)sender {
    [self gotoMain];
}

#pragma mark - Transition
-(void) gotoMain {
    REMOVE_OBSERVERS();
    PRESENT_VIEW_CONTROLLER(@"Main");
}


#pragma mark mapView
-(void) setPin:(UILongPressGestureRecognizer*) sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    CGPoint pt = [sender locationInView: self.map];
    CLLocationCoordinate2D loc = [self.map convertPoint:pt toCoordinateFromView: self.map];
    
    [self putPin: loc];
    
    [Settings saveHomeLocation: loc];
    
    [[Location sharedInstance] startMonitoring];
}

-(void) putPin: (CLLocationCoordinate2D) loc {
    
    if (pin != nil) {
        [self.map removeAnnotation: pin];
        [self.map removeOverlay: circle];
    }

    pin = [[MKPointAnnotation alloc] init];
    pin.coordinate = loc;
    [self.map addAnnotation: pin];
    
    circle = [MKCircle circleWithCenterCoordinate: loc radius: 250];
    [self.map addOverlay: circle];

}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass: [MKCircle class]] ) {
        MKCircleRenderer* renderer = [[MKCircleRenderer alloc] initWithCircle: overlay];
        renderer.fillColor = [UIColor colorWithRed:106/255.0 green:208/255.0 blue:227/255.0 alpha:0.6];
        return renderer;
    }
    return nil;
}

@end
