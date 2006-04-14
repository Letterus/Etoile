// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   client_list_menu.c for the Openbox window manager
   Copyright (c) 2003        Ben Jansens

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   See the COPYING file for a copy of the GNU General Public License.
*/

#import "AZScreen.h"
#import "AZClient.h"
#import "AZFocusManager.h"
#import "AZMenuFrame.h"
#import "AZMenuManager.h"
#import "openbox.h"
#import "AZMenu.h"
#import "action.h"
#import "config.h"

#include <glib.h>

#define MENU_NAME @"client-list-menu"

static GSList *desktop_menus;

@interface AZDesktopMenu: AZMenu
{
  unsigned int data;
}

- (id) initWithName: (NSString *) name title: (NSString *) title desktop: (unsigned int) desktop;
@end

@implementation AZDesktopMenu

- (id) initWithName: (NSString *) n title: (NSString *) t desktop: (unsigned int) d
{
  self = [super initWithName: n title: t];
  data = d;
  return self;
}

- (void) update: (AZMenuFrame *) frame 
{
    AZMenu *menu = [frame menu];
    int i;
    int j, jcount;
    BOOL icons = NO;
    BOOL empty = YES;

    [menu clearEntries];

    AZFocusManager *fManager = [AZFocusManager defaultManager];
    jcount = [fManager numberOfFocusOrderInScreen: data];
    for (j = 0, i = 0; j < jcount; j++, ++i) {
        AZClient *c = [fManager focusOrder: j inScreen: data];
        if ([c normal] && ![c skip_taskbar]) {
            GSList *acts = NULL;
            AZAction* act;
            AZNormalMenuEntry *e;
            AZClientIcon *icon;

            empty = FALSE;

            if (!icons && [c iconic]) {
                icons = TRUE;
		[menu addSeparatorMenuEntry: -1];
            }

            act = action_from_string("Activate",
                                     OB_USER_ACTION_MENU_SELECTION);
            [act data_pointer]->activate.any.c = c;
            acts = g_slist_append(acts, act);
            act = action_from_string("Desktop",
                                     OB_USER_ACTION_MENU_SELECTION);
            [act data_pointer]->desktop.desk = data;
            acts = g_slist_append(acts, act);
	    e = [menu addNormalMenuEntry: i label: ([c iconic] ? [c icon_title] : [c title]) actions: acts];

            if (config_menu_client_list_icons && 
		(icon = [c iconWithWidth: 32 height: 32])) {
                [e set_icon_width: [icon width]];
                [e set_icon_height: [icon height]];
                [e set_icon_data: [icon data]];
            }
        }
    }

    if (empty) {
        /* no entries */

        GSList *acts = NULL;
        AZAction* act;
        AZNormalMenuEntry *e;

        act = action_from_string("Desktop", OB_USER_ACTION_MENU_SELECTION);
        [act data_pointer]->desktop.desk = data;
        acts = g_slist_append(acts, act);
	e = [menu addNormalMenuEntry: 0 label: @"Go there..." actions: acts];
        if (data == [[AZScreen defaultScreen] desktop])
            [e set_enabled: NO];
    }
}

/* executes it using the client in the actions, since we set that
   when we make the actions! */
- (BOOL) execute: (AZMenuEntry *) entry state: (unsigned int) state
{
    AZAction *a;

    if ([entry isKindOfClass: [AZNormalMenuEntry class]] &&
		    [(AZNormalMenuEntry *)entry actions]) {
        a = [(AZNormalMenuEntry *)entry actions]->data;
        action_run([(AZNormalMenuEntry *)entry actions], [a data].any.c, state);
    }
    return YES;
}

- (void) dealloc
{
  desktop_menus = g_slist_remove(desktop_menus, self);
  [super dealloc];
}
@end

@interface AZClientListMenu: AZMenu
@end

@implementation AZClientListMenu

- (void) update: (AZMenuFrame *) frame 
{
    AZMenu *menu = [frame menu];
    guint i;
    GSList *it, *next;
    
    it = desktop_menus;
    AZScreen *screen = [AZScreen defaultScreen];
    for (i = 0; i < [screen numberOfDesktops]; ++i) {
        if (!it) {
            AZDesktopMenu *submenu;
	    NSString *n = [NSString stringWithFormat: @"%@-%u", MENU_NAME, i];
	    submenu = [[AZDesktopMenu alloc] initWithName: n title: [screen nameOfDesktopAtIndex: i] desktop: i];

	    [menu addSubmenuMenuEntry: i submenu: n];
	    [[AZMenuManager defaultManager] registerMenu: submenu];
	    RELEASE(submenu);

            desktop_menus = g_slist_append(desktop_menus, submenu);
        } else
            it = g_slist_next(it);
    }
    for (; it; it = next, ++i) {
        next = g_slist_next(it);
	[[AZMenuManager defaultManager] removeMenu: it->data];
        desktop_menus = g_slist_delete_link(desktop_menus, it);
	[menu removeEntryWithIdentifier: i];
    }
}
@end

void client_list_menu_startup()
{
    AZClientListMenu *menu;

    menu = [[AZClientListMenu alloc] initWithName: MENU_NAME title: @"Desktops"];
    [[AZMenuManager defaultManager] registerMenu: menu];
    DESTROY(menu);
}

