#import "MultiTextFinder.h"

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


@implementation MultiTextFinder

- (IBAction)changeEntirePhrase:(id)sender {
}
/*
- (id)init {
    if (!(self = [super init]))
		return nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidActivate:) 
												 name:NSApplicationDidBecomeActiveNotification object:NSApp];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addWillDeactivate:) 
												 name:NSApplicationWillResignActiveNotification object:NSApp];
    [self setFindString:@""];
    [self loadFindStringFromPasteboard];
    return self;
}

- (void)appDidActivate:(NSNotification *)notification {
    [self loadFindStringFromPasteboard];
}

- (void)addWillDeactivate:(NSNotification *)notification {
    [self loadFindStringToPasteboard];
}

- (void)loadFindStringFromPasteboard {
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        NSString *string = [pasteboard stringForType:NSStringPboardType];
        if (string && [string length]) {
            [self setFindString:string];
            findStringChangedSinceLastPasteboardUpdate = NO;
        }
    }
}

- (void)loadFindStringToPasteboard {
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    if (findStringChangedSinceLastPasteboardUpdate) {
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pasteboard setString:[self findString] forType:NSStringPboardType];
		findStringChangedSinceLastPasteboardUpdate = NO;
    }
}

static id sharedFindObject = nil;

+ (id)sharedInstance {
    if (!sharedFindObject) {
        sharedFindObject = [[self allocWithZone:[[NSApplication sharedApplication] zone]] init];
    }
    return sharedFindObject;
}

- (void)loadUI {
    if (!findStringField) {
        if (![NSBundle loadNibNamed:@"FindPanel" owner:self])  {
            NSLog(@"Failed to load FindPanel.nib");
            NSBeep();
        }
		if (self == sharedFindObject) [window setFrameAutosaveName:@"Find In Filtered Notes"];
    }
    [findStringField setStringValue:[self findString]];
}

- (void)dealloc {
    if (self != sharedFindObject) {
        [findString release];
        [super dealloc];
    }
}

- (NSString *)findString {
    return findString;
}

- (void)setFindString:(NSString *)string {
    if ([string isEqualToString:findString]) return;
    [findString autorelease];
    findString = [string copyWithZone:[self zone]];
    if (findStringField) {
        [findStringField setStringValue:string];
        [findStringField selectText:nil];
    }
    findStringChangedSinceLastPasteboardUpdate = YES;
}

- (NSTextView *)textObjectToSearchIn {
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (NSPanel *)findPanel {
    if (!findStringField) [self loadUI];
    return window;
}

//use -[NSArray nextRangeForString:(NSString*)string activeNote:(NoteObject*)startNote options:(unsigned)opts range:]
//The primitive for finding; this ends up setting the status field (and beeping if necessary)...
- (BOOL)find:(BOOL)direction {
    NSTextView *text = [self textObjectToSearchIn];
    lastFindWasSuccessful = NO;
    if (text) {
        NSString *textContents = [text string];
        unsigned textLength;
        if (textContents && (textLength = [textContents length])) {
            NSRange range;
            unsigned options = 0;
			if (direction == Backward) options |= NSBackwardsSearch;
            if ([ignoreCaseButton state]) options |= NSCaseInsensitiveSearch;
            //range = [textContents findString:[self findString] selectedRange:[text selectedRange] options:options wrap:YES];
            if (range.length) {
                [text setSelectedRange:range];
                [text scrollRangeToVisible:range];
                lastFindWasSuccessful = YES;
            }
        }
    }
    if (!lastFindWasSuccessful) {
        NSBeep();
        //[statusField setStringValue:NSLocalizedStringFromTable(@"Not found", @"FindPanel", @"Status displayed in find panel when the find string is not found.")];
    } else {
        //[statusField setStringValue:@""];
    }
    return lastFindWasSuccessful;
}

- (void)orderFrontFindPanel:(id)sender {
    NSPanel *panel = [self findPanel];
    [findStringField selectText:nil];
    [panel makeKeyAndOrderFront:nil];
}

// Action methods for gadgets in the find panel; these should all end up setting or clearing the status field

- (void)findNextAndOrderFindPanelOut:(id)sender {
    [nextButton performClick:nil];
    if (lastFindWasSuccessful) {
        [[self findPanel] orderOut:sender];
    } else {
		[findStringField selectText:nil];
    }
}
*/

- (void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
}
- (id)delegate {
	return delegate;
}

- (void)findNext:(id)sender {
   // if (findStringField) [self setFindString:[findStringField stringValue]];	/* findStringField should be set */
    //(void)[self find:Forward];
}

- (void)findPrevious:(id)sender {
   // if (findStringField) [self setFindString:[findStringField stringValue]];	/* findStringField should be set */
    //(void)[self find:Backward];
}

@end


@implementation NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned)options wrap:(BOOL)wrap {
	BOOL forwards = (options & NSBackwardsSearch) == 0;
	unsigned length = [self length];
	NSRange searchRange, range;
	
	if (forwards) {
		searchRange.location = NSMaxRange(selectedRange);
		searchRange.length = length - searchRange.location;
		range = [self rangeOfString:string options:options range:searchRange];
		if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
			searchRange.location = 0;
			searchRange.length = selectedRange.location;
			range = [self rangeOfString:string options:options range:searchRange];
		}
	} else {
		searchRange.location = 0;
		searchRange.length = selectedRange.location;
		range = [self rangeOfString:string options:options range:searchRange];
		if ((range.length == 0) && wrap) {
			searchRange.location = NSMaxRange(selectedRange);
			searchRange.length = length - searchRange.location;
			range = [self rangeOfString:string options:options range:searchRange];
		}
	}
	return range;
}

@end
