#import "COItem.h"
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETUUID.h>
#import "COPath.h"
#import "COType.h"

static NSDictionary *copyValueDictionary(NSDictionary *input, BOOL mutable)
{
	NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
	
	for (NSString *key in input)
	{
		id obj = [input objectForKey: key];
		
		if ([obj isKindOfClass: [NSCountedSet class]])
		{
			// FIXME: Always mutable
			[result setObject: obj
					   forKey: key];
		}
		else if ([obj isKindOfClass: [NSSet class]])
		{
			[result setObject: [(mutable ? [NSMutableSet class] : [NSSet class]) setWithSet: obj]
					   forKey: key];
		}
		else if ([obj isKindOfClass: [NSArray class]])
		{
			[result setObject: [(mutable ? [NSMutableArray class] : [NSArray class]) arrayWithArray: obj]
					   forKey: key];
		}
		else
		{
			[result setObject: obj forKey: key];
		}
	}
	
	if (!mutable)
	{
		NSDictionary *immutable = [[NSDictionary alloc] initWithDictionary: result];
		return immutable;
	}
	return result;
}

@implementation COItem

@synthesize schemaName;

- (id) initWithUUID: (ETUUID *)aUUID
 typesForAttributes: (NSDictionary *)typesForAttributes
valuesForAttributes: (NSDictionary *)valuesForAttributes
{
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(typesForAttributes);
	NILARG_EXCEPTION_TEST(valuesForAttributes);
		
	SUPERINIT;
	uuid =  aUUID;
	// FIXME: These casts are not truly elegant
	types = (NSMutableDictionary *)[[NSDictionary alloc] initWithDictionary: typesForAttributes];
	values = (NSMutableDictionary *)copyValueDictionary(valuesForAttributes, NO);
    
    for (NSString *key in values)
    {
        ETAssert(COTypeValidateObject([[types objectForKey: key] intValue], [values objectForKey: key]));
    }

	return self;
}


+ (COItem *) itemWithTypesForAttributes: (NSDictionary *)typesForAttributes
						 valuesForAttributes: (NSDictionary *)valuesForAttributes
{
	return [[self alloc] initWithUUID: [ETUUID UUID]
					typesForAttributes: typesForAttributes
				   valuesForAttributes: valuesForAttributes];
}

- (ETUUID *)UUID
{
	return uuid;
}

- (NSArray *) attributeNames
{
	return [types allKeys];
}

- (COType) typeForAttribute: (NSString *)anAttribute
{
	return [[types objectForKey: anAttribute] intValue];
}

- (id) valueForAttribute: (NSString *)anAttribute
{
	return [values objectForKey: anAttribute];
}


/** @taskunit equality testing */

- (BOOL) isEqual: (id)object
{
	if (object == self)
	{
		return YES;
	}
	if (![object isKindOfClass: [COItem class]])
	{
		return NO;
	}
	COItem *otherItem = (COItem*)object;
	
	if (![otherItem->uuid isEqual: uuid]) return NO;
	if (![otherItem->types isEqual: types]) return NO;
	if (![otherItem->values isEqual: values]) return NO;
    if (!(otherItem->schemaName == nil && schemaName == nil)
        && ![otherItem->schemaName isEqual: schemaName]) return NO;
	return YES;
}

- (NSUInteger) hash
{
	return [uuid hash] ^ [types hash] ^ [values hash] ^ 9014972660509684524LL;
}

/** @taskunit convenience */

- (NSArray *) allObjectsForAttribute: (NSString *)attribute
{
	id value = [self valueForAttribute: attribute];
	
	if (COTypeIsPrimitive([self typeForAttribute: attribute]))
	{
		return [NSArray arrayWithObject: value];
	}
	else
	{
		if ([value isKindOfClass: [NSSet class]])
		{
			return [(NSSet *)value allObjects];
		}
		else if ([value isKindOfClass: [NSArray class]])
		{
			return value;
		}
		else
		{
			return [NSArray array];
		}
	}
}

- (NSSet *) compositeReferencedItemUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (NSString *key in [self attributeNames])
	{
		COType type = [self typeForAttribute: key];
		if (COTypePrimitivePart(type) == kCOTypeCompositeReference)
		{		
			for (ETUUID *embedded in [self allObjectsForAttribute: key])
			{
				[result addObject: embedded];
			}
		}
	}
	return [NSSet setWithSet: result];
}

