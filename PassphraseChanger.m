/*Copyright (c) 2010, Zachary Schneirov. All rights reserved.
    This file is part of Notational Velocity.

    Notational Velocity is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Notational Velocity is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Notational Velocity.  If not, see <http://www.gnu.org/licenses/>. */


#import "PassphraseChanger.h"
#import "NotationPrefs.h"
#import "KeyDerivationManager.h"

@implementation PassphraseChanger

- (IBAction)cancelNewPassword:(id)sender {
	[NSApp endSheet:changePassphraseWindow returnCode:0];
	[changePassphraseWindow close];

}

- (IBAction)okNewPassword:(id)sender {
	
	
	if ([notationPrefs canLoadPassphrase:[currentPasswordField stringValue]]) {
		
		NSString *pass = [newPasswordField stringValue];
		
		if ([pass isEqualToString:[verifyChangedPasswordField stringValue]]) {
			
			[notationPrefs setPassphraseData:[pass dataUsingEncoding:NSUTF8StringEncoding] 
								  inKeychain:[rememberChangeButton state] 
							  withIterations:[keyDerivation hashIterationCount]];
						
			[NSApp endSheet:changePassphraseWindow returnCode:1];
			[changePassphraseWindow close];
			
		} else {
			NSRunAlertPanel(NSLocalizedString(@"Your entered new passphrase does not match your verification passphrase.",nil),
							NSLocalizedString(@"Please try again.",nil), NSLocalizedString(@"OK",nil), nil, nil);
			[verifyChangedPasswordField setStringValue:@""];
			[verifyChangedPasswordField performSelector:@selector(selectText:) withObject:nil afterDelay:0.0];
			[self textDidChange:nil];
		}
	} else {
		
		NSRunAlertPanel(NSLocalizedString(@"Your entered current passphrase is incorrect.",nil), 
						NSLocalizedString(@"Please try again.",nil), NSLocalizedString(@"OK",nil), nil, nil);
		[currentPasswordField setStringValue:@""];
		[currentPasswordField performSelector:@selector(selectText:) withObject:nil afterDelay:0.0];
	}
}

- (id)initWithNotationPrefs:(NotationPrefs*)prefs {
	if ([super init]) {
		notationPrefs = [prefs retain];
		
	}
	return self;
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[notationPrefs release];
	[keyDerivation release];
	
	[super dealloc];
}

- (void)awakeFromNib {
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(textDidChange:)
				   name:NSControlTextDidChangeNotification object:newPasswordField];
	[center addObserver:self selector:@selector(textDidChange:)
				   name:NSControlTextDidChangeNotification object:currentPasswordField];
	[center addObserver:self selector:@selector(textDidChange:)
				   name:NSControlTextDidChangeNotification object:verifyChangedPasswordField];	
}

- (IBAction)discloseAdvancedSettings:(id)sender {
	BOOL disclosed = [disclosureButton state];
	int heightDifference = disclosed ? 118 : -118;
	
	if (disclosed) {
		[self performSelector:@selector(setAdvancedViewHidden:) 
				   withObject:[NSNumber numberWithBool:NO] afterDelay:0.0];
	} else {
		[advancedView setHidden:YES];
	}
	
	NSPoint origin = [changePassphraseWindow frame].origin;
	NSRect newFrame = NSMakeRect(origin.x, origin.y - heightDifference, [changePassphraseWindow frame].size.width, 
								 [changePassphraseWindow frame].size.height + heightDifference);
	[changePassphraseWindow setFrame:newFrame display:YES animate:YES];
}

- (void)setAdvancedViewHidden:(NSNumber*)value {
	[advancedView setHidden:[value boolValue]];
}

- (void)showAroundWindow:(NSWindow*)window {
	if (!changePassphraseWindow) {
		if (![NSBundle loadNibNamed:@"PassphraseChanger" owner:self])  {
			NSLog(@"Failed to load PassphraseChanger.nib");
			NSBeep();
			return;
		}
	}
	
	if (!keyDerivation) {
		keyDerivation = [[KeyDerivationManager alloc] initWithNotationPrefs:notationPrefs];
		[advancedView addSubview:[keyDerivation view]];
	}	
		
	[newPasswordField setStringValue:@""];
	[verifyChangedPasswordField setStringValue:@""];
	[currentPasswordField setStringValue:@""];
	
	[rememberChangeButton setState:[notationPrefs storesPasswordInKeychain]];
	[currentPasswordField selectText:nil];
	
	[okChangeButton setEnabled:NO];
		
	[NSApp beginSheet:changePassphraseWindow modalForWindow:window modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[newPasswordField setStringValue:@""];
	[verifyChangedPasswordField setStringValue:@""];
	[currentPasswordField setStringValue:@""];
}

- (void)textDidChange:(NSNotification *)aNotification {
	[okChangeButton setEnabled:(([[newPasswordField stringValue] length] > 0) && 
								([[verifyChangedPasswordField stringValue] length] > 0) &&
								([[currentPasswordField stringValue] length] > 0))];
}


@end
