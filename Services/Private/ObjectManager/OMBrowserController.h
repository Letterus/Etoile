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
#import <ObjectMerging/COEditingContext.h>
#import <ObjectMerging/COGroup.h>
#import <EtoileUI/EtoileUI.h>

/** The controller to supervise the whole ObjectManager window */
@interface OMBrowserController : ETController
{
	ETLayoutItemGroup *contentViewItem;
	ETLayoutItemGroup *sourceListItem;
	ETLayoutItem *viewPopUpItem;
	id <ETCollection> browsedGroup;
}

@property (nonatomic, retain) ETLayoutItemGroup *contentViewItem;
@property (nonatomic, retain) ETLayoutItemGroup *sourceListItem;
@property (nonatomic, retain) ETLayoutItem *viewPopUpItem;
@property (nonatomic, retain) id <ETCollection> browsedGroup;
@property (nonatomic, readonly) id selectedObject;

- (void) updatePresentedContent;

/** @taskunit Notifications */

- (void) sourceListSelectionDidChange: (NSNotification *)aNotif;

/** @taskunit Actions */

- (IBAction) doubleClick: (id)sender;
- (IBAction) changePresentationViewFromPopUp: (id)sender;
- (IBAction) search: (id)sender;
- (IBAction) open: (id)sender;
- (IBAction) openSelection: (id)sender;
- (IBAction) markVersion: (id)sender;
- (IBAction) revertTo: (id)sender;
- (IBAction) browseHistory: (id)sender;
- (IBAction) export: (id)sender;
- (IBAction) showInfos: (id)sender;

@end

/** The subcontroller to supervise the view where the source list selection 
content is presented in an ObjectManager window */
@interface OMBrowserContentController : ETController
{

}

@end