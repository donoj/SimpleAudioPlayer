//
//  SimpleAudioPlayerViewController.m
//  SimpleAudioPlayer
//
//  Created by Chris Adamson on 12/22/08.
//  Copyright Subsequently and Furthermore, Inc. 2008. All rights reserved.
//

#import "SimpleAudioPlayerViewController.h"

@implementation SimpleAudioPlayerViewController

@synthesize songNameLabel, currentTimeLabel, startTimeLabel, endTimeLabel, 
			playPauseButton, loopButton, scrubSlider, volumeSlider,
			leftLevelView, rightLevelView, leftLevelViewLabel, rightLevelViewLabel;

@synthesize audioPlayer;




/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// note: it would be nicer if the controller had a BOOL wasInterrupted
// that would be checked in the kAudioSessionEndInterruption case.  in
// this simplistic version, you could be paused, get a call, decline it,
// and the app would *start* playing.

// C function for handling interruptions
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleinterruptionhandler
void simpleInterruptionHandler (
		void     *inUserData,
		UInt32   inInterruptionState) {
	// callback object was created as "self", so we know it's
	// a (actually, "the") view controller
	SimpleAudioPlayerViewController *sapvh =
		(SimpleAudioPlayerViewController*) inUserData;
	if (inInterruptionState == kAudioSessionBeginInterruption) {
		[sapvh pausePlaying];
	} else if (inInterruptionState == kAudioSessionEndInterruption) {
		[sapvh startPlaying];
	}
}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleinterruptionhandler


//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handleroutechange
void simpleRouteChangeHandler ( 
		   void *inUserData,
		   AudioSessionPropertyID inPropertyID,
		   UInt32 inPropertyValueSize,
		   const void *inPropertyValue
) { 
	SimpleAudioPlayerViewController *sapvh = //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.castuserdata"/>
		(SimpleAudioPlayerViewController*) inUserData;
	// route changes send a CFDictionaryRef describing the change
	NSDictionary *routeChangeDict = (NSDictionary*) inPropertyValue; //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.getdictionary"/>
	NSNumber *routeChangeReason = //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.getreasonstart"/>
		[routeChangeDict objectForKey:
		(NSString*) CFSTR(kAudioSession_AudioRouteChangeKey_Reason)]; //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.getreasonend"/>
	if ([routeChangeReason intValue] == //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.checkreasonstart"/>
			kAudioSessionRouteChangeReason_OldDeviceUnavailable) { //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.checkreasonend"/>
		[sapvh pausePlaying]; //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.pauseplaying"/>
		NSString *removedDeviceName = //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.getremoveddevicenamestart"/>
			[routeChangeDict objectForKey: (NSString*)
				CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute)]; //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simpleroutechangehandler.getremoveddevicenameend"/>
		NSString *removalMessage =
			[NSString stringWithFormat:@"%@ removed. Pausing.",
				removedDeviceName];
		UIAlertView *deviceRemovedAlert = [[UIAlertView alloc]
				initWithTitle:@"Device removed"
				message: removalMessage
				delegate:NULL
				cancelButtonTitle:@"OK"
				otherButtonTitles: NULL];
		[deviceRemovedAlert show];
		[deviceRemovedAlert release];
	}
}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handleroutechange


-(void) setupAudioSession {
	// initialize audio session
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.audiosessioninitialize
	AudioSessionInitialize
		(NULL, // default run loop
		 NULL, // default run loop mode
		 simpleInterruptionHandler, // interruption callback
		 self); // client callback data
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.audiosessioninitialize
	
	// set the audio category
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setaudiosessioncategory
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty 
		(kAudioSessionProperty_AudioCategory,
		 sizeof (sessionCategory),
		 &sessionCategory 
	 ); 
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setaudiosessioncategory

	// request callbacks when route changes (eg, headphones attached)
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setroutechangelistener
	AudioSessionAddPropertyListener 
		(kAudioSessionProperty_AudioRouteChange, // which property
		 simpleRouteChangeHandler, // callback function
		 self); // client callback data
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setroutechangelistener
}

/* todo - see if user data can get at aac/m4a metadata
	// debug - look at user data
	UInt32 item4CC = 'trkn';
	UInt32 itemCount = 0;
	err = AudioFileCountUserData
		(audioFile,
		 item4CC,
		 &itemCount);
	if (err == noErr)  {
		NSLog (@"Got %d user data items");
	} else {
		CFErrorRef error = CFErrorCreate(NULL, kCFErrorDomainOSStatus, err, NULL);
		NSLog (@"Error: %@", error);
		CFRelease (error);
	}
*/

