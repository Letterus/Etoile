#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import "COEditingContext.h"
#import "COContainer.h"
#import "COGroup.h"
#import "COStore.h"
#import "TestCommon.h"

@interface TestEditingContext : TestCommon <UKTest>
{
}
@end

/**
  * A class to test the -[COObject didCreate] 
  * method (unfortunately no anonymous classes in
  * this language).
  */
@interface TestCreateExample : COObject
{
	NSInteger didCreateCalled;
}
- (NSInteger)didCreateCalled;
@end

@implementation TestCreateExample
- (NSInteger)didCreateCalled
{
	return didCreateCalled;
}
- (void)didCreate
{
	[super didCreate];
	didCreateCalled++;
}
@end

@implementation TestEditingContext

- (id) init
{
	self = [super init];
	return self;
}
- (void)testCreate
{
	OPEN_STORE(store);
	COEditingContext *ctx = NewContext(store);
	UKNotNil(ctx);
	TearDownContext(ctx);
	CLOSE_STORE(store);
}

- (void)testContextWithNoStore
{
	COEditingContext *ctx = [[COEditingContext alloc] init];

	UKNil([ctx store]);
	/* In case, -latestRevisionNumber sent to a nil store doesn't behave correctly */
	UKIntsEqual(0, [ctx latestRevisionNumber]);
}

- (void)testInsertObject
{
	OPEN_STORE(store)
	COEditingContext *ctx = NewContext(store);
	UKFalse([ctx hasChanges]);
	
	COObject *obj = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	UKNotNil(obj);
	UKTrue([obj isKindOfClass: [COObject class]]);
	
	NSArray *expectedProperties = A(@"name", @"parentContainer", @"parentCollections", @"contents", @"label", @"tags");
	UKObjectsEqual([NSSet setWithArray: expectedProperties],
				   [NSSet setWithArray: [obj persistentPropertyNames]]);

	UKObjectsSame(obj, [ctx objectWithUUID: [obj UUID]]);
	
	UKTrue([ctx hasChanges]);
	
	UKNotNil([obj valueForProperty: @"parentCollections"]);
	UKNotNil([obj valueForProperty: @"contents"]);
	
	TearDownContext(ctx);
	CLOSE_STORE(store);
}

- (void)testBasicPersistence
{
	ETUUID *objUUID;
	
	{
		NSAutoreleasePool *arp = [NSAutoreleasePool new];
		COStore *store = [[COStore alloc] initWithURL: STORE_URL];
		COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
		COObject *obj = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
		objUUID = [[obj UUID] retain];
		[obj setValue: @"Hello" forProperty: @"label"];
		[ctx commit];
		[ctx release];
		[arp drain];
		[store release];
	}
	
	{
		OPEN_STORE(store);
		COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
		COObject *obj = [ctx objectWithUUID: objUUID];
		UKNotNil(obj);
		NSArray *expectedProperties = A(@"name", @"parentContainer", @"parentCollections", @"contents", @"label", @"tags");
		UKObjectsEqual([NSSet setWithArray: expectedProperties],
					   [NSSet setWithArray: [obj persistentPropertyNames]]);
		UKStringsEqual(@"Hello", [obj valueForProperty: @"label"]);
		[ctx release];
		CLOSE_STORE(store);
	}
	[objUUID release];
	DELETE_STORE;
}

- (void)testDidCreate
{
	ETUUID *objUUID;
	
	{
		NSAutoreleasePool *arp = [NSAutoreleasePool new];
		COStore *store = [[COStore alloc] initWithURL: STORE_URL];
		COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
		// Create two objects: one through insertObjectWithEntityName:, the other
		// using the -init call.
		TestCreateExample *obj = (TestCreateExample*)[ctx 
			insertObjectWithEntityName: @"Anonymous.TestCreateExample"];
		TestCreateExample *obj2 = [TestCreateExample new];

		UKIntsEqual(1, [obj didCreateCalled]);

		UKIntsEqual(1, [obj2 didCreateCalled]);
		[obj2 becomePersistentInContext: ctx 
                                     rootObject: obj2];
		UKIntsEqual(1, [obj2 didCreateCalled]);

		objUUID = [[obj UUID] retain];

		[ctx commit];
		[obj2 release];
		[ctx release];
		[arp drain];
		[store release];
	}
	
	{
		OPEN_STORE(store);
		COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
		TestCreateExample *obj = (TestCreateExample*)[ctx objectWithUUID: objUUID];
		UKNotNil(obj);
		UKIntsEqual(0, [obj didCreateCalled]);
		[ctx release];
		CLOSE_STORE(store);
	}
	[objUUID release];
	DELETE_STORE;
}

- (void)testDiscardChanges
{
	OPEN_STORE(store);
	COEditingContext *ctx = NewContext(store);

	UKFalse([ctx hasChanges]);
		
	COObject *o1 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	ETUUID *u1 = [[o1 UUID] retain];
	
	// FIXME: It's not entirely clear what this should do
	[ctx discardAllChanges];
	UKNil([ctx objectWithUUID: u1]);
	
	UKFalse([ctx hasChanges]);
	COObject *o2 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[o2 setValue: @"hello" forProperty: @"label"];
	[ctx commit];
	UKObjectsEqual(@"hello", [o2 valueForProperty: @"label"]);
	
	[o2 setValue: @"bye" forProperty: @"label"];
	[ctx discardAllChanges];
	UKObjectsEqual(@"hello", [o2 valueForProperty: @"label"]);
	
	TearDownContext(ctx);
	CLOSE_STORE(store);
}

