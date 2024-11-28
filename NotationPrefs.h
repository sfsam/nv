//
//  NotationPrefs.h
//  Notation
//
//  Created by Zachary Schneirov on 4/1/06.

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


#import <Cocoa/Cocoa.h>
#import "NotationController.h"

/* this class is responsible for managing all preferences specific to a notational database,
including encryption, file formats, synchronization, passwords management, and others */

#define EPOC_ITERATION 4

enum { SingleDatabaseFormat = 0, PlainTextFormat, RTFTextFormat, HTMLFormat, WordDocFormat, WordXMLFormat };

extern NSString *NotationPrefsDidChangeNotification;

@interface NotationPrefs : NSObject {
	BOOL doesEncryption, storesPasswordInKeychain, secureTextEntry;
	NSString *keychainDatabaseIdentifier;
	
	//password(s) stored in keychain or otherwise encrypted using notes password
	NSMutableDictionary *syncServiceAccounts;
	
	unsigned int hashIterationCount, keyLengthInBits;
	
	NSColor *foregroundColor;
	NSFont *baseBodyFont;
	int notesStorageFormat;
	BOOL confirmFileDeletion;
	
	unsigned int chosenExtIndices[4];
    NSMutableArray *typeStrings[4], *pathExtensions[4];
    OSType *allowedTypes;
	
	NSData *masterSalt, *dataSessionSalt, *verifierKey;
	
	NSMutableArray *seenDiskUUIDEntries;
	
	UInt32 epochIteration;
	BOOL firstTimeUsed;
	BOOL preferencesChanged;
	id delegate;
	
	@private 
	//masterKey is not to be stored anywhere
	NSData *masterKey;
}

NSMutableDictionary *ServiceAccountDictInit(NotationPrefs *prefs, NSString* serviceName);

+ (int)appVersion;
+ (NSMutableArray*)defaultTypeStringsForFormat:(int)formatID;
+ (NSMutableArray*)defaultPathExtensionsForFormat:(int)formatID;
- (BOOL)preferencesChanged;
- (void)setForegroundTextColor:(NSColor*)aColor;
- (NSColor*)foregroundColor;
- (void)setBaseBodyFont:(NSFont*)aFont;
- (NSFont*)baseBodyFont;

- (BOOL)storesPasswordInKeychain;
- (int)notesStorageFormat;
- (BOOL)confirmFileDeletion;
- (BOOL)doesEncryption;
- (NSDictionary*)syncServiceAccounts;
- (NSDictionary*)syncServiceAccountsForArchiving;
- (NSDictionary*)syncAccountForServiceName:(NSString*)serviceName;
- (NSString*)syncPasswordForServiceName:(NSString*)serviceName;
- (NSUInteger)syncFrequencyInMinutesForServiceName:(NSString*)serviceName;
- (BOOL)syncNotesShouldMergeForServiceName:(NSString*)serviceName;
- (BOOL)syncServiceIsEnabled:(NSString*)serviceName;
- (unsigned int)keyLengthInBits;
- (unsigned int)hashIterationCount;
- (UInt32)epochIteration;
- (BOOL)firstTimeUsed;
- (BOOL)secureTextEntry;

- (void)forgetKeychainIdentifier;
- (const char *)setKeychainIdentifier;
- (SecKeychainItemRef)currentKeychainItem;
- (NSData*)passwordDataFromKeychain;
- (void)removeKeychainData;
- (void)setKeychainData:(NSData*)data;

- (void)setPreferencesAreStored;
- (void)setStoresPasswordInKeychain:(BOOL)value;
- (BOOL)canLoadPassphraseData:(NSData*)passData;
- (BOOL)canLoadPassphrase:(NSString*)pass;
- (void)setPassphraseData:(NSData*)passData inKeychain:(BOOL)inKeychain;
- (void)setPassphraseData:(NSData*)passData inKeychain:(BOOL)inKeychain withIterations:(int)iterationCount;
- (BOOL)encryptDataInNewSession:(NSMutableData*)data;
- (BOOL)decryptDataWithCurrentSettings:(NSMutableData*)data;
- (NSData*)WALSessionKey;

- (void)setNotesStorageFormat:(int)formatID;
- (BOOL)shouldDisplaySheetForProposedFormat:(int)proposedFormat;
- (void)noteFilesCleanupSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)setConfirmsFileDeletion:(BOOL)value;
- (void)setDoesEncryption:(BOOL)value;
- (void)setSecureTextEntry:(BOOL)value;
- (const char*)keychainSyncAccountNameForService:(NSString*)serviceName;
- (void)setSyncUsername:(NSString*)username forService:(NSString*)serviceName;
- (void)setSyncPassword:(NSString*)password forService:(NSString*)serviceName;
- (void)setSyncFrequency:(NSUInteger)frequencyInMinutes forService:(NSString*)serviceName;
- (void)setSyncEnabled:(BOOL)isEnabled forService:(NSString*)serviceName;
- (void)setSyncShouldMerge:(BOOL)shouldMerge inCurrentAccountForService:(NSString*)serviceName;
- (void)removeSyncPasswordForService:(NSString*)serviceName;
- (void)setKeyLengthInBits:(unsigned int)newLength;

- (NSUInteger)tableIndexOfDiskUUID:(CFUUIDRef)UUIDRef;
- (void)checkForKnownRedundantSyncConduitsAtPath:(NSString*)dbPath;

+ (NSString*)pathExtensionForFormat:(int)format;

//used to view tableviews
- (NSString*)typeStringAtIndex:(int)typeIndex;
- (NSString*)pathExtensionAtIndex:(int)pathIndex;
- (unsigned int)indexOfChosenPathExtension;
- (NSString*)chosenPathExtensionForFormat:(int)format;
- (int)typeStringsCount;
- (int)pathExtensionsCount;

//used to edit tableviews
- (void)addAllowedPathExtension:(NSString*)extension;
- (BOOL)removeAllowedPathExtensionAtIndex:(unsigned int)extensionIndex;
- (BOOL)setChosenPathExtensionAtIndex:(unsigned int)extensionIndex;
- (BOOL)addAllowedType:(NSString*)type;
- (void)removeAllowedTypeAtIndex:(unsigned int)index;
- (BOOL)setExtension:(NSString*)newExtension atIndex:(unsigned int)oldIndex;
- (BOOL)setType:(NSString*)newType atIndex:(unsigned int)oldIndex;

- (BOOL)pathExtensionAllowed:(NSString*)anExtension forFormat:(int)formatID;

//actually used while searching for files
- (void)updateOSTypesArray;
- (BOOL)catalogEntryAllowed:(NoteCatalogEntry*)catEntry;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

@end

@interface NotationPrefs (DelegateMethods)

- (void)databaseEncryptionSettingsChanged;
- (void)syncSettingsChangedForService:(NSString*)serviceName;
- (void)databaseSettingsChangedFromOldFormat:(int)oldFormat;

@end
