#import "COEditingContext.h"
#import "COLibrary.h"
#import "COPersistentRoot.h"
#import "COError.h"
#import "COObject.h"
#import "COGroup.h"
#import "COSQLiteStore.h"
#import "CORevision.h"
#import "COBranch.h"
#import "COPath.h"
#import "COObjectGraphContext.h"
#import "COCrossPersistentRootReferenceCache.h"

@implementation COEditingContext

@synthesize persistentRootsPendingDeletion = _persistentRootsPendingDeletion;
@synthesize persistentRootsPendingUndeletion = _persistentRootsPendingUndeletion;

+ (COEditingContext *)contextWithURL: (NSURL *)aURL
{
	// TODO: Look up the store class based on the URL scheme and path extension
	COEditingContext *ctx = [[self alloc] initWithStore:
		[[[NSClassFromString(@"COSQLiteStore") alloc] initWithURL: aURL] autorelease]];
	return [ctx autorelease];
}

static COEditingContext *currentCtxt = nil;

+ (COEditingContext *)currentContext
{
	return currentCtxt;
}

+ (void)setCurrentContext: (COEditingContext *)aCtxt
{
	ASSIGN(currentCtxt, aCtxt);
}

- (void)registerAdditionalEntityDescriptions
{
	NSSet *entityDescriptions = [COLibrary additionalEntityDescriptions];

	for (ETEntityDescription *entity in entityDescriptions)
	{
		if ([[self modelRepository] descriptionForName: [entity fullName]] != nil)
			continue;
			
		[[self modelRepository] addUnresolvedDescription: entity];
	}
	[[self modelRepository] resolveNamedObjectReferences];
}

- (id)initWithStore: (COSQLiteStore *)store
{
	SUPERINIT;

	ASSIGN(_store, store);
	_modelRepository = [[ETModelDescriptionRepository mainRepository] retain];
	_loadedPersistentRoots = [NSMutableDictionary new];
	_persistentRootsPendingDeletion = [NSMutableSet new];
    _persistentRootsPendingUndeletion = [NSMutableSet new];
    _crossRefCache = [[COCrossPersistentRootReferenceCache alloc] init];
    
	[self registerAdditionalEntityDescriptions];


    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(storePersistentRootDidChange:)
                                                 name: COStorePersistentRootDidChangeNotification
                                               object: _store];

	[[NSDistributedNotificationCenter defaultCenter] addObserver: self
	                                                    selector: @selector(distributedStorePersistentRootDidChange:)
	                                                        name: COStorePersistentRootDidChangeNotification
	                                                      object: nil];

	return self;
}

- (id)init
{
	return [self initWithStore: nil];
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
    [[NSNotificationCenter defaultCenter] removeObserver: self];

	DESTROY(_store);
	DESTROY(_modelRepository);
	DESTROY(_loadedPersistentRoots);
	DESTROY(_persistentRootsPendingDeletion);
    DESTROY(_persistentRootsPendingUndeletion);
    DESTROY(_crossRefCache);
	DESTROY(_error);
	[super dealloc];
}

- (NSString *)description
{
	NSMutableDictionary *changeSummary = [NSMutableDictionary dictionary];

	for (COPersistentRoot *persistentRoot in [_loadedPersistentRoots objectEnumerator])
	{
		if ([persistentRoot hasChanges] == NO)
			continue;
		
		[changeSummary setObject: [persistentRoot description]
		                  forKey: [persistentRoot persistentRootUUID]];
	}

	/* For Mac OS X, see http://www.cocoabuilder.com/archive/cocoa/197297-who-broke-nslog-on-leopard.html */
	NSString *desc = [changeSummary description];
	desc = [desc stringByReplacingOccurrencesOfString: @"\\n" withString: @"\n"];
	desc = [desc stringByReplacingOccurrencesOfString: @"\\\"" withString: @""];
	return desc;
}

- (BOOL)isEditingContext
{
	return YES;
}

- (COEditingContext *)editingContext
{
	return self;
}
- (COCrossPersistentRootReferenceCache *) crossReferenceCache
{
    return _crossRefCache;
}

