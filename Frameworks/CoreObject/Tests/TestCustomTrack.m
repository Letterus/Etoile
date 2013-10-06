#import <UnitKit/UnitKit.h>
#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import "TestCommon.h"

@interface TestCustomTrack : EditingContextTestCase <UKTest>
{
    COUndoStack *_testStack;
    COUndoStack *_setupStack;
}
@end

@implementation TestCustomTrack

- (id)init
{
	SUPERINIT;
    
    _testStack =  [[COUndoStackStore defaultStore] stackForName: @"test"];
    _setupStack =  [[COUndoStackStore defaultStore] stackForName: @"setup"];
    [_testStack setEditingContext: ctx];
	[_setupStack setEditingContext: ctx];
    [_testStack clear];
    [_setupStack clear];
    
	return self;
}


/* The custom track uses the root object commit track to undo and redo, no 
selective undo is involved. */
- (void)testUndoWithSinglePersistentRoot
{
	/* First commit */

	COContainer *object = [[ctx insertNewPersistentRootWithEntityName: @"Anonymous.OutlineItem"] rootObject];
	[object setValue: @"Groceries" forProperty: @"label"];
    [ctx commitWithUndoStack: _setupStack];
    CORevision *firstRevision = [[[object persistentRoot] currentBranch] currentRevision];
    
	/* Second commit */

	[object setValue: @"Shopping List" forProperty: @"label"];
    [ctx commitWithUndoStack: _testStack];
    CORevision *secondRevision = [[[object persistentRoot] currentBranch] currentRevision];
    
	/* Third commit */

	[object setValue: @"Todo" forProperty: @"label"];
    [ctx commitWithUndoStack: _testStack];
    CORevision *thirdRevision = [[[object persistentRoot] currentBranch] currentRevision];
    
	/* First undo  (Todo -> Shopping List) */

	UKTrue([_testStack canUndo]);
	[_testStack undo];
    
	UKStringsEqual(@"Shopping List", [object valueForProperty: @"label"]);
	UKObjectsEqual(secondRevision, [[object persistentRoot] revision]);

	/*  Second undo (Shopping List -> Groceries) */

    UKTrue([_testStack canUndo]);
	[_testStack undo];
	UKFalse([_testStack canUndo]);
    
	UKStringsEqual(@"Groceries", [object valueForProperty: @"label"]);
	UKObjectsEqual(firstRevision, [[object persistentRoot] revision]);

	/* First redo (Groceries -> Shopping List) */

	UKTrue([_testStack canRedo]);
	[_testStack redo];

	UKStringsEqual(@"Shopping List", [object valueForProperty: @"label"]);
	UKObjectsEqual(secondRevision, [[object persistentRoot] revision]);

	/* Second redo (Shopping List -> Todo) */

	UKTrue([_testStack canRedo]);
	[_testStack redo];
	UKFalse([_testStack canRedo]);
    
	UKStringsEqual(@"Todo", [object valueForProperty: @"label"]);
	UKObjectsEqual(thirdRevision, [[object persistentRoot] revision]);
}

