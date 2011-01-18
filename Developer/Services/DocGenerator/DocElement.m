/*
	Copyright (C) 2008 Nicolas Roard

	Authors:  Nicolas Roard,
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import "DocElement.h"
#import "DocDescriptionParser.h"
#import "DocIndex.h"
#import "HtmlElement.h"
#import "DocParameter.h"

@implementation DocElement

@synthesize name, task, taskUnit, filteredDescription, ownerSymbolName;

- (id) init
{
	SUPERINIT;
	rawDescription = [NSMutableString new];
	return self;
}

- (void) dealloc
{
	[rawDescription release];
	[filteredDescription release];
	[name release];
	[task release];
	[taskUnit release];
	[ownerSymbolName release];
	[super dealloc];
}

+ (NSString *) defaultTask
{
	return @"Default";
}

- (NSString *) task
{
	if (task != nil)
	{
		return task;
	}
	else if (taskUnit != nil)
	{
		ETAssert(task == nil);
		return taskUnit;
	}
	else
	{
		return [[self class] defaultTask];
	}
}

- (void) setTask: (NSString *)aTask
{
	if ([aTask isEqualToString: @""])
	{
		ASSIGN(task, nil);
	}
	else
	{
		ASSIGN(task, aTask);
	}
}

- (void) setTaskUnit: (NSString *)aTask
{
	if ([aTask isEqualToString: @""])
	{
		ASSIGN(taskUnit, nil);
	}
	else
	{
		ASSIGN(taskUnit, aTask);
	}
}

- (id) copyWithZone: (NSZone *)aZone
{
	DocElement *copy = [[self class] allocWithZone: aZone];

	copy->rawDescription = [rawDescription mutableCopyWithZone: aZone];
	ASSIGN(copy->filteredDescription, filteredDescription);
	ASSIGN(copy->name, name);
	ASSIGN(copy->task, task);

	return copy;
}

- (NSComparisonResult) caseInsensitiveCompare: (NSString *)aString
{
	return [aString caseInsensitiveCompare: name];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
		[self name], [self task]];
}

+ (NSString *) forthcomingDescription
{
	return @"<em>Description forthcoming.</em>";
}

- (void) appendToRawDescription: (NSString *)aDescription
{
	[rawDescription appendString: aDescription];
}

- (NSString *) rawDescription
{
	return rawDescription;
}

- (void) setFilteredDescription: (NSString *)aDescription
{
	/* We remove white spaces and newlines to prevent many empty words when 
	   breaking the description into words in -insertLinksWithDocIndex:forString:
	   Without it, it won't parse '-[Class \nblabla]'. */
	NSString *trimmedDesc = [aDescription stringByTrimmingWhitespacesAndNewlinesByLine];

	if (IS_NIL_OR_EMPTY_STR(trimmedDesc))
	{
		trimmedDesc = [[self class] forthcomingDescription];
	}
	ASSIGN(filteredDescription, trimmedDesc);
}

- (void) addInformationFrom: (DocDescriptionParser *)aParser
{
	[self setFilteredDescription: [aParser description]];
	[self setTask: [aParser task]];
	[self setTaskUnit: [aParser taskUnit]];
}