- (NSSet *) referencedItemUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (NSString *key in [self attributeNames])
	{
		COType type = [self typeForAttribute: key];
		if (COTypePrimitivePart(type) == kCOTypeReference)
		{
			for (ETUUID *embedded in [self allObjectsForAttribute: key])
			{
				[result addObject: embedded];
			}
		}
	}
	return [NSSet setWithSet: result];
}


// Helper methods for doing GC

- (NSArray *) attachments
{
	NSMutableArray *result = [NSMutableArray array];
	
	for (NSString *key in [self attributeNames])
	{
		COType type = [self typeForAttribute: key];
		if (COTypePrimitivePart(type) == kCOTypeAttachment)
		{
			for (NSData *embedded in [self allObjectsForAttribute: key])
			{
				[result addObject: embedded];
			}
		}
	}
	return result;
}

- (NSArray *) allReferencedPersistentRootUUIDs
{
	NSMutableArray *result = [NSMutableArray array];
	
	for (NSString *key in [self attributeNames])
	{
		COType type = [self typeForAttribute: key];
		if (COTypePrimitivePart(type) == kCOTypeReference)
		{
			for (id ref in [self allObjectsForAttribute: key])
			{
                if ([ref isKindOfClass: [COPath class]] && [ref isCrossPersistentRoot])
                {
                    [result addObject: [ref persistentRoot]];
                }
			}
		}
	}
	return result;
}

- (NSString *) fullTextSearchContent
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *key in [self attributeNames])
	{
		COType type = [self typeForAttribute: key];
		if (COTypePrimitivePart(type) == kCOTypeString)
		{
			[result addObject: [self valueForAttribute: key]];
		}
	}
    return [result componentsJoinedByString: @" "];
}

- (NSString *)description
{
	NSMutableString *result = [NSMutableString string];
		
	[result appendFormat: @"{ COItem %@\n", uuid];
	
	for (NSString *attrib in [self attributeNames])
	{
		[result appendFormat: @"\t%@ <%@> = '%@'\n",
			attrib,
			COTypeDescription([self typeForAttribute: attrib]),
			[self valueForAttribute:attrib]];
	}
	
	[result appendFormat: @"}"];
	
	return result;
}

/** @taskunit copy */

- (id) copyWithZone: (NSZone *)zone
{
	return self;
}

- (id) mutableCopyWithZone: (NSZone *)zone
{
	return [[COMutableItem alloc] initWithUUID: uuid			
								 typesForAttributes: types
								valuesForAttributes: values];
}

- (id)mutableCopyWithNameMapping: (NSDictionary *)aMapping
{
	COMutableItem *aCopy = [self mutableCopy];
	
	ETUUID *newUUIDForSelf = [aMapping objectForKey: [self UUID]];
	if (newUUIDForSelf != nil)
	{
		[aCopy setUUID: newUUIDForSelf];
	}
	
	for (NSString *attr in [aCopy attributeNames])
	{
		id value = [aCopy valueForAttribute: attr];
		COType type = [aCopy typeForAttribute: attr];
		
		if (COTypeIsPrimitive(type))
		{
			if ([value isKindOfClass: [ETUUID class]])
			{
				if ([aMapping objectForKey: value] != nil)
				{
					[aCopy setValue: [aMapping objectForKey: value]
					   forAttribute: attr
							   type: type];
				}
			}
			if ([value isKindOfClass: [COPath class]])
			{
				[aCopy setValue: [value pathWithNameMapping: aMapping]
				   forAttribute: attr
						   type: type];
			}
		}
		else
		{
			id newCollection = [value mutableCopy];
			[newCollection removeAllObjects];
			
			for (id subValue in value)
			{
				if ([subValue isKindOfClass: [ETUUID class]])
				{
					if ([aMapping objectForKey: subValue] != nil)
					{
						[newCollection addObject: [aMapping objectForKey: subValue]];
					}
					else
					{
						[newCollection addObject: subValue];
					}
				}
				else if ([subValue isKindOfClass: [COPath class]])
				{
					[newCollection addObject: [subValue pathWithNameMapping: aMapping]];
				}
			}
			
			[aCopy setValue: newCollection
			   forAttribute: attr
					   type: type];
		}
	}
	
	return aCopy;
}

@end




@implementation COMutableItem

+ (COMutableItem *) itemWithTypesForAttributes: (NSDictionary *)typesForAttributes
						   valuesForAttributes: (NSDictionary *)valuesForAttributes
{
    return (COMutableItem *)[super itemWithTypesForAttributes: typesForAttributes
                                          valuesForAttributes: valuesForAttributes];
}

