#import <Foundation/NSObject.h>
#import "runtime.h"
#import "blocks_runtime.h"
#include <assert.h>

struct objc_class _NSConcreteGlobalBlock;
struct objc_class _NSConcreteStackBlock;

@interface NSBlockPrivate : NSObject @end

void __objc_update_dispatch_table_for_class(Class);
extern struct sarray *__objc_uninstalled_dtable;
extern objc_mutex_t __objc_runtime_mutex;
static void createNSBlockSubclass(Class newClass, char *name)
{
	Class superclass = [NSBlockPrivate class];
	// Create the metaclass
	Class metaClass = calloc(1, sizeof(struct objc_class));

	// Initialize the metaclass
	metaClass->class_pointer = superclass->class_pointer;
	metaClass->super_class = superclass->class_pointer->super_class;
	metaClass->info = _CLS_META;
	metaClass->dtable = __objc_uninstalled_dtable;

	// Set up the new class
	newClass->class_pointer = metaClass;
	newClass->super_class = superclass;
	newClass->name = name;
	newClass->info = _CLS_CLASS;
	newClass->dtable = __objc_uninstalled_dtable;

	// Initialize the dispatch table for the class and metaclass.
	__objc_update_dispatch_table_for_class(metaClass);
	__objc_update_dispatch_table_for_class(newClass);
	CLS_SETINITIALIZED(metaClass);
	CLS_SETINITIALIZED(newClass);
	// Add pointer from super class
	objc_mutex_lock(__objc_runtime_mutex);
	newClass->sibling_class = newClass->super_class->subclass_list;
	newClass->super_class->subclass_list = newClass;
	metaClass->sibling_class = metaClass->super_class->subclass_list;
	metaClass->super_class->subclass_list = metaClass;
	objc_mutex_unlock(__objc_runtime_mutex);
}

@implementation NSBlockPrivate
+ (void)load
{
	createNSBlockSubclass(&_NSConcreteGlobalBlock, "NSConcreteGlobalBlockPrivate");
	createNSBlockSubclass(&_NSConcreteStackBlock, "NSConcreteStackBlockPrivate");
}
- (id)copyWithZone: (NSZone*)aZone
{
	return __Block_copy(self);
}
- (id)copy
{
	return __Block_copy(self);
}
- (id)retain
{
	return __Block_copy(self);
}
- (void)release
{
	__Block_release(self);
}
- (void)dealloc 
{
	// Hack to get rid of compiler warning.
	if (0) [super dealloc];
}
@end