- (NSSet *)persistentRoots
{
    // TODO: Revisit once we introduce persistent root faulting. Assumes all persistent roots are loaded.
    
    NSMutableSet *result = [NSMutableSet setWithArray: [_loadedPersistentRoots allValues]];

    for (ETUUID *uuid in [_store deletedPersistentRootUUIDs])
    {
        [result removeObject: [self persistentRootForUUID: uuid]];
    }

    [result minusSet: _persistentRootsPendingDeletion];
    [result unionSet: _persistentRootsPendingUndeletion];
    
    return result;
}

- (NSSet *)deletedPersistentRoots
{
    NSMutableSet *result = [NSMutableSet set];
    
    for (ETUUID *uuid in [_store deletedPersistentRootUUIDs])
    {
        [result addObject: [self persistentRootForUUID: uuid]];
    }
    
    return result;
}

- (COGroup *)libraryGroup
{
    return nil; // FIXME: Rewrite
#if 0
	NSString *UUIDString = [[_store metadata] objectForKey: @"kCOLibraryGroupUUID"];

	if (UUIDString == nil)
	{
		COGroup *newGroup = [[self insertNewPersistentRootWithEntityName: @"Anonymous.COGroup"] rootObject];
		NSMutableDictionary *metadata = AUTORELEASE([[_store metadata] mutableCopy]);

		[newGroup setName: _(@"Libraries")];
		[metadata setObject: [[newGroup UUID] stringValue] 
		             forKey: @"kCOLibraryGroupUUID"];
		[_store setMetadata: metadata];
		
		[newGroup addObjects: A([self tagLibrary], [self bookmarkLibrary],
			[self noteLibrary], [self photoLibrary], [self musicLibrary])];
	
		return newGroup;
	}

	return (id)[self objectWithUUID: [ETUUID UUIDWithString: UUIDString]];
#endif
}

- (COSQLiteStore *)store
{
	return _store;
}

- (ETModelDescriptionRepository *)modelRepository
{
	return _modelRepository; 
}

- (COPersistentRoot *)persistentRootForUUID: (ETUUID *)persistentRootUUID
{
	COPersistentRoot *persistentRoot = [_loadedPersistentRoots objectForKey: persistentRootUUID];
	
	if (persistentRoot != nil)
		return persistentRoot;

    COPersistentRootInfo *info = [_store persistentRootInfoForUUID: persistentRootUUID];
        
	BOOL persistentRootFound = (info != nil);

	if (persistentRootFound == NO)
		return nil;

	persistentRoot = [self makePersistentRootWithInfo: info objectGraphContext: nil];

	return persistentRoot;
}

// NOTE: Persistent root insertion or deletion are saved to the store at commit time.

- (COPersistentRoot *)makePersistentRootWithInfo: (COPersistentRootInfo *)info
                              objectGraphContext: (COObjectGraphContext *)anObjectGrapContext
{
    if (info != nil)
    {
        NSParameterAssert(nil == [_loadedPersistentRoots objectForKey: [info UUID]]);
    }
    
    COPersistentRoot *persistentRoot = [[COPersistentRoot alloc] initWithInfo: info
                                                          cheapCopyRevisionID: nil
	                                                       objectGraphContext: anObjectGrapContext
                                                                parentContext: self];
	[_loadedPersistentRoots setObject: persistentRoot
							   forKey: [persistentRoot persistentRootUUID]];
	[persistentRoot release];
	return persistentRoot;
}

- (COPersistentRoot *)insertNewPersistentRootWithEntityName: (NSString *)anEntityName
{
	ETEntityDescription *desc = [[self modelRepository] descriptionForName: anEntityName];
	Class cls = [[self modelRepository] classForEntityDescription: desc];
	COObject *rootObject = [[cls alloc] initWithUUID: [ETUUID UUID]
	                               entityDescription: desc
	                              objectGraphContext: [COObjectGraphContext objectGraphContext]];
	COPersistentRoot *persistentRoot = [self makePersistentRootWithInfo: nil
	                                                 objectGraphContext: [rootObject objectGraphContext]];

	[[rootObject objectGraphContext] setRootObject: rootObject];

	return persistentRoot;
}

