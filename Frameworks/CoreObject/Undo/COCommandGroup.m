#import "COCommandGroup.h"
#import "COCommand.h"
#import "COCommandSetCurrentVersionForBranch.h"
#import "CORevision.h"
#import <EtoileFoundation/Macros.h>

static NSString * const kCOCommandContents = @"COCommandContents";

@implementation COCommandGroup

@synthesize contents = _contents;

+ (void) initialize
{
	if (self != [COCommandGroup class])
		return;
	
	[self applyTraitFromClass: [ETCollectionTrait class]];
}

- (id)init
{
    SUPERINIT;
    _contents = [[NSMutableArray alloc] init];
    return self;
}

- (id) initWithPlist: (id)plist
{
    SUPERINIT;
    
    NSMutableArray *edits = [NSMutableArray array];
    for (id editPlist in [plist objectForKey: kCOCommandContents])
    {
        COCommand *subEdit = [COCommand commandWithPlist: editPlist];
        [edits addObject: subEdit];
    }
    
    self.contents = edits;
    return self;
}

- (id) plist
{
    NSMutableDictionary *result = [super plist];
    
    NSMutableArray *edits = [NSMutableArray array];
    for (COCommand *subEdit in _contents)
    {
        id subEditPlist = [subEdit plist];
        [edits addObject: subEditPlist];
    }
    [result setObject: edits forKey: kCOCommandContents];
    return result;
}

- (COCommand *) inverse
{
    COCommandGroup *inverse = [[COCommandGroup alloc] init];
    
    NSMutableArray *edits = [NSMutableArray array];
    for (COCommand *subEdit in _contents)
    {
        COCommand *subEditInverse = [subEdit inverse];
        [edits addObject: subEditInverse];
    }
    inverse.contents = edits;
    
    return inverse;
}

- (BOOL) canApplyToContext: (COEditingContext *)aContext
{
    for (COCommand *subEdit in _contents)
    {
        if (![subEdit canApplyToContext: aContext])
        {
            return NO;
        }
    }
    return YES;
}

- (void) applyToContext: (COEditingContext *)aContext
{
    for (COCommand *subEdit in _contents)
    {
        [subEdit applyToContext: aContext];
    }
}

#pragma mark -
#pragma mark Track Node Protocol

- (ETUUID *)UUID
{
	return nil;
}

- (ETUUID *)persistentRootUUID
{
	return nil;
}

- (ETUUID *)branchUUID
{
	return nil;
}

- (NSDate *)date
{
	return [[_contents firstObject] date];
}

- (NSDictionary *)metadata
{
	for (COCommand *command in _contents)
	{
		BOOL hasRevision =
			[command isKindOfClass: [COCommandSetCurrentVersionForBranch class]];

		if (hasRevision)
		{
			return [(COCommandSetCurrentVersionForBranch *)command metadata];
		}
	}
	return nil;
}

- (NSString *)type
{
	return [(COCommand *)[_contents firstObject] type];
}

- (NSString *)shortDescription;
{
	return [[self metadata] objectForKey: @"shortDescription"];
}

#pragma mark -
#pragma mark Collection Protocol

- (BOOL)isOrdered
{
	return YES;
}

- (id)content
{
	return _contents;
}

- (NSArray *)contentArray
{
	return [NSArray arrayWithArray: [self content]];
}

@end