// returns an nsdictionary of file metadata, via kAudioFilePropertyInfoDictionary property
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl
-(NSDictionary*) getMetadataForAudioURL: (NSURL *) audioFileURL {
	OSStatus err = noErr;
	AudioFileID audioFile;
	err = AudioFileOpenURL //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl.openurlstart"/>
			((CFURLRef) audioFileURL,
			 kAudioFileReadPermission, 
			 0, // no hint
			 &audioFile); //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl.openurlend"/>
	if (err != noErr) {
		NSLog (@"open url error %d", err);
		return NULL;
	}	
	UInt32 size;
	// get size of metadata dictionary
	err = AudioFileGetPropertyInfo //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl.getpropertyinfostart"/>
			(audioFile,
			 kAudioFilePropertyInfoDictionary,
			 &size,
			 NULL); //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl.getpropertyinfoend"/>
	if (err != noErr) {
		NSLog (@"size check error %d", err);
		return NULL;
	} 
	// allocate a buffer of appropriate size
	NSMutableDictionary* metadataDictionary;
	err = AudioFileGetProperty //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl.getpropertystart"/>
			(audioFile,
			 kAudioFilePropertyInfoDictionary,
			 &size, 
			 &metadataDictionary); //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl.getpropertyend"/>
	if (err != noErr) {
		NSLog (@"get property error %d", err);
		return NULL;
	}
	AudioFileClose (audioFile); //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl.audiofilclose"/>
	return [metadataDictionary autorelease];
}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.getmetadataforaudiourl

-(void) updateAudioDisplay {
	// set time label
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setcurrenttimelabel
	currentTimeLabel.text = [minutesSecondsFormatter stringForObjectValue: 
		[NSNumber numberWithInt: audioPlayer.currentTime]];
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setcurrenttimelabel
	// set scrubber position only if user is not scrubbing
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setscrubbervalue
	if (! userIsScrubbing) {
		NSTimeInterval percentDone =
			audioPlayer.currentTime / audioPlayer.duration;
		scrubSlider.value = percentDone;
	}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setscrubbervalue
	
	// set level meters
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setlevelmeters
	[audioPlayer updateMeters];
	[leftLevelView setPower: [audioPlayer averagePowerForChannel:0]
		 peak: [audioPlayer peakPowerForChannel: 0]];
	if ([audioPlayer numberOfChannels] > 0) {
		[rightLevelView setPower: [audioPlayer averagePowerForChannel:1]
			peak: [audioPlayer peakPowerForChannel: 1]];
	}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setlevelmeters
}


/* this simpler viewDidLoad is cited in the book before we add session and metadata code
- (void)viewDidLoad {
    [super viewDidLoad];
	
	minutesSecondsFormatter = [[SimpleMinutesSecondsFormatter alloc] init];
	
	[self setupAudioSession];
	
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simplesetupaudioplayer
	@try { //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simplesetupaudioplayer.try"/>
		NSString *audioFilePath =
			[[NSBundle mainBundle] pathForResource:@"audio" ofType: @"mp3"];
		if (! audioFilePath)
			[NSException raise:@"No audio path" //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simplesetupaudioplayer.nopathexception"/>
					format:@"No path to audio file"];
		songNameLabel.text = [audioFilePath lastPathComponent];
		NSURL *audioFileURL = [NSURL fileURLWithPath: audioFilePath];
		NSError *audioPlayerError = nil;
		audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL
			error:&audioPlayerError];
		if (! audioPlayer)
			[NSException raise:@"No player"
					format:@"Couldn't create audio player: %@",
					[audioPlayerError localizedDescription]];
		[audioPlayer prepareToPlay];		
	}
	@catch (NSException* exception) { //<label id="code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simplesetupaudioplayer.catch"/>
		NSLog (@"exception: %@", exception);
		playPauseButton.enabled = NO;
		UIAlertView *cantPlayAlert =
		[[UIAlertView alloc] initWithTitle:@"Cannot Play:"
				message:[exception reason]
				delegate:nil
				cancelButtonTitle:@"OK"
				otherButtonTitles:nil];
		[cantPlayAlert show];
		[cantPlayAlert release];
	}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.simplesetupaudioplayer
	
	// set up display updater
	NSInvocation *updateAudioDisplayInvocation =
	[NSInvocation invocationWithMethodSignature:
		[self methodSignatureForSelector: @selector (updateAudioDisplay)]];
	[updateAudioDisplayInvocation setSelector: @selector (updateAudioDisplay)];
	[updateAudioDisplayInvocation setTarget: self];
	audioDisplayUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
														   invocation:updateAudioDisplayInvocation repeats:YES];
}
 */