- (void)testCopyingBetweenContextsWithNoStoreSimple
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];

	COObject *o1 = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[o1 setValue: @"Shopping" forProperty: @"label"];
	
	COObject *o1copy = [ctx2 insertObject: o1];
	UKNotNil(o1copy);
	UKObjectsSame(ctx1, [o1 editingContext]);
	UKObjectsSame(ctx2, [o1copy editingContext]);
	UKStringsEqual(@"Shopping", [o1copy valueForProperty: @"label"]);

	[ctx1 release];
	[ctx2 release];
}

- (void)testCopyingBetweenContextsWithNoStoreAdvanced
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];
	
	COContainer *parent = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *child = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *subchild = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];

	[parent setValue: @"Shopping" forProperty: @"label"];
	[child setValue: @"Groceries" forProperty: @"label"];
	[subchild setValue: @"Pizza" forProperty: @"label"];
	[child addObject: subchild];
	[parent addObject: child];

	// We are going to copy 'child' from ctx1 to ctx2. It should copy both
	// 'child' and 'subchild', but not 'parent'
	
	COContainer *childCopy = [ctx2 insertObject: child];
	UKNotNil(childCopy);
	UKObjectsSame(ctx2, [childCopy editingContext]);
	UKNil([childCopy valueForProperty: @"parentContainer"]);
	UKStringsEqual(@"Groceries", [childCopy valueForProperty: @"label"]);
	UKNotNil([childCopy contentArray]);
	
	COContainer *subchildCopy = [[childCopy contentArray] firstObject];
	UKNotNil(subchildCopy);
	UKObjectsSame(ctx2, [subchildCopy editingContext]);
	UKStringsEqual(@"Pizza", [subchildCopy valueForProperty: @"label"]);
				   
	[ctx1 release];
	[ctx2 release];
}

- (void)testCopyingBetweenContextsWithSharedStore
{
	OPEN_STORE(store);
	COEditingContext *ctx1 = NewContext(store);
	COEditingContext *ctx2 = [[COEditingContext alloc] initWithStore: [ctx1 store]];
	
	COContainer *parent = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *child = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *subchild = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	
	[parent setValue: @"Shopping" forProperty: @"label"];
	[child setValue: @"Groceries" forProperty: @"label"];
	[subchild setValue: @"Pizza" forProperty: @"label"];
	[child addObject: subchild];
	[parent addObject: child];
	
	[ctx1 commit];
	
	// We won't commit this
	[parent setValue: @"Todo" forProperty: @"label"];
	
	// We'll add another sub-child and leave it uncommitted.
	COContainer *subchild2 = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[subchild2 setValue: @"Salad" forProperty: @"label"];
	[child addObject: subchild2];
	
	// We are going to copy 'child' from ctx1 to ctx2. It should copy
	// 'child', 'subchild', and 'subchild2', but not 'parent' (so 
	// renaming parent from "Shopping" to "Todo" should not be propagated.)
	
	COContainer *childCopy = [ctx2 insertObject: child];
	UKNotNil(childCopy);
	UKObjectsSame(ctx2, [childCopy editingContext]);
	UKObjectsEqual([parent UUID], [[childCopy valueForProperty: @"parentContainer"] UUID]);
	UKStringsEqual(@"Shopping", [[childCopy valueForProperty: @"parentContainer"] valueForProperty: @"label"]);
	UKStringsEqual(@"Groceries", [childCopy valueForProperty: @"label"]);
	UKNotNil([childCopy contentArray]);
	UKIntsEqual(2, [[childCopy contentArray] count]);
	if (2 == [[childCopy contentArray] count])
	{
		COContainer *subchildCopy = [[childCopy contentArray] firstObject];
		UKNotNil(subchildCopy);
		UKObjectsSame(ctx2, [subchildCopy editingContext]);
		UKStringsEqual(@"Pizza", [subchildCopy valueForProperty: @"label"]);
		
		COContainer *subchild2Copy = [[childCopy contentArray] objectAtIndex: 1];
		UKNotNil(subchild2Copy);
		UKObjectsSame(ctx2, [subchild2Copy editingContext]);
		UKStringsEqual(@"Salad", [subchild2Copy valueForProperty: @"label"]);
	}
	[ctx2 release];
	TearDownContext(ctx1);
	CLOSE_STORE(store);
}


- (void)testCopyingBetweenContextsCornerCases
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];
	
	COObject *o1 = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[o1 setValue: @"Shopping" forProperty: @"label"];
	
	COObject *o1copy = [ctx2 insertObject: o1];
	
	// Insert again
	COObject *o1copy2 = [ctx2 insertObject: o1];
	UKObjectsSame(o1copy, o1copy2);
	
	//FIXME: Should inserting again copy over new changes (if any)?
	
	[ctx1 release];
	[ctx2 release];
}

- (void)testCopyingBetweenContextsWithManyToMany
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];

	COGroup *tag1 = [ctx1 insertObjectWithEntityName: @"Anonymous.Tag"];
	COContainer *child = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];

	[tag1 addObject: child];

	// Copy the tag collection to ctx2. At first it will be empty since child isn't in ctx2 yet
	
	COGroup *tag1copy = [ctx2 insertObject: tag1];
	UKObjectsEqual([NSArray array], [tag1copy contentArray]);
	
	COContainer *childcopy = [ctx2 insertObject: child];
	UKObjectsEqual([NSArray arrayWithObject: childcopy], [tag1copy contentArray]);
	
	[ctx1 release];
	[ctx2 release];
}

@end
