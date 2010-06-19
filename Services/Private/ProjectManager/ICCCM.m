/**
 * Étoilé ProjectManager - ICCCM.m
 *
 * Copyright (C) 2010 Christopher Armstrong
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import "ICCCM.h"

NSString* ICCCMWMName = @"WM_NAME";
NSString* ICCCMWMIconName = @"WM_ICON_NAME";
NSString* ICCCMWMNormalHints = @"WM_NORMAL_HINTS";
NSString* ICCCMWMSizeHints = @"WM_SIZE_HINTS";
NSString* ICCCMWMHints = @"WM_HINTS";
NSString* ICCCMWMClass = @"WM_CLASS";
NSString* ICCCMWMTransientFor = @"WM_TRANSIENT_FOR";
NSString* ICCCMWMProtocols = @"WM_PROTOCOLS";
NSString* ICCCMWMColormapWindows = @"WM_COLORMAP_WINDOWS";
NSString* ICCCMWMClientMachine = @"WM_CLIENT_MACHINE";

// Properties set by a Window Manager on a Client Window
NSString* ICCCMWMState = @"WM_STATE";
NSString* ICCCMWMIconSize = @"WM_ICON_SIZE";

// ICCCM WM_PROTOCOLS
NSString* ICCCMWMTakeFocus = @"WM_TAKE_FOCUS";
NSString* ICCCMWMSaveYourself = @"WM_SAVE_YOURSELF";
NSString* ICCCMWMDeleteWindow = @"WM_DELETE_WINDOW";

NSArray *ICCCMAtomsList(void)
{
	NSString* atoms[] = {
		ICCCMWMName,
		ICCCMWMIconName,
		ICCCMWMNormalHints, 
		ICCCMWMSizeHints, 
		ICCCMWMHints, 
		ICCCMWMClass, 
		ICCCMWMTransientFor, 
		ICCCMWMProtocols, 
		ICCCMWMColormapWindows, 
		ICCCMWMClientMachine, 
		ICCCMWMState, 
		ICCCMWMIconSize, 

		ICCCMWMTakeFocus, 
		ICCCMWMSaveYourself, 
		ICCCMWMDeleteWindow
	};
	// Remember, only works with static allocated arrays
	return [NSArray arrayWithObjects: atoms 
	                           count: sizeof(atoms) / sizeof(NSString*)];
}

@implementation XCBCachedProperty (ICCCM)
- (xcb_size_hints_t)asWMSizeHints
{
	xcb_size_hints_t size_hints;
	[self checkAtomType: ICCCMWMSizeHints];
	[[self data] getBytes: &size_hints
	               length: sizeof(xcb_size_hints_t)];
	return size_hints;
}
- (xcb_wm_hints_t)asWMHints
{
	xcb_wm_hints_t hints;
	[self checkAtomType: ICCCMWMHints];
	[[self data] getBytes: &hints
	               length: sizeof(xcb_wm_hints_t)];
	return hints;
}
@end

