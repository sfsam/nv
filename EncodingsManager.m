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


#import "EncodingsManager.h"
#import "NoteObject.h"
#import "NotationFileManager.h"
#import "NSData_transformations.h"
#import "NSString_NV.h"

@implementation EncodingsManager

static const NSStringEncoding AllowedEncodings[] = {
	/* Western */
	NSISOLatin1StringEncoding,			// ISO Latin 1
	(NSStringEncoding) 0x80000203,		// ISO Latin 3
	(NSStringEncoding) 0x8000020F,		// ISO Latin 9
	NSMacOSRomanStringEncoding,			// Mac
	NSWindowsCP1252StringEncoding,		// Windows
	/* Baltic */
	(NSStringEncoding) -1,
	(NSStringEncoding) 0x8000020D,		// ISO Latin 7
	(NSStringEncoding) 0x80000507,		// Windows
	/* Central European */
	(NSStringEncoding) -1,
	NSISOLatin2StringEncoding,			// ISO Latin 2
	(NSStringEncoding) 0x80000204,		// ISO Latin 4
	(NSStringEncoding) 0x8000001D,		// Mac
	NSWindowsCP1250StringEncoding,		// Windows
	/* Cyrillic */
	(NSStringEncoding) -1,
	(NSStringEncoding) 0x80000A02,		// KOI8-R
	(NSStringEncoding) 0x80000205,		// ISO Latin 5
	(NSStringEncoding) 0x80000007,		// Mac
	NSWindowsCP1251StringEncoding,		// Windows
	/* Japanese */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000A01,		// ShiftJIS
	NSISO2022JPStringEncoding,			// ISO-2022-JP
	NSJapaneseEUCStringEncoding,		// EUC
	(NSStringEncoding) 0x80000001,		// Mac
	NSShiftJISStringEncoding,			// Windows
	/* Simplified Chinese */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000632,		// GB 18030
	(NSStringEncoding) 0x80000631,		// GBK
	(NSStringEncoding) 0x80000930,		// EUC
	(NSStringEncoding) 0x80000019,		// Mac
	(NSStringEncoding) 0x80000421,		// Windows
	/* Traditional Chinese */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000A03,		// Big5
	(NSStringEncoding) 0x80000A06,		// Big5 HKSCS
	(NSStringEncoding) 0x80000931,		// EUC
	(NSStringEncoding) 0x80000002,		// Mac
	(NSStringEncoding) 0x80000423,		// Windows
	/* Korean */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000940,		// EUC
	(NSStringEncoding) 0x80000003,		// Mac
	(NSStringEncoding) 0x80000422,		// Windows
	/* Hebrew */
	(NSStringEncoding) -1,				// Divider
	(NSStringEncoding) 0x80000208,		// ISO-8859-8
	(NSStringEncoding) 0x80000005,		// Mac
	(NSStringEncoding) 0x80000505,		// Windows
	/* End */ 0 };


+ (EncodingsManager *)sharedManager {
	static EncodingsManager *man = nil;
	if (!man)
		man = [[EncodingsManager alloc] init];
	return man;
}

- (BOOL)checkUnicode {
	
	if (NSUnicodeStringEncoding == currentEncoding || NSUTF8StringEncoding == currentEncoding) {
		
		NSString * alertTitleString = NSLocalizedString(@"quotemark%@quotemark is a Unicode file and not directly interpretable using plain text encodings.", 
													   @"alert title when converting from unicode");
		if (NSRunAlertPanel([NSString stringWithFormat:alertTitleString, filenameOfNote(note)],	
							NSLocalizedString(@"If you wish to convert it, you must open and re-save the file in an external editor.", "alert description when converting from unicode"), 
							NSLocalizedString(@"OK", nil), NSLocalizedString(@"Open in TextEdit", @"title of button for opening the current note in text edit"), NULL) != NSAlertDefaultReturn) {

			NSString *textEditPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.TextEdit"];
			if (textEditPath) {
				NSString *resolvedPath = [note noteFilePath];
				if (!resolvedPath) {
					NSRunAlertPanel(NSLocalizedString(@"Could not locate the note file.", nil), NSLocalizedString(@"Does it still exist?", nil), 
									NSLocalizedString(@"I'll Go See", @"... if it exists"), NULL, NULL);
				} else {
					[[NSWorkspace sharedWorkspace] openFile:resolvedPath withApplication:textEditPath];
				}
			} else {
				NSRunAlertPanel(NSLocalizedString(@"Could not find the application TextEdit.", nil), NSLocalizedString(@"You may need to re-run the Mac OS X installer.",nil), NSLocalizedString(@"OK", nil), NULL, NULL);
			}
		}

		return YES;
	}
	
	return NO;
}

