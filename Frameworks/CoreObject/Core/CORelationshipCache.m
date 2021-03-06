/*
	Copyright (C) 2013 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  July 2013
	License:  Modified BSD  (see COPYING)
 */

#import "CORelationshipCache.h"
#import <EtoileFoundation/EtoileFoundation.h>
#import "COType.h"
#import "COItem.h"
#import "COObject.h"

@interface COCachedRelationship : NSObject
{
@public
    NSString *_targetProperty;
    /**
     * Weak reference.
     */
    COObject *__weak _sourceObject;
    NSString *_sourceProperty;
}

@property (nonatomic, readonly) NSDictionary *descriptionDictionary;

@property (readwrite, nonatomic, weak) COObject *sourceObject;
@property (readwrite, nonatomic, copy) NSString *sourceProperty;
@property (readwrite, nonatomic, copy) NSString *targetProperty;

@end

@implementation COCachedRelationship

@synthesize sourceObject = _sourceObject;
@synthesize sourceProperty = _sourceProperty;
@synthesize targetProperty = _targetProperty;

- (NSDictionary *)descriptionDictionary
{
	return D(_targetProperty, @"property",
	         _sourceProperty, @"opposite property",
	        [_sourceObject UUID], @"opposite object");
}

- (NSString *)description
{
	return [[self descriptionDictionary] description];
}

@end

@implementation CORelationshipCache

#define INITIAL_ARRAY_CAPACITY 8

- (id) initWithOwner: (COObject *)owner
{
    SUPERINIT;
    _cachedRelationships = [[NSMutableArray alloc] initWithCapacity: INITIAL_ARRAY_CAPACITY];
    _owner = owner;
    return self;
}

- (NSString *)description
{
	NSArray *relationships =
		(id)[[_cachedRelationships mappedCollection] descriptionDictionary];
	return [D([_owner UUID], @"owner", relationships, @"relationships") description];
}

- (NSSet *) referringObjectsForPropertyInTarget: (NSString *)aProperty
{
    NSMutableSet *result = [NSMutableSet set];
    for (COCachedRelationship *entry in _cachedRelationships)
    {
        if ([aProperty isEqualToString: entry->_targetProperty])
        {
            [result addObject: entry->_sourceObject];
        }
    }
    return result;
}

- (COObject *) referringObjectForPropertyInTarget: (NSString *)aProperty
{
    NSMutableArray *results = [NSMutableArray array];
    
    for (COCachedRelationship *entry in _cachedRelationships)
    {
        if ([aProperty isEqualToString: entry->_targetProperty])
        {
            [results addObject: entry->_sourceObject];
        }
    }
    
    assert([results count] == 0
           || [results count] == 1);
    
    if ([results count] == 0)
    {
        return nil;
    }
    return [results firstObject];
}

- (void) removeAllEntries
{
    [_cachedRelationships removeAllObjects];
}

- (void) removeReferencesForPropertyInSource: (NSString *)aTargetProperty
                                sourceObject: (COObject *)anObject
{
    // FIXME: Ugly, rewrite
    
    NSUInteger i = 0;
    while (i < [_cachedRelationships count])
    {
        COCachedRelationship *entry = [_cachedRelationships objectAtIndex: i];
        if ([aTargetProperty isEqualToString: entry->_sourceProperty]
            && entry.sourceObject == anObject)
        {
            [_cachedRelationships removeObjectAtIndex: i];
        }
        else
        {
            i++;
        }
    }
}

- (void) addReferenceFromSourceObject: (COObject *)aReferrer
                       sourceProperty: (NSString *)aSource
                       targetProperty: (NSString *)aTarget
{
    ETPropertyDescription *prop = [[_owner entityDescription] propertyDescriptionForName: aTarget];
    if (![prop isMultivalued])
    {
        // We are setting the value of a non-multivalued property, so assert
        // that it is currently not already set.
        
        // HACK: The assertion fails when code uses -didChangeValueForProperty:
        // instead of -didChangeValueForProperty:oldValue:, because we can't clear the old
        // relationships from the cache if -didChangeValueForProperty: is used.
        //
        // So the assetion was removed and this hack added to remove stale entries from
        // the cache, only for one-many relationships. 
        for (COCachedRelationship *entry in [NSArray arrayWithArray: _cachedRelationships])
        {
            if ([aTarget isEqualToString: entry->_targetProperty])
            {
                [_cachedRelationships removeObject: entry];
            }
        }
    }
    
    COCachedRelationship *record = [[COCachedRelationship alloc] init];
    record.sourceObject = aReferrer;
    record.sourceProperty = aSource;
    record.targetProperty = aTarget;
    [_cachedRelationships addObject: record];
}

@end
