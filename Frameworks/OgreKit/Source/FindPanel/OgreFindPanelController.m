/*
 * Name: OgreFindPanelController.m
 * Project: OgreKit
 *
 * Creation Date: Sep 13 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreFindPanelController.h>
#import <OgreKit/OgreFindPanel.h>
#import "GNUstep.h"

@implementation OgreFindPanelController
// 適切な正規表現かどうか調べる
- (BOOL)alertIfInvalidRegex
{
  NS_DURING
   [OGRegularExpression regularExpressionWithString: [[findPanel findTextField] stringValue]
                                           options: [self options]
                                            syntax: [self syntax]
                                   escapeCharacter: OgreBackslashCharacter];
  NS_HANDLER
  // 例外処理
    if ([[localException name] isEqualToString:OgreException]) {
      NSBeep();   // 不適切な正規表現だった場合 (非常に手抜き)
    } else {
      [localException raise];
    }
    return NO;
  NS_ENDHANDLER

  return YES;
}

- (void) findNext: (id) sender
{
  if (![self alertIfInvalidRegex]) return;

  OgreTextFindResult *result = [[self textFinder] 
	           find: [[findPanel findTextField] stringValue]
	        options: [self options]
		fromTop: NO
		forward: YES
		wrap: YES];
  if (![result isSuccess]) {
    NSLog(@"find next failed");
  }
}

- (void) findPrevious: (id) sender
{
  if (![self alertIfInvalidRegex]) return;

  OgreTextFindResult *result = [[self textFinder] 
	           find: [[findPanel findTextField] stringValue]
	        options: [self options]
		fromTop: NO
		forward: NO
		wrap: YES];
  if (![result isSuccess]) {
    NSLog(@"find previous failed");
  }
}

- (void) replace: (id) sender
{
  if (![self alertIfInvalidRegex]) return;

  OgreTextFindResult *result = [[self textFinder] 
	replace: [[findPanel findTextField] stringValue]
	withString: [[findPanel replaceTextField] stringValue]
        options: [self options]];

  if (![result isSuccess]) {
    NSLog(@"replace failed");
  }
}

- (void) replaceAndFind: (id) sender
{
  [self replace: self];
  [self findNext: self];
}

/*
 * FIXME: Only replaces everything from the current cursor position. Please fix!
 */
- (void) replaceAll: (id) sender
{
  if (![self alertIfInvalidRegex]) return;
  
  OgreTextFindResult* result = nil;
  NSString* findString = [[findPanel findTextField] stringValue];
  NSString* replaceString = [[findPanel replaceTextField] stringValue];
  
  // FIXME: In this loop I assume that isSuccess only returns NO
  // if all occurences of the pattern have been replaced. Is that
  // a safe assumption? Yen-Ju? :)
  do {
    [self findNext: self];
    
    result = [[self textFinder]
      replace: findString
      withString: replaceString
      options: [self options]];
  } while ([result isSuccess]);
}

- (OgreTextFinder*)textFinder
{
	return textFinder;
}

- (void)setTextFinder:(OgreTextFinder*)aTextFinder
{
	textFinder = aTextFinder;
}


- (IBAction)showFindPanel:(id)sender
{
	if ([findPanel isKeyWindow]) {
		[findPanel orderFront:self];
	} else {
		[findPanel makeKeyAndOrderFront:self];
		[[findPanel findTextField] selectText: self];
	}
	
	// WindowsメニューにFind Panelを追加
	[NSApp addWindowsItem:findPanel title:[findPanel title] filename:NO];
}

- (void)close
{
	[findPanel orderOut:self];
}

- (NSPanel*)findPanel
{
	return findPanel;
}

- (void)setFindPanel:(NSPanel*)aPanel
{
	ASSIGN(findPanel, aPanel);
}

- (unsigned int) options
{
  return options;
}

- (void) setOptions: (unsigned int) o
{
  options = o;
}

- (OgreSyntax) syntax
{
  return syntax;
}

- (void) setSyntax: (OgreSyntax) o
{
  [[self textFinder] setSyntax: o];
  syntax = o;
}

// NSCoding protocols
- (NSDictionary*)history
{
	/* 履歴等を保存したい場合は、NSDictionaryで返す。 */
	return [NSDictionary dictionary];
}

@end