- (NSMutableArray *) wordsFromString: (NSString *)aDescription
{
	NSCharacterSet *spaceCharset = [NSCharacterSet whitespaceCharacterSet];
	NSArray *lines = [aDescription componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	NSUInteger estimatedMaxDescWordSize = 10000;
	NSMutableArray *allWords = [NSMutableArray arrayWithCapacity: estimatedMaxDescWordSize];
	BOOL treatAsSingleWord = NO;

	for (NSString *line in lines)
	{
		/* <pre> corresponds to  <example> in the doc comment */
		if ([line hasPrefix: @"<pre>"])
		{
			treatAsSingleWord = YES;
			[allWords addObject: [NSMutableString stringWithFormat: @"\n%@\n", line]];
		}
		else if ([line hasPrefix: @"</pre>"])
		{
			treatAsSingleWord = NO;
			[[allWords lastObject] appendString: line];
			[[allWords lastObject] appendString: @"\n"];
		}
		else if (treatAsSingleWord)
		{
			[[allWords lastObject] appendString: line];
			[[allWords lastObject] appendString: @"\n"];
		}
		else
		{
			NSArray *lineWords = [line componentsSeparatedByCharactersInSet: spaceCharset];
			[allWords addObjectsFromArray: lineWords];
		}
	}

	return allWords;
}

- (NSString *) methodLinkWithDocIndex: (DocIndex *)aDocIndex 
	word: (NSString *)word atIndex: (int)i inWords: (NSMutableArray *)descWords
{
	unichar secondChar = [word characterAtIndex: 1];
	BOOL isFullMethodRef = (secondChar == '[' && i + 1 < [descWords count]);

	if (isFullMethodRef)
	{
		NSString *nextWord = [descWords objectAtIndex: i + 1];

		/* A trimming use case is 'weaveSelector].</p>' to 'weaveSelector]' */
		NSArray *nextWordParts = [nextWord componentsSeparatedByString: @"]"];

		/* It makes no sense to have more than a single ] in 
		   'weaveSelector].</p>' or similar, so we disallow it.
		   See also -setFilteredDescription:. */
		ETAssert([nextWordParts count] == 2);

		NSString *methodWord = [nextWordParts firstObject];
		NSString *symbol = [NSString stringWithFormat: @"%@ %@]", word, methodWord];

		[descWords replaceObjectAtIndex: i + 1 
							 withObject: [nextWordParts lastObject]];

		return [aDocIndex linkForSymbolName: symbol ofKind: @"methods"];
	}
	else
	{
		return [aDocIndex linkForLocalMethodRef: word relativeTo: self];
	}
	return nil;
}

/* In most cases, no link is created and link is the same than symbol */
- (NSString *) otherLinkWithDocIndex: (DocIndex *)aDocIndex symbolName: (NSString *)symbol
{

	NSString *link = [aDocIndex linkForClassName: symbol];
	BOOL linkCreated = (link != symbol);

	if (linkCreated)
		return link;

	link = [aDocIndex linkForProtocolName: symbol];

	return link;
}

- (NSString *) insertLinksWithDocIndex: (DocIndex *)aDocIndex forString: (NSString *)aDescription 
{
	NSMutableArray *descWords = [self wordsFromString: aDescription];
	NSMutableCharacterSet *punctCharset = [NSMutableCharacterSet punctuationCharacterSet];

	/* [ and ] don't have to be removed, they are not included in this charset */
	[punctCharset removeCharactersInString: @"-+"];

	for (int i = 0; i < [descWords count]; i++)
	{
		NSString *word = [descWords objectAtIndex: i];
		NSUInteger length = [word length];
		NSRange r = NSMakeRange(0, length);
		BOOL usesSubword = NO;
		NSString *symbol = word;
		NSString *link =  nil;
		unichar firstChar = '\0';
		
		if (r.length > 2)
			firstChar = [word characterAtIndex: 0];

		/* We want to trim some common punctuation patterns e.g.
		   - word
		   - (word
		   - word),
		   TODO: But we need to handle square bracket use specially. For square 
		   brackets, we detect [Class], [(Protocol)], -[Class method], 
		   +[Class method], -[(Protocol) method], +[(Protocol) method] */
		if (r.length >= 2 && [punctCharset characterIsMember: firstChar])
		{
			r.location++;
			r.length--;
			usesSubword = YES;
		}

		BOOL isPotentialMethodLink = (firstChar == '+' || firstChar == '-');
	
		if (isPotentialMethodLink)
		{
			[punctCharset removeCharactersInString: @":)"];
		}
		if (r.length >= 2 && [punctCharset characterIsMember: [word characterAtIndex: length - 1]])
		{
			r.length--;
			if ([punctCharset characterIsMember: [word characterAtIndex: length - 2]])
			{
				r.length--;
			}
			usesSubword = YES;
		}

		if (usesSubword)
		{
			symbol = [word substringWithRange: r];
		}

		if (isPotentialMethodLink)
		{
			link = [self methodLinkWithDocIndex: aDocIndex word: symbol atIndex: i inWords: descWords];
			[punctCharset addCharactersInString: @":)"];
		}
		else
		{
			link = [self otherLinkWithDocIndex: aDocIndex symbolName: symbol];
		}

		NSString *finalWord = link;

		if (usesSubword)
		{
			finalWord = [word stringByReplacingCharactersInRange: r withString: link];
		}

		[descWords replaceObjectAtIndex: i withObject: finalWord];
	}

	return [descWords componentsJoinedByString: @" "];
}

- (void) replaceDocSectionsWithHTMLInString: (NSMutableString *)description
{
	NSRange searchRange = NSMakeRange(0, [description length]);
	NSRange sectionTagRange = [description rangeOfString: @"@section" options: 0 range: searchRange];

	while (sectionTagRange.location != NSNotFound)	
	{
		ETAssert(sectionTagRange.length == 8);

		NSRange openingTagRange = [description rangeOfString: @"<p>" options: NSBackwardsSearch range: NSMakeRange(0, sectionTagRange.location)];
		NSRange closingTagRange = [description rangeOfString: @"</p>" options: 0 range: NSMakeRange(sectionTagRange.location, [description length] - sectionTagRange.location)];

		/* We don't replace the opening tag first, otherwise the closing tag range must be adjusted */
		[description replaceCharactersInRange: closingTagRange withString: @"</h4>"];
		[description replaceCharactersInRange: NSUnionRange(openingTagRange, sectionTagRange) withString: @"<h4>"];

		/* We don't start right after </h3> to avoid any complex range computation */
		searchRange = NSMakeRange(openingTagRange.location, [description length] - openingTagRange.location);
		sectionTagRange = [description rangeOfString: @"@section" options: 0 range: searchRange];
	}
}

- (void) replaceBasicDocMarkupWithHTMLInString: (NSMutableString *)description
{
 	NSDictionary *htmlTagSubstitutions = D(@"pre>", @"example>", @"var>", @"code>"); 

	for (NSString *tag in htmlTagSubstitutions)
	{
		[description replaceOccurrencesOfString: tag 
		                             withString: [htmlTagSubstitutions objectForKey: tag]
		                                options: NSCaseInsensitiveSearch
		                                  range: NSMakeRange(0, [description length])];
	}
}

- (NSString *) HTMLDescriptionWithDocIndex: (DocHTMLIndex *)aDocIndex
{
	NSMutableString *description = [NSMutableString stringWithString: [self filteredDescription]];

	if ([description rangeOfString: @"<example>"].location != NSNotFound)
	{
		NSLog(@"bla");	
	}

	[self replaceBasicDocMarkupWithHTMLInString: description];
	[self replaceDocSectionsWithHTMLInString: description];

	return [self insertLinksWithDocIndex: aDocIndex forString: description];
}

- (HtmlElement *) HTMLRepresentation
{
	return [HtmlElement blankElement];
}

- (NSString *) GSDocElementName
{
	return nil;
}

- (SEL) weaveSelector
{
	return NULL;
}

@end


@implementation DocSubroutine

- (id) init
{
	SUPERINIT;
	parameters = [NSMutableArray new];
	return self;
}

- (void) dealloc
{
	[parameters release];
	[returnType release];
	[super dealloc];
}

- (void) addInformationFrom: (DocDescriptionParser *)aParser
{
	[super addInformationFrom: aParser];

	FOREACH(parameters, p, DocParameter *)
	{
		[p setDescription: [aParser descriptionForParameter: [p name]]];
	}
	//NSLog (@"Parser return description <%@>", [aParser returnDescription]);
}

- (void) setReturnType: (NSString *) aReturnType
{
	ASSIGN(returnType, aReturnType);
}

- (DocParameter *) returnParameter
{
	return [DocParameter newWithName: nil andType: returnType];
}

- (void) addParameter: (DocParameter *)aParameter
{
	[parameters addObject: aParameter];
}

- (NSArray *) parameters
{
	return [NSArray arrayWithArray: parameters];
}

@end
