//
//  Test.m
//  distn
//
//  Created by David Chisnall on 20/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "StatusAtom.h"
#import <EtoileFoundation/ETUUID.h>

extern char * publish;
/**
 * Helper function for escaping XML character data.
 */
static inline NSMutableString* escapeXMLCData(NSString* _XMLString)
{
	if(_XMLString == nil)
	{
		return [NSMutableString stringWithString:@""];
	}
	NSMutableString * XMLString = [NSMutableString stringWithString:_XMLString];
	[XMLString replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"'" withString:@"&apos;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:0 range:NSMakeRange(0,[XMLString length])];
	return XMLString;
}
@implementation StatusAtom
- (id) init
{
	if((self = [super init]) == nil)
	{
		return nil;
	}
	srandom([[NSDate date] timeIntervalSince1970]);
	file = fopen("mublog.entries", "a");
	return self;
}
- (void) statusChanged:(NSNotification*)aNotification
{
	NSString * message = [[aNotification userInfo] objectForKey:@"status"];
	if(message != nil && ![message isEqualToString:@""])
	{
		/* Avoid duplicates */
		if(![lastStatus isEqualToString:message])
		{
			NSString * title = [[message componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"!:.?"]] objectAtIndex:0];
			NSString * entry = 
				[NSString stringWithFormat:
					@"\n\n\t<entry>\n\t\t<title>%@</title>\n\t\t<summary>%@</summary>\n\t\t<id>%@</id>\n\t\t<updated>%@</updated>\n\t</entry>",
					escapeXMLCData(title),
					escapeXMLCData(message),
					[ETUUID UUID],
					[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%SZ"]];
			const char * utf8 = [entry UTF8String];
			fwrite(utf8, strlen(utf8), 1, file);
			fflush(file);
			if(publish != NULL)
			{
				system(publish);
			}
			/* Log the last status */
			[lastStatus release];
			lastStatus = [message retain];
		}
	}
}
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	NSNotificationCenter * center = [NSDistributedNotificationCenter 
		defaultCenter];
	[center addObserver:self 
			   selector:@selector(statusChanged:) 
				   name:@"LocalPresenceChangedNotification" 
				 object:nil];
}
@end
