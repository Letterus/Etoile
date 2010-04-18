@protocol OgreTextFindProgressDelegate 
// show progress
- (void)setProgress:(double)progression message:(NSString*)message; // progression < 0: indeterminate
- (void)setDonePerTotalMessage:(NSString*)message;
// finish
- (void)done:(double)progression message:(NSString*)message; // progression < 0: indeterminate

// close
- (void)close:(id)sender;
- (void)setReleaseWhenOKButtonClicked:(BOOL)shouldRelease;

// cancel
- (void)setCancelSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject;

// show error alert
- (void)showErrorAlert:(NSString*)title message:(NSString*)errorMessage;
@end