- (id) initWithUUID: (ETUUID *)aUUID
 typesForAttributes: (NSDictionary *)typesForAttributes
valuesForAttributes: (NSDictionary *)valuesForAttributes
{
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(typesForAttributes);
	NILARG_EXCEPTION_TEST(valuesForAttributes);
	
	SUPERINIT;
	uuid =  aUUID;
	types = [[NSMutableDictionary alloc] initWithDictionary: typesForAttributes];
	values = (NSMutableDictionary *)copyValueDictionary(valuesForAttributes, YES);
	
    for (NSString *key in values)
    {
        ETAssert(COTypeValidateObject([[types objectForKey: key] intValue], [values objectForKey: key]));
    }
    
	return self;
}

- (id) initWithUUID: (ETUUID*)aUUID
{
	return [self initWithUUID: aUUID
		   typesForAttributes: [NSDictionary dictionary]
		  valuesForAttributes: [NSDictionary dictionary]];
}

- (id) init
{
	return [self initWithUUID: [ETUUID UUID]];
}

+ (COMutableItem *) item
{
	return [[self alloc] init];
}

+ (COMutableItem *) itemWithUUID: (ETUUID *)aUUID
{
	return [(COMutableItem *)[self alloc] initWithUUID: aUUID];
}

- (void) setUUID: (ETUUID *)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	uuid =  aUUID;
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString *)anAttribute
			 type: (COType)aType
{
	NILARG_EXCEPTION_TEST(aValue);
	NILARG_EXCEPTION_TEST(anAttribute);
	
    ETAssert(COTypeValidateObject(aType, aValue));
    
	[(NSMutableDictionary *)types setObject: [NSNumber numberWithInt: aType] forKey: anAttribute];
	[(NSMutableDictionary *)values setObject: aValue forKey: anAttribute];
}

- (void)removeValueForAttribute: (NSString*)anAttribute
{
	[(NSMutableDictionary *)types removeObjectForKey: anAttribute];
	[(NSMutableDictionary *)values removeObjectForKey: anAttribute];
}

/** @taskunit convenience */

- (void)   addObject: (id)aValue
toUnorderedAttribute: (NSString*)anAttribute
				type: (COType)aType
{
	if (!COTypeIsMultivalued(aType) || COTypeIsOrdered(aType))
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected unordered type"];
	}
	
	if ([self typeForAttribute: anAttribute] == 0)
	{
		[self setValue: [NSSet set]
		  forAttribute: anAttribute
				  type: aType];
	}
		 
	NSMutableSet *set = [[self valueForAttribute: anAttribute] mutableCopy];
	NSAssert([set isKindOfClass: [NSMutableSet class]], @"expected NSMutableSet");
	[set addObject: aValue];
	[self setValue: set
	  forAttribute: anAttribute
			  type: aType];
}

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
			 atIndex: (NSUInteger)anIndex
				type: (COType)aType
{
	if (!COTypeIsMultivalued(aType) || !COTypeIsOrdered(aType))
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected ordered type"];
	}
	
	if ([self typeForAttribute: anAttribute] == 0)
	{
		[self setValue: [NSMutableArray array]
		  forAttribute: anAttribute
				  type: aType];
	}
	
	NSMutableArray *array = [[self valueForAttribute: anAttribute] mutableCopy];
	NSAssert([array isKindOfClass: [NSMutableArray class]], @"expected NSMutableArray");
	[array insertObject: aValue
				atIndex: anIndex];
	[self setValue: array
	  forAttribute: anAttribute
			  type: aType];
}

- (void) addObject: (id)aValue
	  forAttribute: (NSString*)anAttribute
{
	assert(COTypeIsMultivalued([[types objectForKey: anAttribute] integerValue]));
	
    id container = [values objectForKey: anAttribute];
    if (![container isKindOfClass: [NSMutableArray class]]
        && ![container isKindOfClass: [NSMutableSet class]])
    {
        container = [container mutableCopy];
        [(NSMutableDictionary *)values setObject: container forKey: anAttribute];
        
    }
    [container addObject: aValue];
}


- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
{
	[self setValue: aValue 
	  forAttribute: anAttribute
			  type: [self typeForAttribute: anAttribute]];
}

- (id) copyWithZone: (NSZone *)zone
{
	return [[COItem alloc] initWithUUID: uuid
                     typesForAttributes: types
                    valuesForAttributes: values];
}

@end

