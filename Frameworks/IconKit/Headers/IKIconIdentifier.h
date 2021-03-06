/*
	IKIconIdentifier.h

	IKIconIdentifier is where various standard icons related identifiers
	are declared.

	Copyright (C) 2005 Uli Kusterer <contact@zathras.de>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Uli Kusterer <contact@zathras.de>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2005

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import <Foundation/Foundation.h>

typedef NSString *IKIconIdentifier;  // IKIconIdentifier is opaque, and not guaranteed to be an object! It's a struct on MacOS X.

// Any of these can go in anywhere an IKIconIdentifier is asked:
extern IKIconIdentifier    IKIconGenericDocument;
extern IKIconIdentifier    IKIconGenericApplication;
extern IKIconIdentifier    IKIconGenericPlugIn;
extern IKIconIdentifier    IKIconGenericFolder;
extern IKIconIdentifier    IKIconPrivateFolder;
extern IKIconIdentifier    IKIconWriteOnlyFolder;
extern IKIconIdentifier    IKIconRecyclerFolder;
extern IKIconIdentifier    IKIconRecyclerFolderFull;
// ...
extern IKIconIdentifier    IKIconLinkBadge;
extern IKIconIdentifier    IKIconLockedBadge;
extern IKIconIdentifier    IKIconScriptBadge;
extern IKIconIdentifier    IKIconReadOnlyBadge;
extern IKIconIdentifier    IKIconWriteOnlyBadge;

// System icons (not for files):
extern IKIconIdentifier    IKIconAlertNote;
extern IKIconIdentifier    IKIconAlertWarning;
extern IKIconIdentifier    IKIconAlertFailure;

