/** <title>ETDecoratorItem</title>

	<abstract>ETUIItem subclass which makes possibe to decorate any layout 
	items, usually with a widget view.</abstract>

	Copyright (C) 20O9 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETUIItem.h>

@class ETLayoutItemGroup, ETView;


/** Decorator class which can be subclassed to turn wrapper-like widgets such 
as scrollers, windows, group boxes etc., provided by the widget backend 
(e.g. AppKit), into decorator items to be applied to the semantic items that 
make up the layout item tree.

ETDecoratorItem can be seen as an ETLayoutItem variant with limited abilities 
and whose instances don't have a semantic role, hence they remain invisible 
in the layout item tree. They allow EtoileUI to maintain a very tight mapping 
between the model graph and the layout item tree. By limiting the number of 
non-semantic nodes in the tree, the feeling of working with real and cohesive 
objects is greatly enhanced at both code and UI level.

A decorator item must currently not break the following rules (this is subject 
to change though):
<list>
<item>[self displayView] must return [[self decoratorItem] supervisorView]</item>
<item>[self supervisorView] must return [[[self decoratorItem] supervisorView] wrappedView]</item>
</list>
However -supervisorView can be overriden to return nil. */
@interface ETDecoratorItem : ETUIItem
{
	ETUIItem *_decoratedItem; // previous decorator (weak reference)
}

+ (id) item;

- (id) initWithSupervisorView: (ETView *)supervisorView;

- (BOOL) usesWidgetView;

/* Decoration Geometry */

- (void) setDecorationRect: (NSRect)rect;
- (void) setAutoresizingMask: (unsigned int)aMask;

- (NSRect) visibleRect;
- (NSRect) visibleContentRect;
- (NSRect) contentRect;

- (NSRect) convertDecoratorRectFromContent: (NSRect)rectInContent;
- (NSPoint) convertDecoratorPointFromContent: (NSPoint)aPoint;
- (NSRect) convertDecoratorRectToContent: (NSRect)rectInDecorator;
- (NSPoint) convertDecoratorPointToContent: (NSPoint)aPoint;
- (NSSize) decorationSizeForContentSize: (NSSize)aSize;

- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flipped;

/* Subclass Hooks */

- (BOOL) canDecorateItem: (ETUIItem *)item;
- (void) handleDecorateItem: (ETUIItem *)item 
             supervisorView: (ETView *)decoratedView 
                     inView: (ETView *)parentView;
- (void) handleUndecorateItem: (ETUIItem *)item inView: (ETView *)parentView;
- (void) handleSetDecorationRect: (NSRect)rect;
- (NSSize) decoratedItemRectChanged: (NSRect)rect;

/* Private Use */

- (void) setDecoratedItem: (ETUIItem *)item;
- (ETUIItem *) decoratedItemAtPoint: (NSPoint)aPoint;

@end