- (COPersistentRoot *)insertNewPersistentRootWithRevisionID: (CORevisionID *)aRevid
{
    COPersistentRoot *persistentRoot = [[COPersistentRoot alloc] initWithInfo: nil
                                                          cheapCopyRevisionID: aRevid
	                                                       objectGraphContext: nil 
                                                                parentContext: self];
	[_loadedPersistentRoots setObject: persistentRoot
							   forKey: [persistentRoot persistentRootUUID]];
	[persistentRoot release];

    return persistentRoot;
}

- (NSSet *)persistentRootsPendingInsertion
{
	NSMutableSet *insertedPersistentRoots = [NSMutableSet set];

	for (COPersistentRoot *persistentRoot in [_loadedPersistentRoots objectEnumerator])
	{
		if ([persistentRoot revision] == nil)
		{
			[insertedPersistentRoots addObject: persistentRoot];
		}
	}
	return insertedPersistentRoots;
}

- (COPersistentRoot *)insertNewPersistentRootWithRootObject: (COObject *)aRootObject
{
	COObjectGraphContext *objectGraphContext = [aRootObject objectGraphContext];

	INVALIDARG_EXCEPTION_TEST(objectGraphContext, [objectGraphContext persistentRoot] == nil);
	INVALIDARG_EXCEPTION_TEST(objectGraphContext,
		[objectGraphContext rootObject] == nil || [objectGraphContext rootObject] == aRootObject);

	COPersistentRoot *persistentRoot = [self makePersistentRootWithInfo: nil
	                                                 objectGraphContext: objectGraphContext];

	[objectGraphContext setRootObject: aRootObject];

	return persistentRoot;
}

- (void)deletePersistentRoot: (COPersistentRoot *)aPersistentRoot
{
    if (![aPersistentRoot isPersistentRootCommitted])
    {
        [self unloadPersistentRoot: aPersistentRoot];
    }
    else if ([_persistentRootsPendingUndeletion containsObject: aPersistentRoot])
    {
        [_persistentRootsPendingUndeletion removeObject: aPersistentRoot];
    }
    else
    {
        // NOTE: Deleted persistent roots are removed from the cache on commit.
        [_persistentRootsPendingDeletion addObject: aPersistentRoot];
        
    }
    
    [aPersistentRoot updateCrossPersistentRootReferences];
}

- (void)undeletePersistentRoot: (COPersistentRoot *)aPersistentRoot
{
    if ([_persistentRootsPendingDeletion containsObject: aPersistentRoot])
    {
        [_persistentRootsPendingDeletion removeObject: aPersistentRoot];
    }
    else
    {
        [_persistentRootsPendingUndeletion addObject: aPersistentRoot];
    }
    
    [aPersistentRoot updateCrossPersistentRootReferences];
}

- (COObject *)objectWithUUID: (ETUUID *)uuid
{
	for (COPersistentRoot *persistentRoot in [_loadedPersistentRoots objectEnumerator])
	{
		COObject *rootObject = [persistentRoot objectWithUUID: uuid];
		
		if (rootObject != nil)
			return rootObject;
	}
	
	// FIXME: Slow path
	for (ETUUID *uuid in [_store persistentRootUUIDs])
	{
		COPersistentRoot *persistentRoot = [self persistentRootForUUID: uuid];
		
		if ([[persistentRoot rootObjectUUID] isEqual: uuid])
			return [persistentRoot rootObject];
	}
	return nil;
}

- (NSSet *)loadedObjects
{
	return [self setByCollectingObjectsFromPersistentRootsUsingSelector: @selector(loadedObjects)];
}

- (NSSet *)loadedRootObjects
{
	return [self setByCollectingObjectsFromPersistentRootsUsingSelector: @selector(loadedRootObjects)];
}

// NOTE: We could rewrite it using -foldWithBlock: or -leftFold (could be faster)
- (NSSet *)setByCollectingObjectsFromPersistentRootsUsingSelector: (SEL)aSelector
{
	NSMutableSet *collectedObjects = [NSMutableSet set];

	for (COPersistentRoot *context in [_loadedPersistentRoots objectEnumerator])
	{
		[collectedObjects unionSet: [context performSelector: aSelector]];
	}
	return collectedObjects;
}

- (NSSet *)insertedObjects
{
	return [self setByCollectingObjectsFromPersistentRootsUsingSelector: @selector(insertedObjects)];
}

