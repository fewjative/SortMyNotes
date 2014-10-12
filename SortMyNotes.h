@interface NSObject ()
@property (assign,nonatomic) UIEdgeInsets clippingInsets;
@property (copy, nonatomic) NSString *message;
@property (copy, nonatomic) NSString *subtitle;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *sectionID;
@property (copy, nonatomic) id defaultAction;
+ (id)action;
+ (id)sharedInstance;
- (void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSInteger)arg3;
- (void)_replaceIntervalElapsed;
- (void)_dismissIntervalElapsed;
- (BOOL)containsAttachments;
- (void)setSecondaryText:(id)arg1 italicized:(BOOL)arg2;
- (int)_ui_resolvedTextAlignment;

- (UILabel *)tb_titleLabel;
- (void)tb_setTitleLabel:(UILabel *)label;
- (void)tb_setSecondaryLabel:(UILabel *)label;

@end

@interface NoteObject:NSObject
{
}
@property (copy, nonatomic) NSString * guid;
@property (copy, nonatomic) NSDate * creationDate;
@end

#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSPersistentStore.h>
#import <CoreData/NSPersistentStoreCoordinator.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObject.h>
#import <Foundation/NSString.h>

@interface NotesListController : UIViewController <UIActionSheetDelegate>
{
	NSFetchedResultsController* _listFRC;
}
- (void)reloadTables;
- (id)noteDisplayNavigationController;
-(void)changeSort:(NSInteger)index;
@end

@interface UIApplication ()
-(NotesListController*)listController;
-(id)displayController;
-(id)navigationController;
-(id)mainViewController;
@end

@interface NotesDisplayController : UIViewController <UIActionSheetDelegate>
-(void)changeSort:(NSInteger)index;
-(void)sortActionSheetTest;
-(id)delegate;
@end