- (NSArray *)makeCommitsWithMultiplePersistentRoots
{
    /*
                 commit #:    1   2   3   4   5   6
     
     objectPersistentRoot:    x-------x---x--------
     
        docPersistentRoot:        x---x-------x---x
     
     */
    
    
	/* First commit */

	COPersistentRoot *objectPersistentRoot = [ctx insertNewPersistentRootWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *object = [objectPersistentRoot rootObject];
	[object setValue: @"Groceries" forProperty: @"label"];

    [ctx commitWithUndoStack: _testStack];
    
	/* Second commit */

    COPersistentRoot *docPersistentRoot = [ctx insertNewPersistentRootWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *doc = [docPersistentRoot rootObject];
	[doc setValue: @"Document" forProperty: @"label"];

	[ctx commitWithUndoStack: _testStack];

	/* Third commit call (creates commits in objectPersistentRoot and docPersistentRoot) */

	COContainer *para1 = [[doc objectGraphContext] insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[para1 setValue: @"paragraph 1" forProperty: @"label"];
    [doc addObject: para1];
	[object setValue: @"Shopping List" forProperty: @"label"];

	[ctx commitWithUndoStack: _testStack];

	/* Fourth commit */

	[object setValue: @"Todo" forProperty: @"label"];

	[ctx commitWithUndoStack: _testStack];

	/* Fifth commit */

	COContainer *para2 = [[doc objectGraphContext] insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[para2 setValue: @"paragraph 2" forProperty: @"label"];
	[doc addObject: para2];

	[ctx commitWithUndoStack: _testStack];

	/* Sixth commit */

	[para1 setValue: @"paragraph with different contents" forProperty: @"label"];

	[ctx commitWithUndoStack: _testStack];

	return A(object, doc, para1, para2);
}

- (void)testUndoWithMultiplePersistentRoots
{
	NSArray *objects = [self makeCommitsWithMultiplePersistentRoots];

	OutlineItem *object = [objects objectAtIndex: 0];
	OutlineItem *doc = [objects objectAtIndex: 1];
	OutlineItem *para1 = [objects objectAtIndex: 2];
	OutlineItem *para2 = [objects objectAtIndex: 3];

    COPersistentRoot *objectPersistentRoot = [object persistentRoot];
    UKNotNil(objectPersistentRoot);
    
    COPersistentRoot *docPersistentRoot = [doc persistentRoot];
    UKNotNil(docPersistentRoot);
    
    UKObjectsNotEqual(docPersistentRoot, objectPersistentRoot);
    
	/* Basic undo/redo check */

	[_testStack undo];
	UKStringsEqual(@"paragraph 1", [para1 valueForProperty: @"label"]);
	
	[_testStack redo];
	UKStringsEqual(@"paragraph with different contents", [para1 valueForProperty: @"label"]);
    
	/* Sixth and fifth commit undone ('doc' revision) */
    
    UKNotNil([docPersistentRoot objectWithUUID: [para2 UUID]]);
    UKObjectsEqual((@[para1, para2]), [doc contents]);
	[_testStack undo];
	[_testStack undo];
	UKStringsEqual(@"paragraph 1", [para1 valueForProperty: @"label"]);
	UKNil([docPersistentRoot objectWithUUID: [para2 UUID]]);
	UKObjectsEqual(@[para1], [doc contents]);

	/* Fourth commit undone ('object' revision) */

	[_testStack undo];
	UKStringsEqual(@"Shopping List", [object valueForProperty: @"label"]);

	/* Third commit call undone (two underlying commits, one on 'doc' and one on 'object') */

    UKNotNil([docPersistentRoot objectWithUUID: [para1 UUID]]);
	[_testStack undo];
	UKNil([docPersistentRoot objectWithUUID: [para1 UUID]]);
    UKObjectsEqual(@[], [doc contents]);
	UKStringsEqual(@"Groceries", [object valueForProperty: @"label"]);

	/* Second commit undone ('doc' revision) */

	[_testStack undo];
    UKTrue(docPersistentRoot.isDeleted);
    
	/***********************************************/
	/* First commit reached (root object 'object') */
    /***********************************************/
    
	// Just check the object creation hasn't been undone
	UKNotNil([objectPersistentRoot objectWithUUID: [object UUID]]);
	UKStringsEqual(@"Groceries", [object valueForProperty: @"label"]);

	/* Second commit redone */

	[_testStack redo];
    UKFalse(docPersistentRoot.isDeleted);
	UKNotNil([docPersistentRoot objectWithUUID: [doc UUID]]);
	UKObjectsSame(doc, [docPersistentRoot objectWithUUID: [doc UUID]]);
	UKStringsEqual(@"Document", [doc valueForProperty: @"label"]);

	/* Third commit redone (involve two underlying commits) */

	[_testStack redo];
	UKStringsEqual(@"Shopping List", [object valueForProperty: @"label"]);

	/* Third commit undone (involve two underlying commits)  */

	[_testStack undo];
	UKStringsEqual(@"Groceries", [object valueForProperty: @"label"]);

	/* Third commit redone (involve two underlying commits) */

	[_testStack redo];
	UKNotNil([docPersistentRoot objectWithUUID: [para1 UUID]]);
	UKObjectsNotSame(para1, [docPersistentRoot objectWithUUID: [para1 UUID]]);

	// Get the new restored object instance
	para1 = (OutlineItem *)[docPersistentRoot objectWithUUID: [para1 UUID]];
    UKObjectsEqual(@[para1], [doc contents]);
	UKStringsEqual(@"paragraph 1", [para1 valueForProperty: @"label"]);

	/* Fourth, fifth and sixth commits redone */

	[_testStack redo];
    [_testStack redo];
    [_testStack redo];
    UKFalse([_testStack canRedo]);
	UKStringsEqual(@"Todo", [object valueForProperty: @"label"]);
	UKStringsEqual(@"paragraph with different contents", [para1 valueForProperty: @"label"]);
	UKNotNil([docPersistentRoot objectWithUUID: [para2 UUID]]);
	UKObjectsNotSame(para2, [docPersistentRoot objectWithUUID: [para2 UUID]]);

	// Get the new restored object instance
	para2 = (OutlineItem *)[docPersistentRoot objectWithUUID: [para2 UUID]];
    UKObjectsEqual((@[para1, para2]), [doc contents]);
	UKStringsEqual(@"paragraph 2", [para2 valueForProperty: @"label"]);
}

@end