- (NSSet *)updatedObjects
{
	return [self setByCollectingObjectsFromPersistentRootsUsingSelector: @selector(updatedObjects)];
}

- (BOOL)isUpdatedObject: (COObject *)anObject
{
	return [[self setByCollectingObjectsFromPersistentRootsUsingSelector: @selector(updatedObjects)] containsObject: anObject];
}

- (NSSet *)deletedObjects
{
	return [self setByCollectingObjectsFromPersistentRootsUsingSelector: @selector(deletedObjects)];
}

- (NSSet *)changedObjects
{
	return [self setByCollectingObjectsFromPersistentRootsUsingSelector: @selector(changedObjects)];
}

- (BOOL)hasChanges
{
    if ([_persistentRootsPendingDeletion count] > 0)
        return YES;
    
    if ([_persistentRootsPendingUndeletion count] > 0)
        return YES;
    
	for (COPersistentRoot *context in [_loadedPersistentRoots objectEnumerator])
	{
        if (![context isPersistentRootCommitted])
            return YES;
        
		if ([context hasChanges])
			return YES;
	}
	return NO;
}

- (void)discardAllChanges
{
	/* Represents persistent roots inserted since the last commit */
	NSSet *insertedPersistentRoots = [self persistentRootsPendingInsertion];

	/* Discard changes in persistent roots and collect discarded persistent roots */
	for (ETUUID *uuid in _loadedPersistentRoots)
	{
		COPersistentRoot *persistentRoot = [_loadedPersistentRoots objectForKey: uuid];
		BOOL isInserted = ([persistentRoot revision] == nil);

		if (isInserted)
			continue;

		[persistentRoot discardAllChanges];
	}

	/* Remove from the cache all the objects that belong to discarded persistent roots */
    // FIXME: Implement
	//[(COPersistentRoot *)[insertedPersistentRoots mappedCollection] unload];

	/* Release the discarded persistent roots */
	[_loadedPersistentRoots removeObjectsForKeys:
		(id)[[[insertedPersistentRoots allObjects] mappedCollection] persistentRootUUID]];

	assert([self hasChanges] == NO);
}

- (NSArray *)commit
{
	return [self commitWithType: nil shortDescription: nil];
}

- (NSArray *)commitWithType: (NSString *)type
           shortDescription: (NSString *)shortDescription
{
	NSString *commitType = type;
	
	if (type == nil)
	{
		commitType = @"Unknown";
	}
	if (shortDescription == nil)
	{
		shortDescription = @"";
	}
	return [self commitWithMetadata: D(shortDescription, @"shortDescription", commitType, @"type")];
}

- (void)didCommitRevision: (CORevision *)aRevision
{
}

- (void)didFailValidationWithError: (COError *)anError
{
	ASSIGN(_error, anError);
}

/* Both COPersistentRoot or COEditingContext objects are valid arguments. */
- (BOOL)validateChangedObjectsForContext: (id)aContext
{
#if 0
	NSSet *insertionErrors = (id)[[[aContext insertedObjects] mappedCollection] validateForInsert];
	NSSet *updateErrors = (id)[[[aContext updatedObjects] mappedCollection] validateForUpdate];
	NSSet *deletionErrors = (id)[[[aContext deletedObjects] mappedCollection] validateForDelete];
	NSMutableSet *validationErrors = [NSMutableSet setWithSet: insertionErrors];
	
	[validationErrors unionSet: updateErrors];
	[validationErrors unionSet: deletionErrors];

	// NOTE: We have a null value because -validateXXX returns nil on validation success
	[validationErrors removeObject: [NSNull null]];

	[aContext didFailValidationWithError: [COError errorWithErrors: validationErrors]];

	return ([aContext error] == nil);
#endif
    return YES;
}

