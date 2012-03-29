//
//  MBMAppDelegate.m
//  MapBox Me
//
//  Created by Justin Miller on 3/29/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "MBMAppDelegate.h"

#import "MBMViewController.h"

@implementation MBMAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UINavigationController *wrapper = [[UINavigationController alloc] initWithRootViewController:[[MBMViewController alloc] initWithNibName:@"MBMViewController" bundle:nil]];
    
    self.window.rootViewController = wrapper;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end