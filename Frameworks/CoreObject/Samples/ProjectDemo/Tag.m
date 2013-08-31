#import <EtoileFoundation/EtoileFoundation.h>

#import "Tag.h"

@implementation Tag

+ (void)initialize
{
	if (self == [Tag class])
	{
		ETEntityDescription *tag = [ETEntityDescription descriptionWithName: @"Tag"];
		
		ETPropertyDescription *labelProperty = [ETPropertyDescription descriptionWithName: @"label"
																							  type: (id)@"Anonymous.NSString"];
		
		[tag setPropertyDescriptions: A(labelProperty)];
		
		[[ETModelDescriptionRepository mainRepository] addUnresolvedDescription: tag];
		[[ETModelDescriptionRepository mainRepository] setEntityDescription: tag
																   forClass: self];
		
		[[ETModelDescriptionRepository mainRepository] resolveNamedObjectReferences];
	}
}


/* Accessor Methods */

- (NSString*)label
{
	[self willAccessValueForProperty: @"label"];
	return label;
}
- (void)setLabel:(NSString *)l
{
	[self willChangeValueForProperty: @"label"];
	ASSIGN(label, l);
	[self didChangeValueForProperty: @"label"];
}

@end