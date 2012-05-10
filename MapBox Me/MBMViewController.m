//
//  MBMViewController.m
//  MapBox Me
//
//  Created by Justin Miller on 3/29/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "MBMViewController.h"

#import "RMMapView.h"
#import "RMMapBoxSource.h"

#define kMapBoxMeNormalTintColor [UIColor colorWithRed:0.120 green:0.650 blue:0.750 alpha:1.000]
#define kMapBoxMeActiveTintColor [UIColor colorWithRed:0.120 green:0.550 blue:0.670 alpha:1.000]

@interface MBMViewController ()

@property (nonatomic, strong) IBOutlet RMMapView *mapView;

- (void)startTrackingLocation;
- (void)startTrackingHeading;
- (void)stopTracking;

@end

@implementation MBMViewController

@synthesize mapView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

    self.mapView.userTrackingMode = RMUserTrackingModeFollow;
}

- (void)startTrackingHeading
{
    self.navigationItem.rightBarButtonItem.image     = [UIImage imageNamed:@"TrackingHeading.png"];
    self.navigationItem.rightBarButtonItem.tintColor = kMapBoxMeActiveTintColor;
    self.navigationItem.rightBarButtonItem.action    = @selector(stopTracking);
    
    self.mapView.userTrackingMode = RMUserTrackingModeFollowWithHeading;
}

- (void)stopTracking
{
    self.navigationItem.rightBarButtonItem.image     = [UIImage imageNamed:@"TrackingLocation.png"];
    self.navigationItem.rightBarButtonItem.tintColor = kMapBoxMeNormalTintColor;
    self.navigationItem.rightBarButtonItem.action    = @selector(startTrackingLocation);

    self.mapView.userTrackingMode = RMUserTrackingModeNone;    
}

#pragma mark -

- (void)mapView:(RMMapView *)mapView didChangeUserTrackingMode:(RMUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == RMUserTrackingModeNone)
        [self stopTracking];
}

@end