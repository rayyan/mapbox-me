//
//  MBMViewController.m
//  MapBox Me
//
//  Created by Justin Miller on 3/29/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "MBMViewController.h"

#import "RMMapBoxSource.h"
#import "RMAnnotation.h"
#import "RMMarker.h"
#import "RMCircle.h"

#define kMapBoxMeNormalTintColor [UIColor colorWithRed:0.120 green:0.650 blue:0.750 alpha:1.000]
#define kMapBoxMeActiveTintColor [UIColor colorWithRed:0.120 green:0.550 blue:0.670 alpha:1.000]

@interface MBMViewController ()

@property (nonatomic, strong) IBOutlet RMMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) RMAnnotation *accuracyCircle;
@property (nonatomic, strong) RMAnnotation *trackingHalo;
@property (nonatomic, strong) RMAnnotation *userLocation;
@property (nonatomic, assign) BOOL shouldRecenter;

- (void)startUpdating;
- (void)stopUpdating;

@end

@implementation MBMViewController

@synthesize mapView;
@synthesize locationManager;
@synthesize accuracyCircle;
@synthesize trackingHalo;
@synthesize userLocation;
@synthesize shouldRecenter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;

    self.title = @"MapBox Me";
    
    self.navigationController.navigationBar.tintColor = kMapBoxMeActiveTintColor;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"TrackingLocation.png"]
                                                                                                  style:UIBarButtonItemStyleBordered
                                                                                                 target:self 
                                                                                                 action:@selector(startUpdating)];
    
    self.mapView.delegate = self;
    self.mapView.tileSource = [[RMMapBoxSource alloc] init];
    self.mapView.decelerationMode = RMMapDecelerationFast;
    self.mapView.adjustTilesForRetinaDisplay = YES;    
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);
    self.mapView.minZoom = 1;
    self.mapView.zoom = 2;

    CGColorRef darkBackgroundColor = CGColorCreateCopyWithAlpha([self.navigationController.navigationBar.tintColor CGColor], 0.5);

    self.mapView.backgroundColor = [UIColor colorWithCGColor:darkBackgroundColor];

    CGColorRelease(darkBackgroundColor);
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    
    panGesture.delegate = self;
    
    [self.mapView addGestureRecognizer:panGesture];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self startUpdating];
}

#pragma mark -

- (void)startUpdating
{
    self.navigationItem.rightBarButtonItem.tintColor = kMapBoxMeActiveTintColor;
    self.navigationItem.rightBarButtonItem.action    = @selector(stopUpdating);

    self.shouldRecenter = YES;
    
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdating
{
    [self.locationManager stopUpdatingLocation];
    
    self.shouldRecenter = NO;
    
    self.navigationItem.rightBarButtonItem.tintColor = kMapBoxMeNormalTintColor;
    self.navigationItem.rightBarButtonItem.action    = @selector(startUpdating);
}

- (void)handleGesture:(UIGestureRecognizer *)gesture
{
    self.shouldRecenter = NO;
}

#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                     animations:^(void)
                     {
                         float delta = manager.location.horizontalAccuracy / 110000;
                         
                         CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(manager.location.coordinate.latitude  - delta, 
                                                                                       manager.location.coordinate.longitude - delta);

                         CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(manager.location.coordinate.latitude  + delta, 
                                                                                       manager.location.coordinate.longitude + delta);

                         if (self.shouldRecenter)
                             [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:southWest northEast:northEast animated:NO];
                         
                         // accuracy circle: visible when homing in
                         //
                         if ( ! self.accuracyCircle)
                         {
                             self.accuracyCircle = [RMAnnotation annotationWithMapView:self.mapView coordinate:manager.location.coordinate andTitle:nil];

                             [self.mapView addAnnotation:self.accuracyCircle];
                         }
                         
                         self.accuracyCircle.coordinate = manager.location.coordinate;
                         
                         [self.mapView.delegate mapView:self.mapView layerForAnnotation:self.accuracyCircle].hidden = (manager.location.horizontalAccuracy <= 10);

                         // tracking halo: visible after homing in
                         //
                         if ( ! self.trackingHalo)
                         {
                             self.trackingHalo = [RMAnnotation annotationWithMapView:self.mapView coordinate:manager.location.coordinate andTitle:nil];
                             
                             [self.mapView addAnnotation:self.trackingHalo];
                         }
                         
                         self.trackingHalo.coordinate = manager.location.coordinate;
                         
                         [self.mapView.delegate mapView:self.mapView layerForAnnotation:self.trackingHalo].hidden = (manager.location.horizontalAccuracy > 10);
                         
                         // user location: always visible
                         //
                         if ( ! self.userLocation)
                         {
                             self.userLocation = [RMAnnotation annotationWithMapView:self.mapView coordinate:manager.location.coordinate andTitle:nil];
                             
                             [self.mapView addAnnotation:self.userLocation];
                         }
                         
                         self.userLocation.coordinate = manager.location.coordinate;
                     }
                     completion:nil];
}

#pragma mark -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark -

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    if ([annotation isEqual:self.accuracyCircle])
    {
        RMCircle *circle = [[RMCircle alloc] initWithView:self.mapView radiusInMeters:self.locationManager.location.horizontalAccuracy];
        
        circle.lineColor = [UIColor colorWithRed:0.378 green:0.552 blue:0.827 alpha:0.7];
        circle.fillColor = [UIColor colorWithRed:0.378 green:0.552 blue:0.827 alpha:0.15];
        
        circle.lineWidthInPixels = 2.0;
        
        // TODO: add throbber animation
        
        return circle;
    }
    else if ([annotation isEqual:self.trackingHalo])
    {
        RMMarker *halo = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"TrackingDotHalo.png"]];
        
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        
        boundsAnimation.duration = 2.0;
        
        boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

        boundsAnimation.repeatCount = MAXFLOAT;
        
        boundsAnimation.fromValue = [NSValue valueWithCGRect:CGRectMake(0, 0, halo.bounds.size.width * 0.2, halo.bounds.size.height * 0.2)];
        boundsAnimation.toValue   = [NSValue valueWithCGRect:CGRectMake(0, 0, halo.bounds.size.width * 1.1, halo.bounds.size.height * 1.1)];

        boundsAnimation.removedOnCompletion = NO;
        
        [halo addAnimation:boundsAnimation forKey:@"animateBounds"];

        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        
        opacityAnimation.duration = 2.0;
        
        opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

        opacityAnimation.repeatCount = MAXFLOAT;
        
        opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        opacityAnimation.toValue   = [NSNumber numberWithFloat:0.0];
        
        opacityAnimation.removedOnCompletion = NO;
        
        [halo addAnimation:opacityAnimation forKey:@"animateOpacity"];
        
        return halo;
    }
    else if ([annotation isEqual:self.userLocation])
    {
        return [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"TrackingDot.png"]];
    }
    
    return nil;
}

@end