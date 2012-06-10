//
//  SimpleAudioPlayerAppDelegate.h
//  SimpleAudioPlayer
//
//  Created by Chris Adamson on 12/22/08.
//  Copyright Subsequently and Furthermore, Inc. 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SimpleAudioPlayerViewController;

@interface SimpleAudioPlayerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SimpleAudioPlayerViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SimpleAudioPlayerViewController *viewController;

@end

