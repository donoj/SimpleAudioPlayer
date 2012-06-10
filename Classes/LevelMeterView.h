//
//  LevelMeterView.h
//  SimpleAudioPlayer
//
//  Created by Chris Adamson on 12/23/08.
//  Copyright 2008 Subsequently and Furthermore, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


//START:code.SimpleAudioPlayer.LevelMeterView.headers
@interface LevelMeterView : UIView {
	float power;
	float peak;
	CGColorRef levelColor;
	CGColorRef peakColor;
	CGRect levelRect;
	CGRect peakRect;
}
- (void) setPower: (float) pow peak: (float) pk;
@end
//END:code.SimpleAudioPlayer.LevelMeterView.headers
