/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2011
	License:  Modified BSD  (see COPYING)
 */

#import "COCollection.h"

#pragma GCC diagnostic ignored "-Wprotocol"

@implementation COCollection

+ (void) initialize
{
	if (self != [COCollection class])
		return;

	[self applyTraitFromClass: [ETCollectionTrait class]];
	[self applyTraitFromClass: [ETMutableCollectionTrait class]];
}

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *collection = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add the 
	// property descriptions that we will inherit through the parent
	if ([[collection name] isEqual: [COCollection className]] == NO) 
		return collection;

	return collection;	
}

- (void)addObjects: (NSArray *)anArray
{
	for (id object in anArray)
	{
		[self addObject: object];
	}
}

- (id) content
{
	return [self valueForProperty: @"contents"];
}

- (NSArray *) contentArray
{
	 // FIXME: Should return a new array, but this might break other things currently
	return [self valueForProperty: @"contents"];
}

- (void) insertObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
{
	assert([object editingContext] == [self editingContext]); // FIXME: change to an exception
	if (index == ETUndeterminedIndex)
	{
		[self addObject: object forProperty: @"contents"];
	}
	else
	{
		[self insertObject: object atIndex: index forProperty: @"contents"];
	}
}

- (void) removeObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
{
	assert([object editingContext] == [self editingContext]); // FIXME: change to an exception
	if (index == ETUndeterminedIndex)
	{
		[self removeObject: object forProperty: @"contents"];	
	}
	else
	{
		[self removeObject: object atIndex: index forProperty: @"contents"];
	}
}

- (id)objectForIdentifier: (NSString *)anId
{
	for (id object in [self content])
	{
		if ([[object identifier] isEqualToString: anId])
		{
			return object;
		}
	}
	return nil;
}

- (NSArray *)objectsMatchingQuery: (COQuery *)aQuery
{
	NSMutableArray *result = [NSMutableArray array];

	for (COObject *object in [self content])
	{
		if ([[aQuery predicate] evaluateWithObject: object])
		{
			[result addObject: object];
		}
	}

	return result;
}

@end


@implementation COObject (COCollectionTypeQuerying)

- (BOOL)isGroup
{
	return NO;
}

- (BOOL)isTag
{
	return NO;
}

- (BOOL)isContainer
{
	return NO;
}

- (BOOL)isLibrary
{
	return NO;
}

@end

