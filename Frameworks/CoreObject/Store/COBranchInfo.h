#import <Foundation/Foundation.h>

@class ETUUID, CORevisionID;

@interface COBranchInfo : NSObject
{
@private
    ETUUID *uuid_;
    CORevisionID *initialRevisionId_;
    CORevisionID *headRevisionId_;
    CORevisionID *currentRevisionId_;
    NSDictionary *metadata_;
    BOOL deleted_;
    ETUUID *parentBranchUUID_;
}

@property (readwrite, nonatomic, strong) ETUUID *UUID;

/**
 * The newest revision on the branch.
 *
 * Normally the same as currentRevisionID,
 * unless currentRevisionID is reverted to an older revision.
 * Upon making a commit from that state, headRevisionID would be reset to
 * equal currentRevisionID.
 *
 * The only benefit for having this is so the user can undo reverting to an
 * old revision without using the real, application-level undo command.
 * i.e. they would open the history inspector, and explicitly
 * reset the current revision to the head. If we don't care about that feature,
 * we can drop this property and require users to undo bad "revert to old revision"
 * by pressing Cmd+Z.
 *
 * It's worth noting that if they revert to an old revision and commit a change,
 * the only way to undo that is with application-level undo anyway. So this
 * property really only does anything in a very tiny use case (reverted to old
 * revision, haven't yet made a change) which suggests it should probably be
 * removed.
 */
@property (readwrite, nonatomic, retain) CORevisionID *headRevisionID;
/**
 * The oldest revision on the branch. Indicates "where a feature branch was
 * forked from master"
 */
@property (readwrite, nonatomic, strong) CORevisionID *initialRevisionID;
/**
 * The current revision of this branch.
 */
@property (readwrite, nonatomic, strong) CORevisionID *currentRevisionID;
/**
 * Metadata, like the user-facing name of the branch.
 * Note that branches have metadata while persistent roots do not. Persistent
 * root metadata should be stored in the inner objects as versioned data.
 * (If there is a real use case for unversioned persistent root metadata,
 *  we can easily re-add it)
 */
@property (readwrite, nonatomic, strong) NSDictionary *metadata;
@property (readwrite, nonatomic, getter=isDeleted, setter=setDeleted:) BOOL deleted;

@property (readwrite, nonatomic, strong) ETUUID *parentBranchUUID;

/**
 * In git terminology, if the receiver is "master", returns "origin/master", or
 * nil if there is no corresponding "origin/master"
 */
- (ETUUID *) remoteMirror;

/**
 * In git terminology, if the receiver is "origin/master", returns the UUID
 * of the "master" branch in the remote store "origin". Otherwise, returns nil.
 */
- (ETUUID *) replcatedBranch;

@end