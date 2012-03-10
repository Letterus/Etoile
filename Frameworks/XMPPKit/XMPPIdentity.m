//  XMPPIdentity.m
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XMPPIdentity.h"
#import "XMPPRootIdentity.h"
#import <EtoileXML/ETXMLString.h>
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPIdentity


- (id) initWithJID:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group forPerson:(id)_person
{
	[self init];
	jid = [_jid retain];
	name = [_name retain];
	group = [_group retain];
	person = [_person retain];
	return self;
}

- (id) initWithXMLParser: (ETXMLParser*) aParser
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	presence = [[XMPPPresence alloc] init];
	return self;
}

/*
 <query xmlns='jabber:iq:roster'>
 <item
 jid='user@example.com'
 subscription='to'
 name='SomeUser'>
 <group>SomeGroup</group>
 </item>
 </query>
 */

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"item"])
	{
		depth++;
		jid = [[JID alloc] initWithString:[attributes objectForKey:@"jid"]];
		subscription = [[attributes objectForKey:@"subscription"] retain];
		ask = [[attributes objectForKey:@"ask"] retain];
		name = [[attributes objectForKey:@"name"] retain];
	}
	else if([aName isEqualToString:@"group"])
	{
		[[[ETXMLString alloc] initWithXMLParser:parser
	   					    key:@"group"] startElement:aName
														   attributes:attributes];
	}
	else
	{
		[[[ETXMLNullHandler alloc] initWithXMLParser:parser
						         key:nil] startElement:aName
															          attributes:attributes];
	}
}

- (void) addgroup:(NSString*)aGroup
{
	[group release];
	group = [aGroup retain];
}

- (void) setPresence:(XMPPPresence*)_presence
{
	[presence release];
	presence = [_presence retain];
	priority = basePriority + 70 - [presence show] + [presence priority];	
}

- (NSString*) name
{
	if (name == nil)
	{
		return [jid node];
	}
	return name;
}

- (NSString*) group
{
	return group;
}
- (void) setName:(NSString*)aName
{
	[aName retain];
	[name release];
	name = aName;
}
- (void) setGroup:(NSString*)aGroup
{
	[aGroup retain];
	[group release];
	group = aGroup;	
}

- (JID*) jid
{
	return jid;
}

- (XMPPPresence*) presence
{
	return presence;
}

- (int) priority
{
	return priority;
}
- (NSString*) subscription
{
	return subscription;
}
- (NSString*) ask
{
	return ask;
}
- (id) person
{
	return person;
}

- (void) person:(id)_person
{
	[person release];
	person = [_person retain];
}

- (NSComparisonResult) compareByPriority:(XMPPIdentity*)_other
{
	if(priority > [_other priority])
	{
		return NSOrderedAscending;
	}
	if(priority < [_other priority])
	{
		return NSOrderedDescending;
	}
	return NSOrderedSame;
}

- (NSComparisonResult) compareByJID:(XMPPIdentity*)_other
{
	return NSOrderedAscending;
}

- (void) dealloc
{
	[person release];
	[jid release];
	[subscription release];
	[ask release];
	[group release];
	[name release];
	[presence release];
	[super dealloc];
}
@end
