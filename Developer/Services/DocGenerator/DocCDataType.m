/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import <objc/runtime.h>
#import "DocCDataType.h"
#import "DescriptionParser.h"
#import "DocIndex.h"
#import "HtmlElement.h"
#import "Parameter.h"

@implementation DocCDataType

@synthesize type;

- (void) dealloc
{
	DESTROY(type);
	[super dealloc];
}

- (BOOL) isConstant
{
	return ([type hasPrefix: @"enum"] || [type hasPrefix: @"union"] 
		|| [type hasPrefix: @"const"] || [type hasSuffix: @"const"]);
}

- (void) turnIntoDocConstantIfNeeded
{
	if ([self isConstant])
	{
		object_setClass(self, [DocConstant class]);
	}
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict
{
	if ([elementName isEqualToString: [self GSDocElementName]]) /* Opening tag */
	{
		BEGINLOG();
		[self setType: [attributeDict objectForKey: @"type"]];
		[self setName: [attributeDict objectForKey: @"name"]];
	}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	if ([elementName isEqualToString: @"desc"]) 
	{
		[self appendToRawDescription: trimmed];
		CONTENTLOG();
	}
	else if ([elementName isEqualToString: [self GSDocElementName]]) /* Closing tag */
	{
		DescriptionParser* descParser = [DescriptionParser new];
		
		[descParser parse: [self rawDescription]];
		
		//NSLog(@"C Data Type raw description <%@>", [self rawDescription]);
		
		[self addInformationFrom: descParser];
		[descParser release];

		/* Switch the class to get the right -weaveSelector */
		[self turnIntoDocConstantIfNeeded];
		[(id)[parser weaver] performSelector: [self weaveSelector] withObject: self];
		
		ENDLOG2(name, [self task]);
	}
}

- (NSString *) GSDocElementName
{
	return @"type";
}

- (SEL) weaveSelector
{
	return @selector(weaveOtherDataType:);
}

- (NSString *) formattedType
{
	return [self type];

	// TODO: Fix or remove... This code wrongly truncates the types.
	// TODO: Insert links in the returned type
	Parameter *formatter = [Parameter newWithName: nil andType: [self type]];
	NSString *formattedType = @"";

	if ([formatter typePrefix] != nil)
	{
		formattedType = [formattedType stringByAppendingString: [formatter typePrefix]];	
	}
	if ([formatter typeSuffix] != nil)
	{
		if ([formattedType length] != 0)
		{
			formattedType = [formattedType stringByAppendingFormat: @"%@ %@", @"", [formatter typeSuffix]];
		}
		else
		{
			formattedType = [formattedType stringByAppendingString: [formatter typeSuffix]];
		}
	}

	return formattedType;
}

- (HtmlElement *) HTMLRepresentation
{
	// TODO: Use more correct span class names
	H hType = [SPAN class: @"returnType" with: [SPAN class: @"type" with: [self formattedType]]];
	H hSymbolName = [SPAN class: @"selector" with: @" " and: [self name]];
	H hDesc = [DIV class: @"methodDescription" with: [self HTMLDescriptionWithDocIndex: [DocIndex currentIndex]]];
	H hDataType = [DIV class: @"method" with: [DL with: [DT with: hType and: hSymbolName]
	                                               and: [DD with: hDesc]]];

	return hDataType;
}

@end


@implementation DocConstant

- (NSString *) GSDocElementName
{
	return @"constant";
}

- (SEL) weaveSelector
{
	return @selector(weaveConstant:);
}


@end
