//
//  MBMViewController.m
//  MapBox Me
//
//  Created by Justin Miller on 3/29/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "MBMViewController.h"

#import "RMTileStreamSource.h"
#import "RMAnnotation.h"
#import "RMMarker.h"
#import "RMCircle.h"

@interface MBMViewController ()

@property (nonatomic, strong) IBOutlet RMMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation MBMViewController

@synthesize mapView;
@synthesize locationManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;

    self.title = @"MapBox Me";
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.116 green:0.550 blue:0.670 alpha:1.000];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                                           target:self.locationManager 
                                                                                           action:@selector(startUpdatingLocation)];
    
    self.mapView.delegate = self;
    self.mapView.tileSource = [[RMTileStreamSource alloc] initWithReferenceURL:[[NSBundle mainBundle] URLForResource:@"mapbox.mapbox-streets" withExtension:@"plist"]];
    self.mapView.decelerationMode = RMMapDecelerationFast;
    self.mapView.adjustTilesForRetinaDisplay = YES;    
    self.mapView.backgroundColor = [UIColor blackColor];
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);
    self.mapView.minZoom = 1;
    self.mapView.zoom = 2;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.locationManager startUpdatingLocation];
}

#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
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
                         
                         [self.mapView removeAllAnnotations];

                         if (manager.location.horizontalAccuracy > 10)
                         {
                             RMAnnotation *circleAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:manager.location.coordinate andTitle:nil];
                             
                             circleAnnotation.userInfo = @"circle";
                             
                             [self.mapView addAnnotation:circleAnnotation];
                         }

                         RMAnnotation *userLocation = [RMAnnotation annotationWithMapView:self.mapView coordinate:manager.location.coordinate andTitle:nil];
                         
                         userLocation.userInfo = @"user";
                         
                         [self.mapView addAnnotation:userLocation];
                     }
                     completion:nil];

    if ([newLocation distanceFromLocation:oldLocation] == 0)
        [self.locationManager stopUpdatingLocation];
}

#pragma mark -

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    if ([annotation.userInfo isEqual:@"user"])
    {
        return [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"dot.png"]];
    }
    else if ([annotation.userInfo isEqual:@"circle"])
    {
        RMCircle *circle = [[RMCircle alloc] initWithView:self.mapView radiusInMeters:self.locationManager.location.horizontalAccuracy];
        
        circle.lineColor = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.25];
        circle.fillColor = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.1];
        
        circle.lineWidthInPixels = 1.0;
        
        return circle;
    }
    
    return nil;
}

@end