#import "SortMyNotes.h"

static NSInteger selection = 4;
static NSMutableArray * favorites = [[NSMutableArray alloc] init];
static bool ascending = NO;
static bool sortFavorites = NO;

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
	NSLog(@"fr: %@", fr);
	[NSFetchedResultsController deleteCacheWithName:nil];
	[NSFetchedResultsController deleteCacheWithName:[listFRC cacheName]];
	NSSortDescriptor * sortDescriptor;

	if(index==0)
	{
		NSLog(@"1");
		selection = 1;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
		ascending = YES;
	}

	if(index==1)
	{
		NSLog(@"2");
		selection = 2;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];//selector:@selector(compareDesc:)
		ascending = NO;
	}

	if(index==2)
	{
		NSLog(@"3");
		selection = 3;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:YES];
		ascending = YES;
	}

	if(index==3)
	{
		NSLog(@"4");
		selection = 4;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:NO ];
		ascending = NO;
	}

	if(index==4)
	{
		NSLog(@"5");
		selection = 5;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
		ascending = YES;
	}

	if(index==5)
	{
		NSLog(@"6");
		selection = 6;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
		ascending = NO;
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

	sortFavorites = YES;

	if(![listFRC performFetch:&error])
	{
		//NSString * errorMessage = [[NSString alloc] initWithFormat:@"Domain: %@ Code : %lD",[error domain],(long)[error code]];
		//NSLog(@"error: %@",errorMessage);
	}

	UITableView * tbv = MSHookIvar<UITableView*>(self,"_table");
	NSLog(@"Table: %@",tbv);
	[tbv beginUpdates];
	[tbv reloadData];
	[tbv endUpdates];
}



%new -(NSComparisonResult)compareAsc:(NSString *)aString :(NSString*)bString
{
	NSLog(@"compareDesc aStr: %@, bStr: %@",aString, bString);
	if([favorites containsObject:aString])
	{
		return NSOrderedAscending;
	}
	else
		return [aString compare:bString];
}

-(id)tableView:(id)view cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell * original = %orig;
	UIButton *tap = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect frame = original.frame;
	frame.size.width /= 1.5f;
	frame.size.height /= 1.2f;
	frame.origin.x +=150.f;
	frame.origin.y +=5.f;
	[tap setBackgroundColor:[UIColor redColor]];
	[tap setFrame:frame];

	UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressTap:)];
	[tap addGestureRecognizer:longPress];
	[original addSubview:tap];

	NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(self,"_listFRC");

	NSString * guid = [[[listFRC fetchedObjects] objectAtIndex: indexPath.row] guid];
	NSLog(@"guidfor row: %@",guid);

	if([favorites containsObject:guid])
	{
		NSLog(@"guid is in favorites, indexPath %@", indexPath);
		UITableView * tbv = MSHookIvar<UITableView*>(self,"_table");
		NSLog(@"datasource: %@",[tbv dataSource]);
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
			NSLog(@"Error retrieivng GUID.");
			return;
		}

		NSLog(@"Pressed alternative row: %ld",(long)alternativeIP.row);
		NSString * guid = [[[listFRC fetchedObjects] objectAtIndex:alternativeIP.row] guid];	
		NSLog(@"guid: %@",guid);

		if(![favorites containsObject:guid])
		{
			[favorites addObject:guid];
		}else
		{
			[favorites removeObject:guid];
		}

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
	//NSLog(@"entities: %@", [listFRC fetchedObjects]);

	/*for(NoteObject *entry in [listFRC fetchedObjects])
	{
		NSLog(@"id: %@", entry.id);
	}*/
	//NSLog(@"id: %@",[[[listFRC fetchedObjects] objectAtIndex:0] data]);

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

%hook UITableViewDataSource

-(int)numberOfSectionsInTableView:(id)tableView{
	NSLog(@"numberOfSectionsInTableView");
	int ret = %orig;
	return ret;
}

-(id)tableView:(id)view cellForRowAtIndexPath:(id)indexPath{
	NSLog(@"datasource cellforrow");
	id ret = %orig;
	return ret;
}

%end

%hook NSString
/*
-(NSComparisonResult)compare:(NSString*)aString
{
	NSLog(@"Comparing");
	NSComparisonResult ret = %orig;
	NSLog(@"result:%@ %ld",aString, (long) ret);
	return ret;
}
- (long long)compare:(id)arg1 options:(unsigned long long)arg2{
	long long ret = %orig;
	NSLog(@"compare result: %@",arg1);
	return ret;
}
- (long long)localizedCaseInsensitiveCompare:(NSString *)arg1{
	NSLog(@"compare localizedCaseInsensitiveCompare, %@",arg1);
	long long ret = %orig;
	return ret;
}*/

