#import <Foundation/NSObject.h>

@interface NSObject (Prototypes)
/**
 * Adds the specified method to this instance.  Objects modified in this way get
 * a hidden dictionary for non-indexed instance variables, allowing them to use
 * KVC to set arbitrary objects on self.
 */
- (void) setMethod:(IMP)aMethod forSelector:(SEL)aSelector;
/**
 * Provides a clone of the object in the specified zone.  Requires the class to
 * implement copyWithZone: to perform the copy, then performs a hidden class
 * transform to make it into a new prototype.
 */
- (id) cloneWithZone: (NSZone *)zone;
/**
 * Returns YES if this object is a prototype.
 */
- (BOOL) isPrototype;
/**
 * Returns the prototype for this object, or nil if this object does not have
 * one.
 */
- (id) prototype;
/**
 * Performs a hidden class transform, making this object into a prototype.
 */
- (void) becomePrototype;
@end