- (void)showPanelForNote:(NoteObject*)aNote {
	currentEncoding = fileEncodingOfNote(aNote);
	
	[note release];
	note = [aNote retain];
	
	bzero(&fsRef, sizeof(FSRef));
	
	[noteData release];
	if (!(noteData = [[[note delegate] dataFromFileInNotesDirectory:&fsRef forFilename:filenameOfNote(note)] retain])) {
		NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"Error: unable to read the contents of the file quotemark%@.quotemark",nil), filenameOfNote(aNote)], 
						NSLocalizedString(@"The file may no longer exist or has incorrect permissions.",nil), NSLocalizedString(@"OK",nil), NULL, NULL);
		return;
	}
	
	if (![self checkUnicode]) {
		
		if (!window) {
			if (![NSBundle loadNibNamed:@"EncodingsManager" owner:self])  {
				NSLog(@"Failed to load EncodingsManager.nib");
				NSBeep();
				return;
			}
		}
		
		[helpStringField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Notational Velocity should assume the file quotemark%@quotemark was saved with the encoding:",nil), filenameOfNote(note)]];
		[encodingsPopUpButton setMenu:[self textConversionsMenu]];
		
		//setup panel for given note
		if ([self tryToUpdateTextForEncoding:currentEncoding]) {
			[NSApp beginSheet:window modalForWindow:[[NSApp delegate] window] modalDelegate:self 
			   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		} else {
			//this shouldn't happen
		}
	}
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	[note release];
	note = nil;
}


- (NSMenu*)textConversionsMenu {
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSMenuItem *menuItem = nil;
	unsigned int i = 0;
	
	for (i = 0; AllowedEncodings[i]; i++) {
		NSStringEncoding thisEncoding = AllowedEncodings[i];
		
		if (thisEncoding == (NSStringEncoding) -1) {
			[menu addItem:[NSMenuItem separatorItem]];
			continue;
		}
		
		menuItem = [[[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:thisEncoding] 
											   action:@selector(setFileEncodingFromMenu:) keyEquivalent:@""] autorelease];
		if (currentEncoding == thisEncoding)
			[menuItem setState:NSOnState];
		
		NSString *noteString = (NSString*)CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, (CFDataRef)noteData, 
																				   CFStringConvertNSStringEncodingToEncoding(thisEncoding));
		//make sure that the conversion works both ways
		[menuItem setEnabled:(noteString != nil && [noteString canBeConvertedToEncoding:thisEncoding])];
		[noteString release];
		
		[menuItem setTag:(int)thisEncoding];
		[menuItem setTarget:self];
		[menu addItem:menuItem];
	}
	
	[menu setAutoenablesItems:NO];
	
	return menu;
}


- (void)setFileEncodingFromMenu:(id)sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
				
		NSStringEncoding newEncoding = (unsigned)[sender tag];
		
		//preview conversion in text view
		if (![self tryToUpdateTextForEncoding:newEncoding]) {
			
			//set it back to the current encoding--this one doesn't work
			[encodingsPopUpButton selectItemWithTag:(int)currentEncoding];
		}		
	} else {  
		NSLog(@"Unknown class sent msg to change encoding: %@", [sender description]);
	}
}

