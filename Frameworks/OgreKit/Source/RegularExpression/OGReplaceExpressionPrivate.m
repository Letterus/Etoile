/*
 * Name: OGReplaceExpressionPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 23 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGReplaceExpression.h>
#import "OGReplaceExpressionPrivate.h"


@implementation OGReplaceExpression (Private)

- (void)_setCompiledReplaceString:(NSArray*)compiledReplaceString
{
	_compiledReplaceString = (NSMutableArray*)[compiledReplaceString retain];
}

- (void)_setCompiledReplaceStringType:(NSArray*)compiledReplaceStringType
{
	_compiledReplaceStringType = (NSMutableArray*)[compiledReplaceStringType retain];
}

- (void)_setNameArray:(NSArray*)nameArray
{
	_nameArray = (NSMutableArray*)[nameArray retain];
}

- (void)_setOptions:(unsigned)options
{
	_options = options;
}

@end

