/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#ifndef GNUSTEP
#import <EtoileFoundation/GNUstep.h>
#endif
#import <CoreObject/CoreObject.h>
#import <EtoileUI/EtoileUI.h>

@class OMLayoutItemFactory;

@interface OMAppController : ETDocumentController
{
	OMLayoutItemFactory *itemFactory;
	NSMutableSet *openedGroups;
	COCustomTrack *mainUndoTrack;
}

- (IBAction) browseMainGroup: (id)sender;
- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;

@end
