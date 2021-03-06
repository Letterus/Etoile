/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2010
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "NSCell+EtoileUI.h"
#import "ETCompatibility.h"


@implementation NSCell (EtoileUI)

/** Returns an object value representation compatible with the cell.

Nil can be returned. */
- (id) objectValueForObject: (id)anObject
{
	id objectValue = nil;

	if ([self type] ==  NSImageCellType)
	{
		objectValue = ([anObject isKindOfClass: [NSImage class]] ? anObject: nil);
	}
	else
	{
		objectValue = ([anObject isCommonObjectValue] ? anObject : [anObject objectValue]);
	}
	ETAssert(objectValue == nil || [objectValue conformsToProtocol: @protocol(NSCopying)]);
	return objectValue;
}

- (id) objectValueForCurrentValue: (id)aValue
{
	return [self objectValueForObject: aValue];
}

- (id) currentValueForObjectValue: (id)aValue
{
	return  aValue;
}

@end


@implementation NSImageCell (EtoileUI)

/** Returns nil when the given object is not an NSImage instance. */
- (id) objectValueForObject: (id)anObject
{
	// NOTE: We override NSCell implementation because NSImageCell type is 
	// NSNullCellType on Mac OS X
	return ([anObject isKindOfClass: [NSImage class]] ? anObject: nil);
}

@end


@implementation NSPopUpButtonCell (EtoileUI)

- (id) objectValueForCurrentValue: (id)aValue
{
	return [NSNumber numberWithInteger: [self indexOfItemWithRepresentedObject: aValue]];
}

- (id) currentValueForObjectValue: (id)aValue
{
	return [[self itemAtIndex: [aValue integerValue]] representedObject];
}

@end
