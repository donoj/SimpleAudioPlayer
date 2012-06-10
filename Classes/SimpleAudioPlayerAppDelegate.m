//
//  SimpleAudioPlayerAppDelegate.m
//  SimpleAudioPlayer
//
//  Created by Chris Adamson on 12/22/08.
//  Copyright Subsequently and Furthermore, Inc. 2008. All rights reserved.
//

#import "SimpleAudioPlayerAppDelegate.h"
#import "SimpleAudioPlayerViewController.h"

@implementation SimpleAudioPlayerAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
