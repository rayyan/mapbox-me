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
@property (nonatomic, strong) RMCircle *accuracyCircleLayer;
@property (nonatomic, strong) RMMarker *trackingHaloLayer;
@property (nonatomic, strong) RMMarker *userLocationLayer;
@property (nonatomic, strong) UIImageView *userLocationStaticView;
@property (nonatomic, strong) UIImageView *userHeadingStaticView;
@property (nonatomic, assign) BOOL shouldTrackLocation;
@property (nonatomic, assign) BOOL shouldTrackHeading;

- (void)startTrackingLocation;
- (void)startTrackingHeading;
- (void)stopTracking;

@end

@implementation MBMViewController

@synthesize mapView;
@synthesize locationManager;
@synthesize accuracyCircle;
@synthesize trackingHalo;
@synthesize userLocation;
@synthesize accuracyCircleLayer;
@synthesize trackingHaloLayer;
@synthesize userLocationLayer;
@synthesize userLocationStaticView;
@synthesize userHeadingStaticView;
@synthesize shouldTrackLocation;
@synthesize shouldTrackHeading;

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
                                                                                                 action:@selector(startTrackingLocation)];
    
    self.mapView.delegate = self;
    self.mapView.tileSource = [[RMMapBoxSource alloc] initWithReferenceURL:[NSURL URLWithString:@"http://a.tiles.mapbox.com/v3/mapbox.mapbox-streets.json"]];
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

    [self startTrackingLocation];
}

#pragma mark -

- (void)startTrackingLocation
{
    self.navigationItem.rightBarButtonItem.image     = [UIImage imageNamed:@"TrackingLocation.png"];
    self.navigationItem.rightBarButtonItem.tintColor = kMapBoxMeActiveTintColor;
    self.navigationItem.rightBarButtonItem.action    = ([CLLocationManager headingAvailable] ? @selector(startTrackingHeading) : @selector(stopTracking));

    self.shouldTrackLocation = YES;
    
    [self.locationManager startUpdatingLocation];
}

- (void)startTrackingHeading
{
    self.navigationItem.rightBarButtonItem.image     = [UIImage imageNamed:@"TrackingHeading.png"];
    self.navigationItem.rightBarButtonItem.tintColor = kMapBoxMeActiveTintColor;
    self.navigationItem.rightBarButtonItem.action    = @selector(stopTracking);
    
    self.shouldTrackHeading = YES;
    
    self.locationManager.headingFilter = 5;
    
    self.userLocationLayer.hidden = YES;
    
    self.userHeadingStaticView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HeadingAngleSmall.png"]];
    
    self.userHeadingStaticView.center = CGPointMake(round(self.view.bounds.size.width  / 2), 
                                                    round(self.view.bounds.size.height / 2) - (self.userHeadingStaticView.bounds.size.height / 2) - 4);
    
    self.userHeadingStaticView.alpha = 0.0;
    
    [self.view addSubview:self.userHeadingStaticView];
    
    [UIView animateWithDuration:0.5 animations:^(void) { self.userHeadingStaticView.alpha = 1.0; }];
    
    self.userLocationStaticView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TrackingDot.png"]];
    
    self.userLocationStaticView.center = CGPointMake(round(self.view.bounds.size.width  / 2), 
                                                     round(self.view.bounds.size.height / 2));
    
    [self.view addSubview:self.userLocationStaticView];
    
    [self.locationManager startUpdatingHeading];
}

- (void)stopTracking
{
    self.accuracyCircleLayer.hidden = YES;

    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                     animations:^(void)
                     {
                         self.mapView.transform = CGAffineTransformIdentity;
                         
                         if (self.userHeadingStaticView.superview)
                             self.userHeadingStaticView.alpha = 0.0;
                     }
                     completion:^(BOOL finished)
                     {
                         if (self.userLocationStaticView.superview)
                             [self.userLocationStaticView removeFromSuperview];

                         if (self.userHeadingStaticView.superview)
                             [self.userHeadingStaticView removeFromSuperview];
                         
                         self.userLocationLayer.hidden = NO;
                     }];

    self.shouldTrackLocation = NO;
    self.shouldTrackHeading  = NO;
    
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
    
    self.navigationItem.rightBarButtonItem.image     = [UIImage imageNamed:@"TrackingLocation.png"];
    self.navigationItem.rightBarButtonItem.tintColor = kMapBoxMeNormalTintColor;
    self.navigationItem.rightBarButtonItem.action    = @selector(startTrackingLocation);
}

- (void)handleGesture:(UIGestureRecognizer *)gesture
{
    if (self.shouldTrackHeading)
    {
        [self.userLocationStaticView removeFromSuperview];
        [self.userHeadingStaticView  removeFromSuperview];
        
        self.userLocationLayer.hidden = NO;
    }

    [self stopTracking];
}