/*
 */
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	minutesSecondsFormatter = [[SimpleMinutesSecondsFormatter alloc] init];

	[self setupAudioSession];

	@try {
		NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"audio"
																  ofType: @"mp3"];

		if (! audioFilePath)
			[NSException raise:@"No audio path" format:@"No path to audio file"];
		
		NSURL *audioFileURL = [NSURL fileURLWithPath: audioFilePath];

		// get audio metadata and reset title if possible
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setsongnamelabel
		NSDictionary *metadataDict = [self getMetadataForAudioURL: audioFileURL];
		NSLog (@"metadata: %@", metadataDict);
		NSString *artistMetadata = [metadataDict objectForKey:@"artist"];
		NSString *titleMetadata = [metadataDict objectForKey:@"title"];
		if ( (artistMetadata != NULL) && (titleMetadata != NULL))
			songNameLabel.text = [NSString stringWithFormat:@"%@: %@",
					artistMetadata, titleMetadata];
		else
			songNameLabel.text = [audioFilePath lastPathComponent];
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setsongnamelabel

		NSError *audioPlayerError = nil;
		audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL
											error:&audioPlayerError];
		if (! audioPlayer)
			[NSException raise:@"No player" format:@"Couldn't create audio player: %@",
				[audioPlayerError localizedDescription]];
	 
		// if we got this far, successful enough to set duration
		// labels and do other initialization. also check
		// to see if we're stereo or mono
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setdurationlabel
		endTimeLabel.text = [minutesSecondsFormatter stringForObjectValue: 
						 [NSNumber numberWithInt: audioPlayer.duration]];
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setdurationlabel
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlemono
		if (audioPlayer.numberOfChannels == 1) {
			// disable right level meter and make the left "M"ono
			rightLevelView.hidden = YES;
			rightLevelViewLabel.hidden = YES;
			leftLevelViewLabel.text = @"M";
		}
		audioPlayer.meteringEnabled = YES;
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlemono
		userIsScrubbing = NO;
		audioPlayer.volume = volumeSlider.value;
		[self updateAudioDisplay];
		[audioPlayer prepareToPlay];
	
	}
	@catch (NSException* exception){
		NSLog (@"exception: %@", exception);
		playPauseButton.enabled = NO;
		UIAlertView *cantPlayAlert =
			[[UIAlertView alloc] initWithTitle:@"Cannot Play:"
								message:[exception reason]
								delegate:nil
								cancelButtonTitle:@"OK"
								otherButtonTitles:nil];
		[cantPlayAlert show];
		[cantPlayAlert release];
	}

	// set up display updater
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setuptimer
	NSInvocation *updateAudioDisplayInvocation =
	[NSInvocation invocationWithMethodSignature:
		[self methodSignatureForSelector: @selector (updateAudioDisplay)]];
	[updateAudioDisplayInvocation setSelector: @selector (updateAudioDisplay)];
	[updateAudioDisplayInvocation setTarget: self];
	audioDisplayUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
		invocation:updateAudioDisplayInvocation repeats:YES];
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.setuptimer
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


/*
// these are the versions described in the book before adding the
// audio session code
//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.startstopnosession
-(void) startPlaying {
	[audioPlayer play];
	playPauseButton.selected = YES;
}

-(void) pausePlaying {
	[audioPlayer pause];
	playPauseButton.selected = NO;
}

 
-(IBAction) handlePlayPauseTapped: (id) sender {
	if (audioPlayer.playing) {
		[self pausePlaying];
	} else {
		[self startPlaying];
	}
}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.startstopnosession
 */



-(void) startPlaying {
	[audioPlayer play];
	AudioSessionSetActive (true);
	playPauseButton.selected = YES;
}

-(void) pausePlaying {
	[audioPlayer pause];
	AudioSessionSetActive (false);
	playPauseButton.selected = NO;
}

-(IBAction) handlePlayPauseTapped: (id) sender {
	if (audioPlayer.playing) {
		[self pausePlaying];
	} else {
		[self startPlaying];
	}
}


//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlelooptapped
-(IBAction) handleLoopTapped: (id)sender {
	if (audioPlayer.numberOfLoops == 0) {
		audioPlayer.numberOfLoops = -1;
		loopButton.selected = YES;
	} else {
		audioPlayer.numberOfLoops = 0;
		loopButton.selected = NO;
	}
}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlelooptapped

//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlescrub
-(IBAction) handleScrub: (id) sender {
	audioPlayer.currentTime = scrubSlider.value * audioPlayer.duration;
	userIsScrubbing = NO;
}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlescrub

//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlevolumechange
-(IBAction) handleVolumeChange: (id) sender {
	audioPlayer.volume = volumeSlider.value;
}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlevolumechange


//START:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlescrubbertouchdown
-(IBAction) handleScrubberTouchDown: (id) sender {
	userIsScrubbing = YES;
}
//END:code.SimpleAudioPlayer.SimpleAudioPlayerViewController.handlescrubbertouchdown


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}

@end
