/*
 *  $Id$
 *
 *  Copyright (C) 2007 Stephen F. Booth <me@sbooth.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "SaveAUPresetSheet.h"

@implementation SaveAUPresetSheet

- (id) init
{
	if((self = [super init])) {
		BOOL result = [NSBundle loadNibNamed:@"SaveAUPresetSheet" owner:self];
		if(NO == result) {
			NSLog(@"Missing resource: \"SaveAUPresetSheet.nib\".");
			[self release];
			return nil;
		}		
	}
	return self;
}

- (void) dealloc
{
	[_presetName release], _presetName = nil;
	
	[super dealloc];
}

- (NSWindow *) sheet
{
	return [[_sheet retain] autorelease];
}

- (IBAction) ok:(id)sender
{
    [[NSApplication sharedApplication] endSheet:[self sheet] returnCode:NSOKButton];
}

- (IBAction) cancel:(id)sender
{
    [[NSApplication sharedApplication] endSheet:[self sheet] returnCode:NSCancelButton];
}

- (NSString *) presetName
{
	return [[_presetName retain] autorelease];
}

- (void) setPresetName:(NSString *)presetName
{
	[_presetName release];
	_presetName = [presetName copy];
}

- (int) presetDomain
{
	return _presetDomain;
}

- (void) setPresetDomain:(int)presetDomain
{
	_presetDomain = presetDomain;
}

@end
