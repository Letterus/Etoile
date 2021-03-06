/*
	IKIconPositions.h

	IKIconPositions is where possible positions to composite 
	IKIcon object are declared.

	Copyright (C) 2005 Uli Kusterer <contact@zathras.de>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Uli Kusterer <contact@zathras.de>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2005

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import <Foundation/Foundation.h>

// Flags from which IKBadgePositions are made up. Don't use these, use IKBadgePosition:
enum _IKBadgePositionFlags
{
    IKBadgePositionFlagBottom       = (1 << 0),
    IKBadgePositionFlagLeft         = (1 << 1),
    IKBadgePositionFlagTop          = (1 << 2),
    IKBadgePositionFlagRight        = (1 << 3),
    IKBadgePositionFlagCenter       = (1 << 4),
    IKBadgePositionFlagSemantic     = (1 << 15), // High bit set means: interpret low 15 bits as icon number.
    IKBadgePositionFlagSemanticMask = 0x7FFF     // Use this to mask out the high bit. (Is this endian-safe?)
};

// Badge position values for badgeRectForPosition:
typedef enum _IKBadgePosition
{
    // Semantic positions: (map to absolute positions, but may change depending on OS/theme)
    // Use e.g. IKBadgePositionStandardSymlink for the theme-provided symlink arrow icon *only*! (they map to full-size on Mac because there the system badges *are* full size)
    // For other icons, use e.g. IKBadgePositionSymlink instead!!!
    IKBadgePositionStandardLink             = (IKBadgePositionFlagSemantic | 0),
    IKBadgePositionLink                     = (IKBadgePositionFlagSemantic | 1),
    IKBadgePositionStandardReadOnly         = (IKBadgePositionFlagSemantic | 2),
    IKBadgePositionReadOnly                 = (IKBadgePositionFlagSemantic | 3),
    IKBadgePositionStandardDocumentSubIcon  = (IKBadgePositionFlagSemantic | 4),
    IKBadgePositionDocumentSubIcon          = (IKBadgePositionFlagSemantic | 5),
    IKBadgePositionStandardPluginSubIcon    = (IKBadgePositionFlagSemantic | 6),
    IKBadgePositionPluginSubIcon            = (IKBadgePositionFlagSemantic | 7),
    IKBadgePositionStandardLocked           = (IKBadgePositionFlagSemantic | 8),
    IKBadgePositionLocked                   = (IKBadgePositionFlagSemantic | 9),
    IKBadgePositionStandardScript           = (IKBadgePositionFlagSemantic | 10),
    IKBadgePositionScript                   = (IKBadgePositionFlagSemantic | 11),
    IKBadgePositionStandardWriteOnly        = (IKBadgePositionFlagSemantic | 12),
    IKBadgePositionWriteOnly                = (IKBadgePositionFlagSemantic | 13),
	// ... up to 32767 special icon positions :-)
    
    // Absolute positions:
    IKBadgePositionNone             = 0,
    IKBadgePositionBottom           = (IKBadgePositionFlagBottom | IKBadgePositionFlagCenter),
    IKBadgePositionBottomLeft       = (IKBadgePositionFlagBottom | IKBadgePositionFlagLeft),
    IKBadgePositionBottomRight      = (IKBadgePositionFlagBottom | IKBadgePositionFlagRight),
    IKBadgePositionTop              = (IKBadgePositionFlagTop | IKBadgePositionFlagCenter),
    IKBadgePositionTopLeft          = (IKBadgePositionFlagTop | IKBadgePositionFlagLeft),
    IKBadgePositionTopRight         = (IKBadgePositionFlagTop | IKBadgePositionFlagRight),
    IKBadgePositionLeft             = (IKBadgePositionFlagLeft | IKBadgePositionFlagCenter),
    IKBadgePositionRight            = (IKBadgePositionFlagRight | IKBadgePositionFlagCenter),
    IKBadgePositionCenter           = (IKBadgePositionFlagCenter)
} IKBadgePosition;
