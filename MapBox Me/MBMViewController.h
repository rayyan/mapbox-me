//
//  MBMViewController.h
//  MapBox Me
//
//  Created by Justin Miller on 3/29/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

#import "RMMapView.h"

@interface MBMViewController : UIViewController <CLLocationManagerDelegate, RMMapViewDelegate, UIGestureRecognizerDelegate>

@end