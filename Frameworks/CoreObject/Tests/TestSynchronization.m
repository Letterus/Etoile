#import <UnitKit/UnitKit.h>
#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import "TestCommon.h"

#define SERVER_STORE_URL [NSURL fileURLWithPath: [@"~/TestStore2.sqlite" stringByExpandingTildeInPath]]

@interface TestSynchronization : EditingContextTestCase <UKTest>
{
    COSQLiteStore *serverStore;
}
@end

@implementation TestSynchronization

static ETUUID *persistentRootUUID;
static ETUUID *rootItemUUID;
static ETUUID *branchAUUID;
static ETUUID *branchBUUID;

+ (void) initialize
{
    if (self == [TestSynchronization class])
    {
        rootItemUUID = [[ETUUID alloc] init];
        persistentRootUUID = [[ETUUID alloc] init];
        branchAUUID = [[ETUUID alloc] init];
        branchBUUID = [[ETUUID alloc] init];        
    }
}

- (COItemGraph *) itemGraphWithLabel: (NSString *)aLabel
{
    COMutableItem *child = [[[COMutableItem alloc] initWithUUID: rootItemUUID] autorelease];
    [child setValue: aLabel
       forAttribute: @"label"
               type: kCOTypeString];
    return [COItemGraph itemGraphWithItemsRootFirst: @[child]];
}

- (id)init
{
	SUPERINIT;
    [[NSFileManager defaultManager] removeItemAtPath: [SERVER_STORE_URL path] error: NULL];
    serverStore = [[COSQLiteStore alloc] initWithURL: SERVER_STORE_URL];
	return self;
}

- (void)dealloc
{
    DESTROY(serverStore);
    [[NSFileManager defaultManager] removeItemAtPath: [SERVER_STORE_URL path] error: NULL];
	[super dealloc];
}

- (void)testReplicateToClientWithoutPersistentRoot
{
    COPersistentRootInfo *serverInfo = [serverStore createPersistentRootWithInitialItemGraph: [self itemGraphWithLabel: @"1"]
                                                                                        UUID: persistentRootUUID
                                                                                  branchUUID: branchAUUID
                                                                            revisionMetadata: nil
                                                                                       error: NULL];
    UKNotNil(serverInfo);
    UKTrue([serverStore createBranchWithUUID: branchBUUID
                             initialRevision: [serverInfo currentRevisionID]
                           forPersistentRoot: persistentRootUUID
                                       error: NULL]);
    UKObjectsEqual(branchAUUID, [serverInfo currentBranchUUID]);

    /* 
       * = current branch
     
       Server: persistent root { branch A *, branch B }
    
       Client: nothing
     */
    
    // Client doesn't have the persistent root. It asks to pull from the server.
    
    COSynchronizationClient *client = [[[COSynchronizationClient alloc] init] autorelease];
    COSynchronizationServer *server = [[[COSynchronizationServer alloc] init] autorelease];
    
    id request = [client updateRequestForPersistentRoot: persistentRootUUID
                                               serverID: @"server"
                                                  store: store];
    id response = [server handleUpdateRequest: request store: serverStore];
    [client handleUpdateResponse: response store: store];
    
    // Persistent root has been replicated to the client

    /*
       * = current branch
     
       Server: persistent root { branch A *, branch B }
     
       Client: persistent root { branch A *, branch C (mirror of server's branch A), branch D (mirror of server's branch B) }
     */
    
    COPersistentRootInfo *clientInfo = [store persistentRootInfoForUUID: persistentRootUUID];
    UKNotNil(clientInfo);
    
    UKIntsEqual(3, [[clientInfo branches] count]);
    
    COBranchInfo *currentBranch = [clientInfo currentBranchInfo];
    COBranchInfo *replicatedBranchA = [[clientInfo branchInfosWithMetadataValue: [branchAUUID stringValue]
                                                                         forKey: @"replcatedBranch"] firstObject];
    

    COBranchInfo *replicatedBranchB = [[clientInfo branchInfosWithMetadataValue: [branchBUUID stringValue]
                                                                         forKey: @"replcatedBranch"] firstObject];

    // Check out the 3 branches
    UKObjectsEqual(branchAUUID, [currentBranch UUID]);
    
    UKNotNil(replicatedBranchB);
    UKObjectsNotEqual(branchBUUID, [replicatedBranchB UUID]);

    UKNotNil(replicatedBranchA);
    UKObjectsNotEqual(branchAUUID, [replicatedBranchA UUID]);
    
    // Check out the revisions of the branches
    
    UKObjectsEqual([[serverInfo currentRevisionID] revisionUUID], [[currentBranch currentRevisionID] revisionUUID]);
    UKObjectsEqual([[serverInfo currentRevisionID] revisionUUID], [[replicatedBranchA currentRevisionID] revisionUUID]);
    UKObjectsEqual([[serverInfo currentRevisionID] revisionUUID], [[replicatedBranchB currentRevisionID] revisionUUID]);
    
    UKObjectsEqual([self itemGraphWithLabel: @"1"], [store itemGraphForRevisionID: [currentBranch currentRevisionID]]);
    UKObjectsEqual([self itemGraphWithLabel: @"1"], [store itemGraphForRevisionID: [replicatedBranchA currentRevisionID]]);
    UKObjectsEqual([self itemGraphWithLabel: @"1"], [store itemGraphForRevisionID: [replicatedBranchB currentRevisionID]]);
    
    UKNil([[currentBranch metadata] objectForKey: @"source"]);
    UKObjectsEqual(@"server", [[replicatedBranchA metadata] objectForKey: @"source"]);
    UKObjectsEqual(@"server", [[replicatedBranchB metadata] objectForKey: @"source"]);
}

