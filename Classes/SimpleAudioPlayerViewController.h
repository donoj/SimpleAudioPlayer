//
//  SimpleAudioPlayerViewController.h
//  SimpleAudioPlayer
//
//  Created by Chris Adamson on 12/22/08.
//  Copyright Subsequently and Furthermore, Inc. 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SimpleMinutesSecondsFormatter.h"
#import "LevelMeterView.h"

@interface SimpleAudioPlayerViewController : UIViewController {
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.iboutlets
	IBOutlet UILabel* songNameLabel;
	IBOutlet UILabel* currentTimeLabel;
	IBOutlet UILabel* startTimeLabel;
	IBOutlet UILabel* endTimeLabel;
	IBOutlet UIButton* playPauseButton;
	IBOutlet UIButton* loopButton;
	IBOutlet UISlider* scrubSlider;
	IBOutlet UISlider* volumeSlider;
	IBOutlet LevelMeterView* leftLevelView;
	IBOutlet LevelMeterView* rightLevelView;
	IBOutlet UILabel* leftLevelViewLabel;
	IBOutlet UILabel* rightLevelViewLabel;
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.iboutlets

	AVAudioPlayer *audioPlayer;
	SimpleMinutesSecondsFormatter *minutesSecondsFormatter;
	NSTimer *audioDisplayUpdateTimer;

	BOOL userIsScrubbing;
}

@property (nonatomic, retain) UILabel* songNameLabel;
@property (nonatomic, retain) UILabel* currentTimeLabel;
@property (nonatomic, retain) UILabel* startTimeLabel;
@property (nonatomic, retain) UILabel* endTimeLabel;
@property (nonatomic, retain) UIButton* playPauseButton;
@property (nonatomic, retain) UIButton* loopButton;
@property (nonatomic, retain) UISlider* scrubSlider;
@property (nonatomic, retain) UISlider* volumeSlider;
@property (nonatomic, retain) UIView* leftLevelView;
@property (nonatomic, retain) UIView* rightLevelView;
@property (nonatomic, retain) UILabel* leftLevelViewLabel;
@property (nonatomic, retain) UILabel* rightLevelViewLabel;

@property (nonatomic, retain) AVAudioPlayer* audioPlayer;

//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.methoddeclarations
-(IBAction) handlePlayPauseTapped: (id) sender;
-(IBAction) handleLoopTapped: (id)sender;
-(IBAction) handleScrubberTouchDown: (id) sender;
-(IBAction) handleScrub: (id) sender;
-(IBAction) handleVolumeChange: (id) sender;

-(void) updateAudioDisplay;
-(void) startPlaying;
-(void) pausePlaying;
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.methoddeclarations

@end