- (NSArray *)commitWithMetadata: (NSDictionary *)metadata
	restrictedToPersistentRoots: (NSArray *)persistentRoots
{
	// TODO: We could organize validation errors by persistent root. Each
	// persistent root might result in a validation error that contains a
	// suberror per inner object, then each suberror could in turn contain
	// a suberror per validation result. For now, we just aggregate errors per
	// inner object.
	if ([self validateChangedObjectsForContext: self] == NO)
		return [NSArray array];

	NSMutableArray *revisions = [NSMutableArray array];

	/* Commit persistent root changes (deleted persistent roots included) */

    [_store beginTransactionWithError: NULL];
    
	// TODO: Add a batch commit UUID in the metadata
	for (COPersistentRoot *ctxt in persistentRoots)
	{
		[ctxt saveCommitWithMetadata: metadata];
		[self didCommitRevision: [revisions lastObject]];
	}
	
	/* Record persistent root deletions at the store level */
	
	for (COPersistentRoot *persistentRoot in persistentRoots)
	{
        ETUUID *uuid = [persistentRoot persistentRootUUID];
        
		if ([_persistentRootsPendingDeletion containsObject: persistentRoot])
        {
            ETAssert([_store deletePersistentRoot: uuid error: NULL]);
            [_persistentRootsPendingDeletion removeObject: persistentRoot];
            
            [self unloadPersistentRoot: persistentRoot];
        }
        else if ([_persistentRootsPendingUndeletion containsObject: persistentRoot])
        {
            ETAssert([_store undeletePersistentRoot: uuid error: NULL]);            
            [_persistentRootsPendingUndeletion removeObject: persistentRoot];
        }
    }

    ETAssert([_store commitTransactionWithError: NULL]);
    
	return revisions;
}

- (NSArray *)commitWithMetadata: (NSDictionary *)metadata
{
	return [self commitWithMetadata: metadata
		restrictedToPersistentRoots: [_loadedPersistentRoots allValues]];
}

- (NSError *)error
{
	return _error;
}

- (void) unloadPersistentRoot: (COPersistentRoot *)aPersistentRoot
{
    // FIXME: Implement. For now, since we don't support faulting persistent
    // roots, only release a persistent root if it's uncommitted.
    
    if (![aPersistentRoot isPersistentRootCommitted])
    {
        [_loadedPersistentRoots removeObjectForKey:
            [aPersistentRoot persistentRootUUID]];
    }
}

- (id)crossPersistentRootReferenceWithPath: (COPath *)aPath
{
    ETUUID *persistentRootUUID = [aPath persistentRoot];
    ETAssert(persistentRootUUID != nil);
    
    ETUUID *branchUUID = [aPath branch];
    
    /* Specifying an embedded object is unsupported and will be removed from COPath */
    ETAssert([aPath embeddedObject] == nil);
    
    COPersistentRoot *persistentRoot = [self persistentRootForUUID: persistentRootUUID];
    ETAssert(persistentRoot != nil);
    
    COBranch *branch;
    if (branchUUID != nil)
    {
        branch = [persistentRoot branchForUUID: branchUUID];
    }
    else
    {
        branch = [persistentRoot currentBranch];
    }
    
    if ([branch isDeleted])
    {
        return nil;
    }
    
    COObjectGraphContext *objectGraph = [branch objectGraph];
    return [objectGraph rootObject];
}

// Notification handling

/* Handles distributed notifications about new revisions to refresh the root
 object graphs present in memory, for which changes have been committed to the
 store by other processes. */
- (void)distributedStorePersistentRootDidChange: (NSNotification *)notif
{
    // TODO: Write a test to ensure other store notifications are not handled
    NSDictionary *userInfo = [notif userInfo];
    NSString *storeURL = [userInfo objectForKey: kCOStoreURL];
    NSString *storeUUID = [userInfo objectForKey: kCOStoreUUID];
    
    if ([[[_store UUID] stringValue] isEqual: storeUUID]
        && [[[_store URL] absoluteString] isEqual: storeURL])
    {
        [self storePersistentRootDidChange: notif];
    }
}

- (void)storePersistentRootDidChange: (NSNotification *)notif
{
    NSDictionary *userInfo = [notif userInfo];
    ETUUID *persistentRootUUID = [ETUUID UUIDWithString: [userInfo objectForKey: kCOPersistentRootUUID]];
    
    // NSLog(@"%@: Got change notif for persistent root: %@", self, persistentRootUUID);
    
    COPersistentRoot *loaded = [_loadedPersistentRoots objectForKey: persistentRootUUID];
    if (loaded != nil)
    {
        [loaded storePersistentRootDidChange: notif];
    }
}

@end
