#import "SortMyNotes.h"

static NSInteger selection = 4;
static NSMutableArray * favorites;
static bool ascending = NO;
static bool sortFavorites = NO;

%hook NotesListController

NSString *alphaAscending = @"Alphabetically(\u2B06\U0000FE0E)";
NSString *alphaDescending = @"Alphabetically(\u2B07\U0000FE0E)";

NSString *modAscending = @"Modification Date(\u2B06\U0000FE0E)";
NSString *modDescending = @"Modification Date(\u2B07\U0000FE0E)";

NSString *createAscending = @"Creation Date(\u2B06\U0000FE0E)";
NSString *createDescending = @"Creation Date(\u2B07\U0000FE0E)";

%new -(void)changeSort:(NSInteger)index {
	NSLog(@"Changing the sort type");

	NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(self,"_listFRC");
	NSFetchRequest *fr = [listFRC fetchRequest];
	[NSFetchedResultsController deleteCacheWithName:nil];
	[NSFetchedResultsController deleteCacheWithName:[listFRC cacheName]];
	NSSortDescriptor * sortDescriptor;

	if(index==0)
	{
		selection = 1;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
		ascending = YES;
	}

	if(index==1)
	{
		selection = 2;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
		ascending = NO;
	}

	if(index==2)
	{
		selection = 3;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:YES];
		ascending = YES;
	}

	if(index==3)
	{
		selection = 4;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:NO ];
		ascending = NO;
	}

	if(index==4)
	{
		selection = 5;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
		ascending = YES;
	}

	if(index==5)
	{
		selection = 6;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
		ascending = NO;
	}

	if(index==6)
	{
		return;
	}

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:selection] forKey:@"NotesSelection"];

	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor,nil];
	[fr setSortDescriptors:sortDescriptors];

	NSError *error = nil;

	sortFavorites = YES;

	if(![listFRC performFetch:&error])
	{
		NSLog(@"error domain: %@",[error domain]);
		NSLog(@"error code: %llu",(long long unsigned)[error code]);
	}

	UITableView * tbv = MSHookIvar<UITableView*>(self,"_table");
	[tbv beginUpdates];
	[tbv reloadData];
	[tbv endUpdates];
}

-(id)tableView:(id)view cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell * original = %orig;

	NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(self,"_listFRC");

	NSDate * creationDate = [[[listFRC fetchedObjects] objectAtIndex: indexPath.row] creationDate];
	NSLog(@"date for row: %@",creationDate);
	NSLog(@"row: %ld", (long)indexPath.row);

	if([favorites containsObject:creationDate])
	{
		NSLog(@"creationDate is in favorites, indexPath %@", indexPath);
		UIView * v = [[UIView alloc] initWithFrame:original.frame];
		v.backgroundColor = [UIColor colorWithRed:1.00 green:0.95 blue:0.80 alpha:1.0];
		original.backgroundView = v;
		[v release];
	}
	else
	{
		UIView * v = [[UIView alloc] initWithFrame:original.frame];
		v.backgroundColor = [UIColor clearColor];
		original.backgroundView = v;
		[v release];
	}

	return original;
}

%new - (void)longPressTap:(UILongPressGestureRecognizer*)sender
{
	NSLog(@"Long press detected");

	if(sender.state==UIGestureRecognizerStateEnded)
	{
		NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(self,"_listFRC");
		UITableView * tbv = MSHookIvar<UITableView*>(self,"_table");

		CGPoint p = [sender locationInView:tbv];
		NSIndexPath  * alternativeIP = [tbv indexPathForRowAtPoint:p];

		if(alternativeIP ==nil)
		{
			NSLog(@"Error retrieivng creationDate.");
			return;
		}

		NSLog(@"Pressed alternative row: %ld",(long)alternativeIP.row);
		NSDate * creationDate = [[[listFRC fetchedObjects] objectAtIndex:alternativeIP.row] creationDate];	
		NSLog(@"creationDate: %@",creationDate);

		if(![favorites containsObject:creationDate])
		{
			[favorites insertObject:creationDate atIndex:0];
		}
		else
		{
			[favorites removeObject:creationDate];
		}

		[[NSUserDefaults standardUserDefaults] setObject:favorites forKey:@"NotesFavorites"];

		[self changeSort:selection-1];
	}
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
	UINavigationBar * bar = [ret navigationBar];

	if([[[bar topItem] rightBarButtonItems] count] < 2)
	{
		UIBarButtonItem * add = [[bar topItem] rightBarButtonItem];
	    UIBarButtonItem *btnSort = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sortActionSheet)];
	    [[bar topItem] setRightBarButtonItems:[NSArray arrayWithObjects:add,btnSort,nil]];
	}

	[self changeSort:selection-1];
	
}

-(void)viewWillAppear:(BOOL)view{
	NSLog(@"ViewWillAppear");
	%orig;

	id selectionobj = [[NSUserDefaults standardUserDefaults] objectForKey:@"NotesSelection"];

	if(selectionobj== nil)
	{
		selection = 4;
	}
	else
	{
		selection = [selectionobj intValue];
	}

	favorites = [[NSUserDefaults standardUserDefaults] objectForKey:@"NotesFavorites"];
	if(!favorites)
	{
		favorites  = [[NSMutableArray alloc] init];
	}else
	{
		favorites = [[NSMutableArray alloc] initWithArray:favorites];
	}

	UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressTap:)];
	UITableView * tbv = MSHookIvar<UITableView*>(self,"_table");
	[tbv addGestureRecognizer:longPress];
	[longPress release];

	[self changeSort:selection-1];
}

-(void)reloadTables {
	NSLog(@"reloadTables");
	%orig;

	[self changeSort:selection-1];
}

%end

%hook NSFetchedResultsController

-(BOOL)performFetch:(id*)arg1
{
	//MORE TO MY NOTES
	//need to change this sot hat it only effects sorting that comes from the Notes app
	NSLog(@"PerformFetch");
	bool b = %orig;
	
	if(b && [favorites count] >0 && sortFavorites)
	{
		NSLog(@"Have a favorite, modifying table");
		[self _makeMutableFetchedObjects];
		NSMutableArray * fetchedObjects = MSHookIvar<NSMutableArray*>(self,"_fetchedObjects");
		NSMutableArray * favCopy = [[NSMutableArray alloc] initWithArray:favorites copyItems:YES];

		for(long i=0; i < [fetchedObjects count]; i++)
		{
			NoteObject *note = [fetchedObjects objectAtIndex:i];
			if([favorites containsObject:[note creationDate]])
			{
				NSLog(@"Found a favorite and moving it,index: %ld",(long)i);
				id object = [fetchedObjects objectAtIndex:i];
				[[object retain] autorelease];
				[fetchedObjects removeObjectAtIndex:i];
				[fetchedObjects insertObject:object atIndex:0];
				[favCopy removeObject:[note creationDate]];
			}
		}

		for(long i=0; i < [favCopy count]; i++)//removes favorites that have been deleted
		{
			NSDate *creationDate = [favCopy objectAtIndex:i];
			[favorites removeObject:creationDate];
		}

		for(long i=0; i< [favorites count]; i++)
		{
			NoteObject * note = [fetchedObjects objectAtIndex:i];
			long newIndex = [favorites indexOfObject:[note creationDate]];

			if(i != newIndex)
			{
				[fetchedObjects exchangeObjectAtIndex:i withObjectAtIndex:newIndex];
			}
		}

		[[NSUserDefaults standardUserDefaults] setObject:favorites forKey:@"NotesFavorites"];

		sortFavorites = NO;
	}

	return b;
}

%end

