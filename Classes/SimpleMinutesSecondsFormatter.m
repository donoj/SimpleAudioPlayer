//
//  SimpleMinutesSecondsFormatter.m
//  SimpleAudioPlayer
//
//  Created by Chris Adamson on 12/22/08.
//  Copyright 2008 Subsequently and Furthermore, Inc.. All rights reserved.
//

#import "SimpleMinutesSecondsFormatter.h"


@implementation SimpleMinutesSecondsFormatter


//START:code.SimpleAudioPlayer.SimpleMinutesSecondsFormatter.stringforobjectvalue
- (NSString *)stringForObjectValue:(id)anObject{
	if (! [anObject isKindOfClass: [NSNumber class]]) {
		return nil;
	}
	NSNumber *secondsNumber = (NSNumber*) anObject;
	int seconds = [secondsNumber intValue];
	int minutesPart = seconds / 60;
	int secondsPart = seconds % 60;
	NSString *minutesString = (minutesPart < 10) ?
		[NSString stringWithFormat:@"0%d", minutesPart] :
		[NSString stringWithFormat:@"%d", minutesPart];
	NSString *secondsString = (secondsPart < 10) ?
		[NSString stringWithFormat:@"0%d", secondsPart] :
		[NSString stringWithFormat:@"%d", secondsPart];
	return [NSString stringWithFormat:@"%@:%@", minutesString, secondsString];
}
//END:code.SimpleAudioPlayer.SimpleMinutesSecondsFormatter.stringforobjectvalue


@end