- (BOOL)tryToUpdateTextForEncoding:(NSStringEncoding)encoding {
	
	NSString *stringFromData = (NSString*)CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, (CFDataRef)noteData, CFStringConvertNSStringEncodingToEncoding(encoding));
	
	if (stringFromData) {
		NSAttributedString *attributedStringFromData = [[NSAttributedString alloc] initWithString:stringFromData];
		NSTextStorage *storage = [textView textStorage];
		[storage setAttributedString:attributedStringFromData];
		
		[stringFromData release];
		[attributedStringFromData release];
		
		currentEncoding = encoding;
		
		[encodingsPopUpButton selectItemWithTag:(int)currentEncoding];
		
		return YES;
	} else {
		NSRunAlertPanel([NSString stringWithFormat:@"%@ is not a valid encoding for this text file.", 
			[NSString localizedNameOfStringEncoding:encoding]], NSLocalizedString(@"Please try another encoding.", @"prompt for choosing an incompatible text encoding"), 
						NSLocalizedString(@"OK",nil), NULL, NULL);
	}
	
	
	return NO;
}

- (IBAction)cancelAction:(id)sender {
	[NSApp endSheet:window returnCode:0];
	[window close];
}

- (IBAction)chooseEncoding:(id)sender {
}

- (BOOL)shouldUpdateNoteFromDisk {
	FSCatalogInfo info;
	OSStatus err = noErr;
	if ((err = [[note delegate] fileInNotesDirectory:&fsRef isOwnedByUs:NULL hasCatalogInfo:&info]) != noErr) {
		NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"Error: the modification date of the file quotemark%@quotemark could not be determined because %@",nil), 
			filenameOfNote(note), [NSString reasonStringFromCarbonFSError:err]], NSLocalizedString(@"The file may no longer exist or has incorrect permissions.",nil), 
						NSLocalizedString(@"OK",nil), NULL, NULL);
		return NO;
	}
	
	UTCDateTime fileModifiedDate = fileModifiedDateOfNote(note);
	CFAbsoluteTime timeOnDisk, lastTime;
    if ((err = (UCConvertUTCDateTimeToCFAbsoluteTime(&fileModifiedDate, &lastTime) == noErr)) &&
		(err = (UCConvertUTCDateTimeToCFAbsoluteTime(&info.contentModDate, &timeOnDisk) == noErr))) {
		
		if (lastTime > timeOnDisk) {
			int result = NSRunCriticalAlertPanel([NSString stringWithFormat:NSLocalizedString(@"The note quotemark%@quotemark is newer than its file on disk.",nil), titleOfNote(note)], 
												 NSLocalizedString(@"If you update this note with re-interpreted data from the file, you may overwrite your changes.",nil), 
												 NSLocalizedString(@"Don't Update", @"don't update the note from its file on disk"), 
												 NSLocalizedString(@"Overwrite Note", @"...from file on disk"), NULL);
			if (result == NSAlertDefaultReturn) {
				NSLog(@"not updating");
				return NO;
			} else {
				NSLog(@"user wants to update");
			}
		}
    } else {
		NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"Error: the modification date of the file quotemark%@quotemark could not be compared because %@",nil), 
			filenameOfNote(note), [NSString reasonStringFromCarbonFSError:err]], NSLocalizedString(@"This may be due to an error in the program or operating system.",nil), 
						NSLocalizedString(@"OK",nil), NULL, NULL);
		return NO;
    }
	
	return YES;
}

- (IBAction)okAction:(id)sender {
	
	//check whether file mod. date of note is older than mod. date on disk
	if ([self shouldUpdateNoteFromDisk]) {
		[note setFileEncodingAndReinterpret:currentEncoding];
		[[NSApp delegate] contentsUpdatedForNote:note];
	}
	
	[NSApp endSheet:window returnCode:1];
	[window close];
}

@end
