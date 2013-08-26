#import "TestCommon.h"
#import "COItem.h"
#import "COSQLiteStore+Attachments.h"

#define READONLY_SEARCHABLE_DIRECTORY_ATTRIBUTES D([NSNumber numberWithShort: 0555], NSFilePosixPermissions)
#define REABLE_WRITABLE_SEARCHABLE_DIRECTORY_ATTRIBUTES D([NSNumber numberWithShort: 0777], NSFilePosixPermissions)

@interface TestSQLiteStoreErrorHandling : NSObject <UKTest>
{
}
@end

@implementation TestSQLiteStoreErrorHandling

static ETUUID *rootUUID;
+ (void) initialize
{
    if (self == [TestSQLiteStoreErrorHandling class])
    {
        rootUUID = [[ETUUID alloc] init];
    }
}

- (COItemGraph *) makeInitialItemGraph
{
    return [COItemGraph treeWithItemsRootFirst: A([[[COMutableItem alloc] initWithUUID: rootUUID] autorelease])];
}

- (NSString *) tempPathWithName: (NSString *)aName
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:
                [NSString stringWithFormat: @"%@-%@", aName, [ETUUID UUID]]];
}

- (void) testCreateStoreInReadonlyDirectory
{
    NSString *dir = [self tempPathWithName: @"coreobject-readonly"];
    
    @autoreleasepool {
        assert([[NSFileManager defaultManager] createDirectoryAtPath: dir
                                         withIntermediateDirectories: NO
                                                          attributes: READONLY_SEARCHABLE_DIRECTORY_ATTRIBUTES
                                                               error: NULL]);
        
        UKNil([[[COSQLiteStore alloc] initWithURL: [NSURL fileURLWithPath: dir
                                                              isDirectory: YES]] autorelease]);
        
        UKNil([[[COSQLiteStore alloc] initWithURL: [NSURL fileURLWithPath: [dir stringByAppendingPathComponent: @"test.coreobject"]
                                                              isDirectory: YES]] autorelease]);
    }

    assert([[NSFileManager defaultManager] removeItemAtPath: dir error: NULL]);
}

- (void) testStoreDirectoryBecomingReadonly
{
    NSString *dir = [self tempPathWithName: @"coreobject-become-readonly"];
    
    @autoreleasepool {
        assert([[NSFileManager defaultManager] createDirectoryAtPath: dir
                                         withIntermediateDirectories: NO
                                                          attributes: nil
                                                               error: NULL]);
        
        COSQLiteStore *store = [[[COSQLiteStore alloc] initWithURL: [NSURL fileURLWithPath: dir
                                                                               isDirectory: YES]] autorelease];
        UKNotNil(store);
        
        assert([[NSFileManager defaultManager] setAttributes: READONLY_SEARCHABLE_DIRECTORY_ATTRIBUTES
                                                ofItemAtPath: dir
                                                       error: NULL]);
        
        // At this point the SQLite database file in dir can be freely modified, but creating files in dir will
        // fail since it's readonly, so creating new persistent roots should fail.
        
        NSError *error = nil;
        BOOL ok = [store createPersistentRootWithInitialItemGraph: [self makeInitialItemGraph]
                                                             UUID: [ETUUID UUID]
                                                       branchUUID: [ETUUID UUID]
                                                 revisionMetadata: nil
                                                            error: &error];
        UKFalse(ok);
    }
    
    assert([[NSFileManager defaultManager] setAttributes: REABLE_WRITABLE_SEARCHABLE_DIRECTORY_ATTRIBUTES
                                            ofItemAtPath: dir
                                                   error: NULL]);
    assert([[NSFileManager defaultManager] removeItemAtPath: dir error: NULL]);
}

@end
