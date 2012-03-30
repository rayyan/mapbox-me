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

@interface MBMViewController ()

@property (nonatomic, strong) IBOutlet RMMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) RMAnnotation *accuracyCircle;
@property (nonatomic, strong) RMAnnotation *userLocation;
@property (nonatomic, assign) BOOL updating;

- (void)startUpdating;

@end

@implementation MBMViewController

@synthesize mapView;
@synthesize locationManager;
@synthesize accuracyCircle;
@synthesize userLocation;
@synthesize updating;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;

    self.title = @"MapBox Me";
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.116 green:0.550 blue:0.670 alpha:1.000];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self startUpdating];
}

#pragma mark -

- (void)startUpdating
{
    self.updating = YES;
    
    [self.locationManager startUpdatingLocation];
}

#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.updating = YES;
    
    [UIView animateWithDuration:5.0
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveLinear
                     animations:^(void)
                     {
                         float delta = manager.location.horizontalAccuracy / 110000;
                         
                         CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(manager.location.coordinate.latitude  - delta, 
                                                                                       manager.location.coordinate.longitude - delta);

                         CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(manager.location.coordinate.latitude  + delta, 
                                                                                       manager.location.coordinate.longitude + delta);

                         
                         [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:southWest northEast:northEast animated:YES];
                         
                         if ( ! self.accuracyCircle)
                         {
                             self.accuracyCircle = [RMAnnotation annotationWithMapView:self.mapView coordinate:manager.location.coordinate andTitle:nil];

                             [self.mapView addAnnotation:self.accuracyCircle];
                         }
                         
                         self.accuracyCircle.coordinate = manager.location.coordinate;
                         
                         if ( ! self.userLocation)
                         {
                             self.userLocation = [RMAnnotation annotationWithMapView:self.mapView coordinate:manager.location.coordinate andTitle:nil];
                             
                             [self.mapView addAnnotation:self.userLocation];
                         }
                         
                         self.userLocation.coordinate = manager.location.coordinate;
                     }
                     completion:^(BOOL finished)
                     {
                         self.updating = NO;
                     }];
}

#pragma mark -

- (void)mapViewRegionDidChange:(RMMapView *)mapView
{
    if ( ! self.updating)
        [self.locationManager stopUpdatingLocation];
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    if ([annotation isEqual:self.accuracyCircle])
    {
        RMCircle *circle = [[RMCircle alloc] initWithView:self.mapView radiusInMeters:self.locationManager.location.horizontalAccuracy];
        
        circle.lineColor = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.25];
        circle.fillColor = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.1];
        
        circle.lineWidthInPixels = 1.0;
        
        // TODO: add throbber animation
        
        return circle;
    }
    else if ([annotation isEqual:self.userLocation])
    {
        return [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"TrackingDot.png"]];
    }
    
    return nil;
}

@end