- (long long)caseInsensitiveCompare:(id)arg1{
	NSLog(@"self: %@", [self description]);
	NSLog(@"compare caseInsensitiveCompare, %@",arg1);
	long long ret = %orig;
	return ret;
}
/*
- (long long)compare:(id)arg1 options:(unsigned long long)arg2 range:(id)arg3 locale:(id)arg4{
	//NSLog(@"self: %@", [self description]);
	NSLog(@"compare result range locale: %@",arg1);
	//NSLog(@"make: %llu",arg2);
	//NSLog(@"range: %@", arg3);
	long long ret = %orig;
	return ret;
}
- (long long)compare:(id)arg1 options:(unsigned long long)arg2 range:(id)arg3{
	//NSLog(@"self: %@", [self description]);
	NSLog(@"compare result just range: %@",arg1);
	//NSLog(@"make: %llu",arg2);
	//NSLog(@"range: %@", arg3);
	long long ret = %orig;
	return ret;
}*/
%end

%hook NSSortDescriptor

-(NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
	NSLog(@"Compare objects, %@ || %@",object1,object2);
	NSComparisonResult ret = %orig;
	return ret;

}

%end

%hook NSFetchedResultsController

-(NSArray*)fetchedObjects
{
	NSArray * ret = %orig;
    NSLog(@"array addres %p", ret);
	return ret;
}

-(BOOL)performFetch:(id*)arg1
{
	NSLog(@"PerformFetch nsfrc");
	bool b = %orig;
	NSArray * fetchedObjects = MSHookIvar<NSArray *>(self,"_fetchedObjects");
	NSLog(@"array addres %p", fetchedObjects);

	NSLog(@"nsfrc fetched: %@", fetchedObjects);
	NSLog(@"Bool: %ld",(long)b);

	if(b && [favorites count] >0 && sortFavorites)
	{
		NSLog(@"Altering fetch result");
		NSMutableArray * changedObjects = [[NSMutableArray alloc] initWithArray: fetchedObjects];
		for(long i=0; i < [changedObjects count]; i++)
		{
			NoteObject *note = [changedObjects objectAtIndex:i];
			if([favorites containsObject:[note guid]])
			{
				NSLog(@"Found a favorite and moving it,index: %ld",(long)i);
				id object = [changedObjects objectAtIndex:i];
				[[object retain] autorelease];
				[changedObjects removeObjectAtIndex:i];
				[changedObjects insertObject:object atIndex:0];
			}
		}
		NSLog(@"mutable: %@", changedObjects);
		NSLog(@"Reassigning array");
		[fetchedObjects release];
		fetchedObjects = nil;
		fetchedObjects = [[NSArray arrayWithArray:changedObjects] retain];
		[changedObjects release];
		NSLog(@"array addres %p", fetchedObjects);
		NSLog(@"new fetched: %@", fetchedObjects);
		NSArray * fetchedObjects2 = MSHookIvar<NSArray *>(self,"_fetchedObjects");
		NSLog(@"nsfrc fetched again: %@", fetchedObjects2);
		sortFavorites = NO;
	}
	return b;
}

- (BOOL)_objectInResults:(id)arg1{
	NSLog(@"_objectInResultsc");
	bool b = %orig;
	return b;
}
- (id)_indexPathForIndex:(unsigned int)arg1{
	NSLog(@"_indexPathForIndex");
	id i = %orig;
	return i;
}

- (void)_removeObjectInFetchedObjectsAtIndex:(unsigned int)arg1{
	NSLog(@"_removeObjectInFetchedObjectsAtIndex");
	%orig;
}

- (void)_insertObjectInFetchedObjects:(id)arg1 atIndex:(unsigned int)arg2{
	NSLog(@"_insertObjectInFetchedObjects");
	%orig;
}
- (unsigned int)_indexOfFetchedID:(id)arg1{
	NSLog(@"_indexOfFetchedID");
	unsigned int i = %orig;
	return i;
}
- (id)_fetchedObjectsArrayOfObjectIDs{
	NSLog(@"_fetchedObjectsArrayOfObjectIDs");
	id i = %orig;
	NSLog(@"ids: %@",i);
	return i;
}
- (void)_makeMutableFetchedObjects{
	NSLog(@"_makeMutableFetchedObjects");
	%orig;
}


%end