- (void)testPullUpdates
{
    COSynchronizationClient *client = [[[COSynchronizationClient alloc] init] autorelease];
    COSynchronizationServer *server = [[[COSynchronizationServer alloc] init] autorelease];
    
    COPersistentRootInfo *serverInfo = [serverStore createPersistentRootWithInitialItemGraph: [self itemGraphWithLabel: @"1"]
                                                                                        UUID: persistentRootUUID
                                                                                  branchUUID: branchAUUID
                                                                            revisionMetadata: nil
                                                                                       error: NULL];

    // Pull from server to client
        
    id request = [client updateRequestForPersistentRoot: persistentRootUUID
                                               serverID: @"server"
                                                  store: store];
    id response = [server handleUpdateRequest: request store: serverStore];
    [client handleUpdateResponse: response store: store];
    
    COPersistentRootInfo *clientInfo = [store persistentRootInfoForUUID: persistentRootUUID];
    UKNotNil(clientInfo);
    
    // Server writes a second commit.
    
    CORevisionID *serverCommit2 = [serverStore writeRevisionWithItemGraph: [self itemGraphWithLabel: @"2"]
                                                                 metadata: nil
                                                         parentRevisionID: [serverInfo currentRevisionID]
                                                    mergeParentRevisionID: nil
                                                            modifiedItems: nil
                                                                    error: NULL];
    int64_t changeCount = serverInfo.changeCount;
    UKTrue([serverStore setCurrentRevision: serverCommit2
                              tailRevision: nil
                                 forBranch: branchAUUID
                          ofPersistentRoot: persistentRootUUID
                        currentChangeCount: &changeCount
                                     error: NULL]);
    
    // Pull from server to client
    
    id request2 = [client updateRequestForPersistentRoot: persistentRootUUID
                                               serverID: @"server"
                                                  store: store];
    id response2 = [server handleUpdateRequest: request2 store: serverStore];
    [client handleUpdateResponse: response2 store: store];
    
    // Persistent root has been replicated to the client
    
    clientInfo = [store persistentRootInfoForUUID: persistentRootUUID];
    UKNotNil(clientInfo);
    
    UKIntsEqual(2, [[clientInfo branches] count]);

    COBranchInfo *currentBranch = [clientInfo currentBranchInfo];
    
    COBranchInfo *replicatedBranchA = [[clientInfo branchInfosWithMetadataValue: [branchAUUID stringValue]
                                                                         forKey: @"replcatedBranch"] firstObject];
    
    UKTrue([[[replicatedBranchA metadata] objectForKey: @"source"] isEqual: @"server"]);
    
    // The replicated branch should have been update, but the other branch should not have
    
    UKObjectsEqual([self itemGraphWithLabel: @"1"], [store itemGraphForRevisionID: [currentBranch currentRevisionID]]);
    UKObjectsEqual([self itemGraphWithLabel: @"2"], [store itemGraphForRevisionID: [replicatedBranchA currentRevisionID]]);
}

