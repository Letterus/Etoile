/*
 ETPropertyDescription.m
 
 Property description in a model description framework inspired by FAME 
 (http://scg.unibe.ch/wiki/projects/fame)
 
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  July 2009
 License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import "ETPropertyDescription.h"
#import "ETCollection.h"
#import "ETEntityDescription.h"
#import "ETReflection.h"
#import "ETUTI.h"
#import "ETValidationResult.h"
#import "Macros.h"
#import "EtoileCompatibility.h"


@implementation ETPropertyDescription

- (void) dealloc
{
	[_role release];
	[super dealloc];
}

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *selfDesc = [ETEntityDescription descriptionWithName: [self className]];

	NSArray *inheritedPropertyDescs = [[super newEntityDescription] allPropertyDescriptions];
	ETPropertyDescription *composite = [ETPropertyDescription descriptionWithName: @"composite"];
	[composite setDerived: YES];
	ETPropertyDescription *container = [ETPropertyDescription descriptionWithName: @"container"];
	ETPropertyDescription *derived = [ETPropertyDescription descriptionWithName: @"derived"];
	ETPropertyDescription *multivalued = [ETPropertyDescription descriptionWithName: @"multivalued"];
	ETPropertyDescription *ordered = [ETPropertyDescription descriptionWithName: @"ordered"];
	ETPropertyDescription *opposite = [ETPropertyDescription descriptionWithName: @"opposite"];
	[opposite setOpposite: opposite];
	ETPropertyDescription *type = [ETPropertyDescription descriptionWithName: @"type"];
	
	[selfDesc setPropertyDescriptions: [inheritedPropertyDescs arrayByAddingObjectsFromArray:
		A(composite, container, derived, multivalued, ordered, opposite, type)]];
	[selfDesc setType: [ETUTI typeWithClass: [ETPropertyDescription class]]];
	[selfDesc setParent: (id)NSStringFromClass([self superclass])];

	return selfDesc;
}

/* Properties */

- (BOOL) isComposite
{
	return [[self opposite] isContainer];
}

- (BOOL) isContainer
{
	return _container;
}

- (void) setIsContainer: (BOOL)isContainer
{
	_container = isContainer;
	if (isContainer)
	{
		FOREACH([[self owner] propertyDescriptions], otherProperty, ETPropertyDescription *)
		{
			if (otherProperty != self)
			{
				[otherProperty setIsContainer: NO];
			}
		}
		[self setMultivalued: NO];
	}
	//FIXME: do other checks that the parent link is valid
}

- (BOOL) isDerived
{
	return _derived;
}

- (void) setDerived: (BOOL)isDerived
{
	_derived = isDerived;
}

- (BOOL) isMultivalued
{
	return _multivalued;
}

- (void) setMultivalued: (BOOL)isMultivalued
{
	_multivalued = isMultivalued;
}

- (BOOL) isOrdered
{
	return _ordered;
}

- (void) setOrdered: (BOOL)isOrdered
{
	_ordered = isOrdered;
}

- (ETPropertyDescription *) opposite
{
	return _opposite;
}

- (void) setOpposite: (ETPropertyDescription *)opposite
{
	// FIXME: what does it mean if opposite == self? 
	//        FM3 seems to do this for the opposite property of FM3.Property
	if (opposite == _opposite || opposite == self)
	{
		return;
	}
	if (nil != _opposite)
	{
		[_opposite setOpposite: nil];
	}
	
	_opposite = opposite;
	if (nil != _opposite)
	{
		if ([_opposite opposite] != self)
		{
			[_opposite setOpposite: self];
		}
		[self setType: [[_opposite owner] type]];
	}
}

- (ETEntityDescription *) owner
{
	return _owner;
}

- (void) setOwner: (ETEntityDescription *)owner
{
	NSParameterAssert((_owner != nil && owner == nil) || (_owner == nil && owner != nil));
	_owner = owner;
}

- (ETPackageDescription *) package
{
	return _package;
}

- (void) setPackage: (ETPackageDescription *)aPackage
{
	_package = aPackage;
}

- (id) role
{
	return _role;
}

- (void) setRole: (ETRoleDescription *)role
{
	ASSIGN(_role, role);
}

- (ETValidationResult *) validateValue: (id)value forKey: (NSString *)key
{
	ETRoleDescription *role = [self role];
	if (nil != role)
	{
		return [role validateValue: value forKey: key];
	}
	return [ETValidationResult validResult: value];
}

/* Inspired by the Java implementation of FAME */
- (void) checkConstraints: (NSMutableArray *)warnings
{
	if ([self isContainer] && [self isMultivalued])
	{
		[warnings addObject: [self warningWithMessage: 
			@"Container must refer to a single object"]];
	}
	if ([self opposite] != nil && [[[self opposite] opposite] isEqual: self] == NO) 
	{
		[warnings addObject: [self warningWithMessage: 
			@"Opposites must refer to each other"]];
	}
	if (islower([[self name] characterAtIndex: 0]))
	{
		[warnings addObject: [self warningWithMessage: @"Name should be in lower case"]];
	}
	if ([self type] == nil)
	{
		[warnings addObject: [self warningWithMessage: @"Miss a type"]];
	}
	if ([self owner] == nil)
	{
		[warnings addObject: [self warningWithMessage: @"Miss an owner"]];
	}
	if ([[self owner] isKindOfClass: [ETEntityDescription class]] == NO)
	{
		[warnings addObject: [self warningWithMessage: 
			@"Owner must be an entity description"]];
	}
}

@end


/*
 Property Role Description classes 
 
 These allow pluggable, more precise property descriptions with validation
 */
@implementation ETRoleDescription 

- (ETPropertyDescription *) parent
{
	return nil;
}

- (ETValidationResult *) validateValue: (id)value forKey: (NSString *)key
{
	return [ETValidationResult validResult: value];
}

@end


@implementation ETRelationshipRole

- (BOOL) isMandatory
{
	return _isMandatory;
}

- (void) setMandatory: (BOOL)isMandatory
{
	_isMandatory = isMandatory;
}

- (NSString *) deletionRule
{
	return _deletionRule;
}

- (void) setDeletionRule: (NSString *)deletionRule
{
	ASSIGN(_deletionRule, deletionRule);
}

@end


@implementation ETMultiOptionsRole

- (void) dealloc
{
	DESTROY(_allowedOptions);
	[super dealloc];
}

- (void) setAllowedOptions: (NSArray *)allowedOptions
{
	ASSIGN(_allowedOptions, [allowedOptions copy]);
}

- (NSArray *) allowedOptions
{
	return _allowedOptions;
}

- (ETValidationResult *) validateValue: (id)value forKey: (NSString *)key
{
	if ([_allowedOptions containsObject: value])
	{
		return [ETValidationResult validResult: value];
	}
	else
	{
		return [ETValidationResult validationResultWithValue: nil
													 isValid: NO
													   error: @"Value not in the allowable set"];
	}
}

@end


@implementation ETNumberRole

- (int)minimum
{
	return _min;
}

- (void)setMinimum: (int)min
{
	_min = min;
}

- (int)maximum
{
	return _max;
}

- (void)setMaximum: (int)max
{
	_max = max;
}

- (ETValidationResult *) validateValue: (id)value forKey: (NSString *)key
{
	int intValue = [value intValue];
	if (intValue <= _max && intValue >= _min)
	{
		return [ETValidationResult validResult: value];
	}
	else
	{
		return [ETValidationResult validationResultWithValue: [NSNumber numberWithInt: MAX(_min, MIN(_max, intValue))]
													 isValid: NO
													   error: @"Value outside the allowable range"];
	}
}

@end