#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                     animations:^(void)
                     {
                         float delta = newLocation.horizontalAccuracy / 110000;
                         
                         CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(newLocation.coordinate.latitude  - delta, 
                                                                                       newLocation.coordinate.longitude - delta);

                         CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(newLocation.coordinate.latitude  + delta, 
                                                                                       newLocation.coordinate.longitude + delta);

                         if (self.shouldTrackLocation)
                             [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:southWest northEast:northEast animated:NO];
                         
                         // accuracy circle: visible when homing in, bouncing at first
                         //
                         if ( ! self.accuracyCircle)
                         {
                             self.accuracyCircle = [RMAnnotation annotationWithMapView:self.mapView coordinate:newLocation.coordinate andTitle:nil];

                             [self.mapView addAnnotation:self.accuracyCircle];
                         }
                         
                         // update accuracy circle coordinate
                         //
                         self.accuracyCircle.coordinate = newLocation.coordinate;
                         
                         // hide when homed in
                         //
                         if (newLocation.horizontalAccuracy <= 10)
                             self.accuracyCircleLayer.hidden = YES;
                         
                         // resize to new radius
                         //
                         self.accuracyCircleLayer.radiusInMeters = newLocation.horizontalAccuracy;
                         
                         // tracking halo: visible after homing in to 10m
                         //
                         if ( ! self.trackingHalo)
                         {
                             self.trackingHalo = [RMAnnotation annotationWithMapView:self.mapView coordinate:newLocation.coordinate andTitle:nil];
                             
                             [self.mapView addAnnotation:self.trackingHalo];
                         }
                         
                         self.trackingHalo.coordinate = newLocation.coordinate;
                         
                         // user location: always visible
                         //
                         if ( ! self.userLocation)
                         {
                             self.userLocation = [RMAnnotation annotationWithMapView:self.mapView coordinate:newLocation.coordinate andTitle:nil];
                             
                             [self.mapView addAnnotation:self.userLocation];
                         }
                         
                         self.userLocation.coordinate = newLocation.coordinate;
                     }
                     completion:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (self.shouldTrackHeading && newHeading.trueHeading != 0)
    {
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                         animations:^(void)
                         {
                             self.mapView.transform = CGAffineTransformMakeRotation((M_PI / -180) * newHeading.trueHeading);
                         }
                         completion:nil];
    }
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
        if ( ! self.accuracyCircleLayer)
        {
            // create circle layer
            //
            self.accuracyCircleLayer = [[RMCircle alloc] initWithView:self.mapView radiusInMeters:self.locationManager.location.horizontalAccuracy];
            
            self.accuracyCircleLayer.lineColor = [UIColor colorWithRed:0.378 green:0.552 blue:0.827 alpha:0.7];
            self.accuracyCircleLayer.fillColor = [UIColor colorWithRed:0.378 green:0.552 blue:0.827 alpha:0.15];
            
            self.accuracyCircleLayer.lineWidthInPixels = 2.0;
        }
        
        return self.accuracyCircleLayer;
    }
    else if ([annotation isEqual:self.trackingHalo])
    {
        if ( ! self.trackingHaloLayer)
        {
            // create image marker
            //
            self.trackingHaloLayer = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"TrackingDotHalo.png"]];
            
            [CATransaction begin];
            [CATransaction setAnimationDuration:2.5];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            
            // ensure hide/show only happens on animation boundaries
            //
            [CATransaction setCompletionBlock:^(void) { self.trackingHaloLayer.hidden = (self.locationManager.location.horizontalAccuracy > 10); }];
            
            // scale out radially
            //
            CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
            
            boundsAnimation.repeatCount = MAXFLOAT;
            
            boundsAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)];
            boundsAnimation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.0, 2.0, 1.0)];
            
            boundsAnimation.removedOnCompletion = NO;
            
            boundsAnimation.fillMode = kCAFillModeForwards;

            [self.trackingHaloLayer addAnimation:boundsAnimation forKey:@"animateScale"];

            // go transparent as scaled out
            //
            CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            
            opacityAnimation.repeatCount = MAXFLOAT;
            
            opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
            opacityAnimation.toValue   = [NSNumber numberWithFloat:-1.0];
            
            opacityAnimation.removedOnCompletion = NO;
            
            opacityAnimation.fillMode = kCAFillModeForwards;

            [self.trackingHaloLayer addAnimation:opacityAnimation forKey:@"animateOpacity"];
            
            [CATransaction commit];
        }
        
        return self.trackingHaloLayer;
    }
    else if ([annotation isEqual:self.userLocation])
    {
        if ( ! self.userLocationLayer)
        {
            // create image marker
            //
            self.userLocationLayer = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"TrackingDot.png"]];
        }
        
        return self.userLocationLayer;
    }
    
    return nil;
}

@end