- (void)testPullCheapCopy
{
    COSynchronizationClient *client = [[[COSynchronizationClient alloc] init] autorelease];
    COSynchronizationServer *server = [[[COSynchronizationServer alloc] init] autorelease];

    COPersistentRootInfo *serverInfo = [serverStore createPersistentRootWithInitialItemGraph: [self itemGraphWithLabel: @"1"]
                                                                                        UUID: persistentRootUUID
                                                                                  branchUUID: branchAUUID
                                                                            revisionMetadata: nil
                                                                                       error: NULL];
    
    ETUUID *cheapCopyUUID = [ETUUID UUID];
    ETUUID *cheapCopyBranchUUID = [ETUUID UUID];
    COPersistentRootInfo *serverCheapCopyInfo = [serverStore createPersistentRootWithInitialRevision: [serverInfo currentRevisionID]
                                                                                                UUID: cheapCopyUUID
                                                                                          branchUUID: cheapCopyBranchUUID
                                                                                               error: NULL];    
    // Server writes a second commit.
    
    CORevisionID *serverCommit2 = [serverStore writeRevisionWithItemGraph: [self itemGraphWithLabel: @"2"]
                                                                 metadata: nil
                                                         parentRevisionID: [serverCheapCopyInfo currentRevisionID]
                                                    mergeParentRevisionID: nil
                                                            modifiedItems: nil
                                                                    error: NULL];

    int64_t changeCount = serverInfo.changeCount;
    UKTrue([serverStore setCurrentRevision: serverCommit2
                              tailRevision: nil
                                 forBranch: cheapCopyBranchUUID
                          ofPersistentRoot: cheapCopyUUID
                        currentChangeCount: &changeCount
                                     error: NULL]);
    
    // Replicate the original persistent root on the client
    
    // Pull from server to client
    
    id request = [client updateRequestForPersistentRoot: persistentRootUUID
                                               serverID: @"server"
                                                  store: store];
    id response = [server handleUpdateRequest: request store: serverStore];
    [client handleUpdateResponse: response store: store];
    
    COPersistentRootInfo *clientInfo = [store persistentRootInfoForUUID: persistentRootUUID];
    UKNotNil(clientInfo);

    //NSLog(@"Server: %@", serverStore);
    //NSLog(@"Client: %@", store);
    
    // Pull "cheapCopyUUID" persistent root from server to client
        
    id request2 = [client updateRequestForPersistentRoot: cheapCopyUUID
                                               serverID: @"server"
                                                  store: store];
    id response2 = [server handleUpdateRequest: request2 store: serverStore];
    [client handleUpdateResponse: response2 store: store];
    
    // "cheapCopyUUID" persistent root has been replicated to the client.
    
    COPersistentRootInfo *clientCheapCopyInfo = [store persistentRootInfoForUUID: cheapCopyUUID];
    UKIntsEqual(2, [[clientCheapCopyInfo branches] count]);
    
    COBranchInfo *currentBranch = [clientCheapCopyInfo currentBranchInfo];
    COBranchInfo *replicatedCheapCopyBranch = [[clientCheapCopyInfo branchInfosWithMetadataValue: [cheapCopyBranchUUID stringValue]
                                                                                          forKey: @"replcatedBranch"] firstObject];

    UKObjectsEqual(cheapCopyBranchUUID, [currentBranch UUID]);
    UKObjectsNotEqual(cheapCopyBranchUUID, [replicatedCheapCopyBranch UUID]);
    
    UKObjectsEqual([self itemGraphWithLabel: @"2"],
                   [store itemGraphForRevisionID: [currentBranch currentRevisionID]]);
    UKObjectsEqual([self itemGraphWithLabel: @"2"],
                   [store itemGraphForRevisionID: [replicatedCheapCopyBranch currentRevisionID]]);
    
    // Ideally it shares the same backing store as the original persistent root. But that's not going to be easy to do.
}

@end

