#import "EWBranchesWindowController.h"
#import <CoreObject/CoreObject.h>
#import <EtoileFoundation/Macros.h>

#import "EWDocument.h"

@implementation EWBranchesWindowController

- (id)init
{
	self = [super initWithWindowNibName: @"Branches"];
    if (self) {
        
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

+ (EWBranchesWindowController *) sharedController
{
    static EWBranchesWindowController *shared;
    if (shared == nil) {
        shared = [[self alloc] init];
    }
    return shared;
}

- (void) awakeFromNib
{
    [table setDoubleAction: @selector(doubleClick:)];
    [table setTarget: self];
}

- (void) setInspectedDocument: (NSDocument *)aDoc
{
    NSLog(@"Inspect %@", aDoc);
    
    [self setPersistentRoot: [(EWDocument *)aDoc currentPersistentRoot]];
}

- (void) show
{
    [self showWindow: self];
    [self setInspectedDocument: [[NSDocumentController sharedDocumentController]
                                 currentDocument]];
}

- (NSArray *) orderedBranches
{
    NSArray *unsorted = [[_persistentRoot branches] allObjects];
    NSArray *sorted = [unsorted sortedArrayUsingDescriptors:
     A([NSSortDescriptor sortDescriptorWithKey: @"label" ascending: NO],
       [NSSortDescriptor sortDescriptorWithKey: @"UUID.stringValue" ascending: NO])];
    
    return sorted;
}

- (void) storePersistentRootMetadataDidChange: (NSNotification *)notif
{
    NSLog(@"branches window: view did change: %@", notif);
    
    [table reloadData];
}

- (void) setPersistentRoot: (COPersistentRoot *)proot
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: COPersistentRootDidChangeNotification
                                                  object: _persistentRoot];
        
    _persistentRoot =  proot;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(storePersistentRootMetadataDidChange:)
                                                 name: COPersistentRootDidChangeNotification
                                               object: nil];    
    
    [table reloadData];
}

- (COBranch *)selectedBranch
{
    COBranch *branch = [[self orderedBranches] objectAtIndex: [table selectedRow]];
    return branch;
}

- (void)doubleClick: (id)sender
{
	if (sender == table)
	{
		COBranch *branch = [self selectedBranch];
		
        [(EWDocument *)[[NSDocumentController sharedDocumentController]
          currentDocument] switchToBranch: [branch UUID]];
	}
}

- (void)deleteForward:(id)sender
{
	COBranch *branch = [self selectedBranch];
    [(EWDocument *)[[NSDocumentController sharedDocumentController]
                    currentDocument] deleteBranch: [branch UUID]];
}

- (void)delete:(id)sender
{
	[self deleteForward: sender];
}

- (void)deleteBackward:(id)sender
{
	[self deleteForward: sender];
}

/**
 * THis seems to be needed to get -delete/-deleteForward:/-deleteBackward: called
 */
- (void)keyDown:(NSEvent *)theEvent
{
	[self interpretKeyEvents: [NSArray arrayWithObject:theEvent]];
}

/* NSTableViewDataSource */

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[_persistentRoot branches] count];;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	COBranch *branch = [[self orderedBranches] objectAtIndex: row];
    if ([[tableColumn identifier] isEqual: @"name"])
    {
        return [branch label];
    }
    else if ([[tableColumn identifier] isEqual: @"important"])
    {
        return [[branch metadata] objectForKey: @"important"];
    }
    else if ([[tableColumn identifier] isEqual: @"checked"])
    {
        BOOL checked = [branch isCurrentBranch];
        return [NSNumber numberWithBool: checked];
    }
    return nil;
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    COBranch *branch = [[self orderedBranches] objectAtIndex: row];
    if ([[tableColumn identifier] isEqual: @"name"])
    {
        [branch setLabel: object];
        [(EWDocument *)[[NSDocumentController sharedDocumentController]
                        currentDocument] commit];
    }
    else if ([[tableColumn identifier] isEqual: @"important"])
    {
        ETAssert([object isKindOfClass: [NSNumber class]]);
        NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary: [branch metadata]];
        metadata[@"important"] = object;
        [branch setMetadata: metadata];
        [(EWDocument *)[[NSDocumentController sharedDocumentController] currentDocument] commit];
    }
    else if ([[tableColumn identifier] isEqual: @"checked"])
    {
        if ([object boolValue])
        {
            [(EWDocument *)[[NSDocumentController sharedDocumentController]
                            currentDocument] switchToBranch: [branch UUID]];
        }
    }
}
@end
