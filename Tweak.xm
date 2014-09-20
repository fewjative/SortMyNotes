#import "SortMyNotes.h"

static NSInteger selection = 4;

%hook NotesListController

NSString *alphaAscending = @"Alphabetically(Ascending)";
NSString *alphaDescending = @"Alphabetically(Descending)";

NSString *modAscending = @"Modification Date(Ascending)";
NSString *modDescending = @"Modification Date(Descending)";

NSString *createAscending = @"Creation Date(Ascending)";
NSString *createDescending = @"Creation Date(Descending)";

%new -(void)changeSort:(NSInteger)index {

	NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(self,"_listFRC");
	NSLog(@"listFRC : %@", listFRC);
	NSFetchRequest *fr = [listFRC fetchRequest];
	[NSFetchedResultsController deleteCacheWithName:nil];
	[NSFetchedResultsController deleteCacheWithName:[listFRC cacheName]];
	NSSortDescriptor * sortDescriptor;

	if(index==0)
	{
		NSLog(@"1");
		selection = 1;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
	}

	if(index==1)
	{
		NSLog(@"2");
		selection = 2;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
	}

	if(index==2)
	{
		NSLog(@"3");
		selection = 3;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:YES];
	}

	if(index==3)
	{
		NSLog(@"4");
		selection = 4;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:NO];
	}

	if(index==4)
	{
		NSLog(@"5");
		selection = 5;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
	}

	if(index==5)
	{
		NSLog(@"6");
		selection = 6;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	}

	if(index==6)
	{
		NSLog(@"Cancel");
		return;
	}

	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor,nil];
	[fr setSortDescriptors:sortDescriptors];
	NSLog(@"fetchRequest's sorting changed");

	NSError *error = nil;

	if(![listFRC performFetch:&error])
	{
		NSString * errorMessage = [[NSString alloc] initWithFormat:@"Domain: %@ Code : %lD",[error domain],(long)[error code]];
		NSLog(@"error: %@",errorMessage);
	}

	UITableView * tbv = MSHookIvar<UITableView*>(self,"_table");
	NSLog(@"Table: %@",tbv);
	[tbv beginUpdates];
	[tbv reloadData];
	[tbv endUpdates];

}

%new - (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)clickedButtonAtIndex{

	[self changeSort:clickedButtonAtIndex];
}


%new -(void)sortActionSheet{
   NSLog(@"Bringing up action sheet");

   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
   														delegate:self
   														cancelButtonTitle:@"Cancel"
   														destructiveButtonTitle:nil
   														otherButtonTitles:alphaAscending,alphaDescending,modAscending,modDescending,createAscending,createDescending,nil];
   UIView * mview = MSHookIvar<UIView*>(self,"_backgroundView");
   [actionSheet showInView:mview];
}

-(void)viewDidAppear:(BOOL)view{

	%orig;
	NSLog(@"ViewDidAppear");
	NSLog(@"Sorting choice: %li",(long)selection);

    UINavigationController * ret = [self noteDisplayNavigationController];
    NSLog(@"view controllers: %@", [ret viewControllers]);
	UINavigationBar * bar = [ret navigationBar];
	NSLog(@"nav bar: %@", bar);
	NSLog(@"top items: %@", [bar topItem]);

	if([[[bar topItem] rightBarButtonItems] count] < 2)
	{
		UIBarButtonItem * add = [[bar topItem] rightBarButtonItem];
	    UIBarButtonItem *btnSort = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sortActionSheet)];
	    [[bar topItem] setRightBarButtonItems:[NSArray arrayWithObjects:add,btnSort,nil]];
	}

	if(selection !=4)
	{
		[self actionSheet:nil clickedButtonAtIndex:selection-1];
	}

}

-(void)viewWillAppear:(BOOL)view{

	NSLog(@"ViewWillAppear");
	%orig;

	NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(self,"_listFRC");
	NSLog(@"listFRC : %@", listFRC);

	if(selection !=4)
	{
		[self changeSort:selection-1];
	}
}

-(void)reloadTables {
	NSLog(@"reloadTables");
	%orig;

	[self changeSort:selection-1];
}

%end