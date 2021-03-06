/*
	Copyright (C) 2013 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>, 
	         Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>

#import "COUndoStackStore.h"
#import "COUndoTrack.h"
#import "COEditingContext+Undo.h"
#import "COEditingContext+Private.h"
#import "COCommand.h"
#import "COEndOfUndoTrackPlaceholderNode.h"

NSString * const COUndoStackDidChangeNotification = @"COUndoStackDidChangeNotification";
NSString * const kCOUndoStackName = @"COUndoStackName";

@interface COPatternUndoTrack : COUndoTrack
@end


@interface COUndoTrack ()
@property (strong, readwrite, nonatomic) COUndoStackStore *store;
@property (strong, readwrite, nonatomic) NSString *name;
@end

@implementation COUndoTrack

@synthesize name = _name, store = _store, editingContext = _editingContext;

#pragma mark -
#pragma mark Initialization

+ (void) initialize
{
	if (self != [COUndoTrack class])
		return;

	[self applyTraitFromClass: [ETCollectionTrait class]];
}

+ (COUndoTrack *)trackForName: (NSString *)aName
           withEditingContext: (COEditingContext *)aContext
{
	return [[self alloc] initWithStore: [COUndoStackStore defaultStore]
	                              name: aName
	                    editingContext: aContext];
}

+ (COUndoTrack *)trackForPattern: (NSString *)aPattern
              withEditingContext: (COEditingContext *)aContext
{
	return [[COPatternUndoTrack alloc] initWithStore: [COUndoStackStore defaultStore]
	                                            name: aPattern
	                                  editingContext: aContext];
}

- (id) initWithStore: (COUndoStackStore *)aStore
                name: (NSString *)aName
	  editingContext: (COEditingContext *)aContext
{
    SUPERINIT;
    _name = aName;
    _store = aStore;
	_editingContext = aContext;
    return self;
}

- (NSArray *) undoNodes
{
    return [_store stackContents: kCOUndoStack forName: _name];
}

- (NSArray *) redoNodes
{
    return [_store stackContents: kCORedoStack forName: _name];
}

#pragma mark -
#pragma mark Undo and Redo

- (BOOL)canUndo
{
    COCommand *edit = [self peekEditFromStack: kCOUndoStack forName: _name];
    return [self canApplyEdit: edit toContext: _editingContext];
}

- (BOOL)canRedo
{
    COCommand *edit = [self peekEditFromStack: kCORedoStack forName: _name];
    return [self canApplyEdit: edit toContext: _editingContext];
}

- (void)undo
{
    [self popAndApplyFromStack: kCOUndoStack pushToStack: kCORedoStack name: _name toContext: _editingContext];
	[self didUpdate];
}

- (void)redo
{
    [self popAndApplyFromStack: kCORedoStack pushToStack: kCOUndoStack name: _name toContext: _editingContext];
	[self didUpdate];
}

#pragma mark -
#pragma mark Managing Commands

- (void) clear
{
    [_store clearStack: kCOUndoStack forName: _name];
    [_store clearStack: kCORedoStack forName: _name];
	[_commands removeAllObjects];
}

- (COCommand *) peekEditFromStack: (NSString *)aStack forName: (NSString *)aName
{
    id plist = [_store peekStack: aStack forName: aName];
    if (plist == nil)
    {
        return nil;
    }
    
    COCommand *edit = [COCommand commandWithPlist: plist];
    return edit;
}

- (BOOL) canApplyEdit: (COCommand*)anEdit toContext: (COEditingContext *)aContext
{
    if (anEdit == nil)
    {
        return NO;
    }
    
    return [anEdit canApplyToContext: aContext];
}

- (BOOL) popAndApplyFromStack: (NSString *)popStack
                  pushToStack: (NSString*)pushStack
                         name: (NSString *)aName
                    toContext: (COEditingContext *)aContext
{
    [_store beginTransaction];
    
    NSString *actualStackName = [_store peekStackName: popStack forName: aName];
	BOOL isUndo = [popStack isEqual: kCOUndoStack];
    COCommand *edit = [self peekEditFromStack: popStack forName: aName];
	COCommand *appliedEdit = (isUndo ? [edit inverse] : edit);

    if (![self canApplyEdit: appliedEdit toContext: aContext])
    {
        // DEBUG: Break here
        edit = [self peekEditFromStack: popStack forName: aName];
		appliedEdit =  (isUndo ? [edit inverse] : edit);
        [self canApplyEdit: appliedEdit toContext: aContext];
        
        [_store commitTransaction];
        [NSException raise: NSInvalidArgumentException format: @"Can't apply edit %@", edit];
    }
    
    // Pop from undo track
    [_store popStack: popStack forName: aName];
    
    // Apply the edit
    [appliedEdit applyToContext: aContext];
    
    // N.B. This must not automatically push a revision
    aContext.isRecordingUndo = NO;
	// TODO: If we can detect a non-selective undo and -commit returns a command,
	// we could implement -validateUndoCommitWithCommand: to ensure there is no
	// command COCommandCreatePersistentRoot or COCommandNewRevisionForBranch
	// that create new revisions in the store.
    [aContext commit];
    aContext.isRecordingUndo = YES;
    
    [_store pushAction: [edit plist] stack: pushStack forName: actualStackName];
    
    return [_store commitTransaction];
}

- (void) recordCommand: (COCommand *)aCommand
{
	NILARG_EXCEPTION_TEST(aCommand);
	// TODO: A SQL constraint and batch UUID would prevent pushing a command twice more strictly.
	INVALIDARG_EXCEPTION_TEST(aCommand, [aCommand isEqual: [self currentCommand]] == NO);

	[self discardRedoCommands];
	[self addNewUndoCommand: aCommand];
	[self didUpdate];
}

- (void) postNotificationsForStackName: (NSString *)aStack
{
    NSDictionary *userInfo = @{kCOUndoStackName : aStack};
    
    [[NSNotificationCenter defaultCenter] postNotificationName: COUndoStackDidChangeNotification
                                                        object: self
                                                      userInfo: userInfo];
    
    //    [[NSDistributedNotificationCenter defaultCenter] postNotificationName: COStorePersistentRootDidChangeNotification
    //                                                                   object: [[self UUID] stringValue]
    //                                                                 userInfo: userInfo
    //                                                       deliverImmediately: NO];
}

#pragma mark -
#pragma mark Track Protocol

- (void)didUpdate
{
	[[NSNotificationCenter defaultCenter] 
		postNotificationName: ETCollectionDidUpdateNotification object: self];
    [self postNotificationsForStackName: _name];
}

- (void)discardRedoCommands
{
	[_store clearStack: kCORedoStack forName: _name];

	if (_commands == nil)
		return;

	NSUInteger currentIndex = [_commands indexOfObject: [self currentCommand]];
	[_commands removeObjectsFromIndex: currentIndex + 1];
}

- (void)addNewUndoCommand: (COCommand *)newCommand
{
	[_store pushAction: [newCommand plist] stack: kCOUndoStack forName: _name];

	COCommand *currentCommand = [self currentCommand];
	NSParameterAssert([newCommand isEqual: currentCommand]);
	BOOL currentCommandUnchanged = [currentCommand isEqual: [_commands lastObject]];
	
	if (currentCommandUnchanged || _commands == nil)
		return;

	[_commands addObject: newCommand];
}

- (COCommand *)currentCommand
{
	return [self peekEditFromStack: kCOUndoStack forName: _name];
}

- (void)setCurrentCommand: (COCommand *)aCommand
{
	INVALIDARG_EXCEPTION_TEST(aCommand, [[self nodes] containsObject: aCommand]);

	NSUInteger oldIndex = [[self nodes] indexOfObject: [self currentNode]];
	NSUInteger newIndex = [[self nodes] indexOfObject: aCommand];
	BOOL isUndo = (newIndex < oldIndex);
	BOOL isRedo = (newIndex > oldIndex);

	if (isUndo)
	{
		// TODO: Write an optimized version. For store operation commands
		// (e.g. create branch etc.), just apply the inverse. For commit-based
		// commands, track the set revision per persistent root in the loop,
		// and just revert persistent roots to the collected revisions at exit time.
		// The collected revisions follows or matches the current command.
		while ([[self currentNode] isEqual: aCommand] == NO)
		{
			[self popAndApplyFromStack: kCOUndoStack pushToStack: kCORedoStack name: _name toContext: [self editingContext]];
		}
	}
	else if (isRedo)
	{
		// TODO: Write an optimized version (see above).
		while ([[self currentNode] isEqual: aCommand] == NO)
		{
			[self popAndApplyFromStack: kCORedoStack pushToStack: kCOUndoStack name: _name toContext: [self editingContext]];
		}
	}
	[self didUpdate];
}

- (void)reloadCommands
{
	_commands = [[NSMutableArray alloc] initWithCapacity: 5000];

	[_commands addObject: [COEndOfUndoTrackPlaceholderNode sharedInstance]];
	
	for (NSDictionary *plist in [_store stackContents: kCOUndoStack forName: _name])
	{
		[_commands addObject: [COCommand commandWithPlist: plist]];
	}

	for (NSDictionary *plist in [[_store stackContents: kCORedoStack forName: _name] reverseObjectEnumerator])
	{
		[_commands addObject: [COCommand commandWithPlist: plist]];
	}
}

- (NSArray *)nodes
{
	if (_commands == nil)
	{
		[self reloadCommands];
	}
	return [_commands copy];
}

- (id)nextNodeOnTrackFrom: (id <COTrackNode>)aNode backwards: (BOOL)back
{
	NSInteger nodeIndex = [[self nodes] indexOfObject: aNode];
	
	if (nodeIndex == NSNotFound)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Node %@ must belong to the track %@ to retrieve the previous or next node", aNode, self];
	}
	if (back)
	{
		nodeIndex--;
	}
	else
	{
		nodeIndex++;
	}
	
	BOOL hasNoPreviousOrNextNode = (nodeIndex < 0 || nodeIndex >= [[self nodes] count]);
	
	if (hasNoPreviousOrNextNode)
	{
		return nil;
	}
	return [[self nodes] objectAtIndex: nodeIndex];
}

- (id <COTrackNode>)currentNode
{
	id <COTrackNode> command = [self currentCommand];
	if (command == nil)
	{
		command = [COEndOfUndoTrackPlaceholderNode sharedInstance];
	}
	return command;
}

- (void)setCurrentNode: (id <COTrackNode>)node
{
	INVALIDARG_EXCEPTION_TEST(node, [node isKindOfClass: [COCommand class]]
							|| [node isKindOfClass: [COEndOfUndoTrackPlaceholderNode class]]);
	[self setCurrentCommand: (COCommand *)node];
}

- (void)undoNode: (id <COTrackNode>)aNode
{
	// TODO: Implement Selective Undo
}

- (BOOL)isOrdered
{
	return YES;
}

- (id)content
{
	return [self nodes];
}

- (NSArray *)contentArray
{
	return [NSArray arrayWithArray: [self nodes]];
}

@end


@implementation COPatternUndoTrack

- (void) recordCommand: (COCommand *)aCommand
{
    [NSException raise: NSGenericException
	            format: @"You can't push actions to a %@", [self className]];
}

@end

