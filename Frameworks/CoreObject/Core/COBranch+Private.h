/*
	Copyright (C) 2013 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>, 
	         Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2013
	License:  Modified BSD  (see COPYING)
 */

#import <CoreObject/COBranch.h>

@interface COBranch ()

/** @taskunit Private */

- (id)        initWithUUID: (ETUUID *)aUUID
        objectGraphContext: (COObjectGraphContext *)anObjectGraphContext
            persistentRoot: (COPersistentRoot *)aPersistentRoot
          parentBranchUUID: (ETUUID *)aParentBranchUUID
parentRevisionForNewBranch: (CORevisionID *)parentRevisionForNewBranch;

- (void)updateWithBranchInfo: (COBranchInfo *)branchInfo;
- (COBranchInfo *)branchInfo;

- (void)didMakeInitialCommitWithRevisionID: (CORevisionID *)aRevisionID;
- (void) saveCommitWithMetadata: (NSDictionary *)metadata;
- (void)saveDeletion;
- (BOOL) isBranchUncommitted;

- (void)updateRevisions;

@property (readwrite, nonatomic) CORevision *headRevision;

@end