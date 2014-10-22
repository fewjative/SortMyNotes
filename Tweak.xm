#import "SortMyNotes.h"

static NSInteger selection = 4;
static NSMutableArray * favorites;
static bool ascending = NO;
static bool sortFavorites = NO;
static NSIndexPath * ipath = nil;
static NoteObject * selectedNote = nil;
static NoteObject * noteToChangeColor = nil;
static bool sortFavByColor = NO;
static NSMutableDictionary *colorMap = nil;

%hook NotesListController

NSString *alphaAscending = @"Alphabetically \u2B06\U0000FE0E";
NSString *alphaDescending = @"Alphabetically \u2B07\U0000FE0E";

NSString *modAscending = @"Modification Date \u2B06\U0000FE0E";
NSString *modDescending = @"Modification Date \u2B07\U0000FE0E";

NSString *createAscending = @"Creation Date \u2B06\U0000FE0E";
NSString *createDescending = @"Creation Date \u2B07\U0000FE0E";

NSString *sortFavDescription = @"Sort Favorites by Color?";

NSString * blackColor = @"Black";
UIColor * blackColorUI = [UIColor blackColor];
NSString * darkGrayColor = @"Dark Gray";
UIColor * darkGrayColorUI = [UIColor darkGrayColor];
NSString * lightGrayColor = @"Light Gray";
UIColor * lightGrayColorUI = [UIColor lightGrayColor];
NSString * grayColor = @"Gray";
UIColor * grayColorUI = [UIColor grayColor];
NSString * redColor = @"Red";
UIColor * redColorUI = [UIColor redColor];
NSString * greenColor = @"Green";
UIColor * greenColorUI = [UIColor greenColor];
NSString * blueColor = @"Blue";
UIColor * blueColorUI = [UIColor blueColor];
NSString * cyanColor = @"Cyan";
UIColor * cyanColorUI = [UIColor cyanColor];
NSString * yellowColor = @"Yellow";
UIColor * yellowColorUI = [UIColor yellowColor];
NSString * magentaColor = @"Magenta";
UIColor * magentaColorUI = [UIColor magentaColor];
NSString * orangeColor = @"Orange";
UIColor * orangeColorUI = [UIColor orangeColor];
NSString * purpleColor = @"Purple";
UIColor * purpleColorUI = [UIColor purpleColor];
NSString * brownColor = @"Brown";
UIColor * brownColorUI = [UIColor brownColor];
NSString * customColor = @"Custom Color";

%new - (NSString *)hexStringFromColor:(UIColor *)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];

    return [NSString stringWithFormat:@"%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

%new - (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:0]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:0.7];
}

%new -(void)changeSort:(NSInteger)index {
	NSLog(@"Changing the sort type from the ListController");

	NotesListController * nlc = [[UIApplication sharedApplication] listController];
	NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(nlc,"_listFRC");
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

	/*INDEX 6 is handled in the original click delegate method */

	if(index==7)
	{
		NSLog(@"Action canceled");
		return;
	}

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:selection] forKey:@"NotesSelection"];
	[[NSUserDefaults standardUserDefaults] setBool:sortFavByColor forKey:@"NotesSortFavColor"];

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

	NSLog(@"indexpath: %@",ipath);
	[tbv beginUpdates];
	// Why not reloadData? Because it removes the table cell selection/highlight
	//[tbv reloadData];
	[tbv reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
	[tbv endUpdates];

	if( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
	{
		if(ipath)
		{
			ipath = nil;
		}
	}
	else
	{
		NotesDisplayController * ndc = [[UIApplication sharedApplication] displayController];
		selectedNote = MSHookIvar<NoteObject*>(ndc,"_note");
		NSLog(@"SelectedNote: %@", selectedNote);
		if(selectedNote)
		{
			NSArray * fetchedObjects = [listFRC fetchedObjects];
			long row = [fetchedObjects indexOfObject:selectedNote];
			NSIndexPath * scrollPath = [NSIndexPath indexPathForRow:row inSection:0];
			[tbv scrollToRowAtIndexPath:scrollPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
		}
	}
}

%new -(void)changeColor:(NSInteger)index {
	NSLog(@"Changing the color of the note from the ListController");
	NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
	NSDate * creationDate = [noteToChangeColor creationDate];

	if(index==0)
	{
		//SET CUSTOM COLOR
		//DISPLAY POPUP
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Enter The Hex Of The Color(no #)" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok",nil];
		alertView.tag=1;
		alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alertView show];
		[alertView release];
	}

	if(index==1)
	{
		[colorMap setObject:[self hexStringFromColor:redColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==2)
	{
		[colorMap setObject:[self hexStringFromColor:greenColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==3)
	{
		[colorMap setObject:[self hexStringFromColor:blueColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==4)
	{
		[colorMap setObject:[self hexStringFromColor:cyanColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==5)
	{
		[colorMap setObject:[self hexStringFromColor:yellowColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==6)
	{
		[colorMap setObject:[self hexStringFromColor:magentaColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==7)
	{
		[colorMap setObject:[self hexStringFromColor:orangeColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==8)
	{
		[colorMap setObject:[self hexStringFromColor:purpleColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==9)
	{
		[colorMap setObject:[self hexStringFromColor:brownColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==10)
	{
		[colorMap setObject:[self hexStringFromColor:blackColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==11)
	{
		[colorMap setObject:[self hexStringFromColor:darkGrayColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==12)
	{
		[colorMap setObject:[self hexStringFromColor:lightGrayColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if(index==13)
	{
		[colorMap setObject:[self hexStringFromColor:grayColorUI] forKey:[dateFormat stringFromDate:creationDate]];
	}

	if( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
	{
		if(index !=0)
		{
			[[NSUserDefaults standardUserDefaults] setObject:colorMap forKey:@"colorMap"];
			[self changeSort:selection-1];
		}
	}

	if(index==14)
	{
		noteToChangeColor = nil;
		return;
	}
	//IF NOT IPAD, SAVE NSUSERDEFAULTS NO. IF IPAD PERFORM REFRESH?
}

%new -(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if(buttonIndex==0)
	{
		noteToChangeColor = nil;
		return;
	}
	else
	{
		UITextField * alertTextField = [alertView textFieldAtIndex:0];
		NSLog(@"text from alert: %@",alertTextField.text);
		if(alertTextField.text.length !=6)
		{
			noteToChangeColor = nil;
		}
		else
		{
			NSCharacterSet * chars = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"] invertedSet];
			BOOL isValid = (NSNotFound == [alertTextField.text rangeOfCharacterFromSet:chars].location);
			if(isValid)
			{
				NSLog(@"Valid custom hex");
				NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
				[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
				NSDate * creationDate = [noteToChangeColor creationDate];
				[colorMap setObject:alertTextField.text forKey:[dateFormat stringFromDate:creationDate]];
				[[NSUserDefaults standardUserDefaults] setObject:colorMap forKey:@"colorMap"];
				noteToChangeColor = nil;
				[self changeSort:selection-1];
			}
			else
			{
				//display a popup saying invalid?
				noteToChangeColor = nil;
			}
		}

	}
}

-(void)tableView:(id)view didSelectRowAtIndexPath:(id)indexPath
{
	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		UITableView * tbv = view;
		if(tbv && ipath)
		{
			[tbv deselectRowAtIndexPath:ipath animated:YES];
		}
	}

	ipath = indexPath;
	%orig;
}

-(id)tableView:(id)view cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell * original = %orig;

	NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(self,"_listFRC");

	NSDate * creationDate = [[[listFRC fetchedObjects] objectAtIndex: indexPath.row] creationDate];
	NSString * searchTerms = MSHookIvar<NSString*>(self,"_searching");

	if([favorites containsObject:creationDate] && searchTerms ==nil)
	{
		NSLog(@"creationDate is in favorites, indexPath %@", indexPath);
		UIView * v = [[UIView alloc] initWithFrame:original.frame];
		NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
		v.backgroundColor = [self colorFromHexString:[colorMap objectForKey:[dateFormat stringFromDate:creationDate]]];
		NSLog(@"v.backgroundColor : %@", v.backgroundColor);
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
		NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];

		if(![favorites containsObject:creationDate])
		{
			[favorites insertObject:creationDate atIndex:0];			
			[colorMap setObject:[self hexStringFromColor:yellowColorUI] forKey:[dateFormat stringFromDate:creationDate]];
		}
		else
		{
			[favorites removeObject:creationDate];
			[colorMap removeObjectForKey:[dateFormat stringFromDate:creationDate]];
		}

		[[NSUserDefaults standardUserDefaults] setObject:favorites forKey:@"NotesFavorites"];
		[[NSUserDefaults standardUserDefaults] setObject:colorMap forKey:@"colorMap"];

		[self changeSort:selection-1];
	}
}

%new - (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)clickedButtonAtIndex{
	
	if(actionSheet.tag==1)
	{
		if(clickedButtonAtIndex==6)
		{
			UIActionSheet *actionSheet2 = [[UIActionSheet alloc] initWithTitle:@"Sort favorites by color?"
   														delegate:self
   														cancelButtonTitle:@"Cancel"
   														destructiveButtonTitle:nil
   														otherButtonTitles:@"Yes",@"No",nil];

			actionSheet2.tag = 2;
			UIView * mview = MSHookIvar<UIView*>(self,"_backgroundView");
  			[actionSheet2 showInView:mview];
  			[actionSheet2 release];
		}
		else
			[self changeSort:clickedButtonAtIndex];
	}
	else if(actionSheet.tag==2)
	{
		if(clickedButtonAtIndex==0)
		{
			sortFavByColor = YES;
		}else if(clickedButtonAtIndex==1)
		{
			sortFavByColor = NO;
		}

		[self changeSort:selection-1];//we don't want to change the main sorting type of the table so we use the previous stored value
	}
	else if(actionSheet.tag ==3 || actionSheet.tag==4)
	{
		NSLog(@"ColorSheet action sheet pressed");
		[self changeColor:clickedButtonAtIndex];
	}

}


%new -(void)sortActionSheet{
   NSLog(@"Bringing up action sheet");

   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
   														delegate:self
   														cancelButtonTitle:@"Cancel"
   														destructiveButtonTitle:nil
   														otherButtonTitles:alphaAscending,alphaDescending,modAscending,modDescending,createAscending,createDescending,sortFavDescription,nil];
   actionSheet.tag = 1;

  
   UIView * mview = MSHookIvar<UIView*>(self,"_backgroundView");
   [actionSheet showInView:mview];
   [actionSheet release];

}

-(void)viewDidAppear:(BOOL)view{

	%orig;
	NSLog(@"ViewDidAppear");

	NSLog(@"Sorting choice: %li",(long)selection);

    UINavigationController * ret = [self noteDisplayNavigationController];
	UINavigationBar * bar = [ret navigationBar];

	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		/*
		Initialize iPad items in NotesDisplayController
		*/
	}
	else
	{
		if([[[bar topItem] rightBarButtonItems] count] < 2)
		{
			UIBarButtonItem * add = [[bar topItem] rightBarButtonItem];
		    UIBarButtonItem *btnSort = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(sortActionSheet)];
		    [[bar topItem] setRightBarButtonItems:[NSArray arrayWithObjects:add,btnSort,nil]];
		    [btnSort release];
		}
	}	
}

-(void)viewWillAppear:(BOOL)view{
	NSLog(@"ViewWillAppear, bool %ld",(long)view);
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

	sortFavByColor = [[NSUserDefaults standardUserDefaults] boolForKey:@"NotesSortFavColor"];

	colorMap = [[NSUserDefaults standardUserDefaults] objectForKey:@"colorMap"];

	if(!colorMap)
	{
		colorMap = [[NSMutableDictionary alloc] init];
	}
	else
	{
		colorMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"colorMap"] mutableCopy];
		//can we just replace the above with colorMap = [colorMap mutableCopy];?
	}

	UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressTap:)];
	UITableView * tbv = MSHookIvar<UITableView*>(self,"_table");
	[tbv addGestureRecognizer:longPress];
	[longPress release];


	if( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
	{
		NSLog(@"ipath: %@", ipath);
		if(!ipath)
		{
			[self changeSort:selection-1];
		}
		ipath = nil;
	}
	else
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
		NSLog(@"SortFavsByColor? : %lu",(long)sortFavByColor);

		[self _makeMutableFetchedObjects];
		NSMutableArray * fetchedObjects = MSHookIvar<NSMutableArray*>(self,"_fetchedObjects");
		NSMutableArray * favCopy = [[NSMutableArray alloc] initWithArray:favorites copyItems:YES];

		NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];

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
				[favCopy removeObject:[note creationDate]];//favCopy contains date objects and thus we don't need to convert to string
			}
		}

		for(long i=0; i < [favCopy count]; i++)//removes favorites that have been deleted
		{
			NSDate *creationDate = [favCopy objectAtIndex:i];
			[favorites removeObject:creationDate];
			[colorMap removeObjectForKey:[dateFormat stringFromDate:creationDate]];
		}

		//Removes extras from the dictionary
		/*NSMutableArray * allKeys = [[colorMap allKeys] mutableCopy];

		for(long j=0; j < [allKeys count]; j++)
		{
			if(![favorites containsObject:[dateFormat dateFromString:[allKeys objectAtIndex:j]]])
			{
				[colorMap removeObjectForKey:[allKeys objectAtIndex:j]];
			}
		}*/

		if(sortFavByColor)
		{
			NSArray * sortedKeys = [colorMap keysSortedByValueUsingComparator:^(NSString * obj1, NSString * obj2){
				return (NSComparisonResult)[obj1 compare:obj2];
			}];

			NSLog(@"keys %@",sortedKeys);
			NSLog(@"fav count: %ld",(long)[favorites count]);

			for(long i=0; i< [favorites count]; i++)
			{
				NoteObject * note = [fetchedObjects objectAtIndex:i];
				NSLog(@"note: %@", note);
				long newIndex = [sortedKeys indexOfObject:[dateFormat stringFromDate:[note creationDate]]];

				if(i != newIndex)
				{
					[fetchedObjects exchangeObjectAtIndex:i withObjectAtIndex:newIndex];
				}
			}

		}
		else
		{
			for(long i=0; i< [favorites count]; i++)
			{
				NoteObject * note = [fetchedObjects objectAtIndex:i];
				long newIndex = [favorites indexOfObject:[note creationDate]];

				if(i != newIndex)
				{
					[fetchedObjects exchangeObjectAtIndex:i withObjectAtIndex:newIndex];
				}
			}
		}



		[[NSUserDefaults standardUserDefaults] setObject:favorites forKey:@"NotesFavorites"];

		sortFavorites = NO;
	}

	return b;
}

%end

%hook NotesDisplayController

%new -(void)sortActionSheet{
   NSLog(@"Bringing up action sheet for the iPad");
   NotesDisplayController * ndc = [[UIApplication sharedApplication] displayController];
   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
   														delegate:[ndc delegate]
   														cancelButtonTitle:@"Cancel"
   														destructiveButtonTitle:nil
   														otherButtonTitles:alphaAscending,alphaDescending,modAscending,modDescending,createAscending,createDescending,nil];

   UINavigationController * ret = [[UIApplication sharedApplication] navigationController];
   UINavigationBar * bar = [ret navigationBar];
   UIBarButtonItem * bi = nil;

	if([[[bar topItem] rightBarButtonItems] count] == 6)
	{
		NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
		bi = [items objectAtIndex:5];
	}

   if(bi)
   {
   	    [actionSheet showFromBarButtonItem:bi animated:YES];
   }

}

%new -(void)colorActionSheet{
   NSLog(@"Bringing up the color action sheet");

   noteToChangeColor = MSHookIvar<NoteObject*>(self,"_note");

	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
	   NotesDisplayController * ndc = [[UIApplication sharedApplication] displayController];
	   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
	   														delegate:[ndc delegate]
	   														cancelButtonTitle:@"Cancel"
	   														destructiveButtonTitle:nil
	   														otherButtonTitles:customColor,redColor,greenColor,blueColor,cyanColor,yellowColor,magentaColor,orangeColor,purpleColor,brownColor,blackColor,darkGrayColor,lightGrayColor,grayColor,nil];
	   actionSheet.tag=3;
	   UINavigationController * ret = [[UIApplication sharedApplication] navigationController];
	   UINavigationBar * bar = [ret navigationBar];
	   UIBarButtonItem * bi = nil;

		if([[[bar topItem] rightBarButtonItems] count] == 7)
		{
			NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
			bi = [items objectAtIndex:7];
		}

	   if(bi)
	   {
	   	    [actionSheet showFromBarButtonItem:bi animated:YES];
	   	    [actionSheet release];
	   }
	}
	else
	{
		NotesDisplayController * ndc = [[UIApplication sharedApplication] displayController];
	   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
	   														delegate:[ndc delegate]
	   														cancelButtonTitle:@"Cancel"
	   														destructiveButtonTitle:nil
	   														otherButtonTitles:customColor,redColor,greenColor,blueColor,cyanColor,yellowColor,magentaColor,orangeColor,purpleColor,brownColor,blackColor,darkGrayColor,lightGrayColor,grayColor,nil];
	   actionSheet.tag=4;
	   UIView * mview = MSHookIvar<UIView*>(self,"_backgroundView");
	   [actionSheet showInView:mview];
	   [actionSheet release];
	}
}

/*%new -(void)sortActionSheetTest{
   NSLog(@"Bringing up action sheet for the iPad");
   NotesDisplayController * ndc = [[UIApplication sharedApplication] displayController];
   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
   														delegate:[ndc delegate]
   														cancelButtonTitle:@"Cancel"
   														destructiveButtonTitle:nil
   														otherButtonTitles:alphaAscending,alphaDescending,modAscending,modDescending,createAscending,createDescending,nil];
   UIView * mview = MSHookIvar<UIView*>(self,"_backgroundView");
   [actionSheet showInView:mview];

}*/

%new - (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)clickedButtonAtIndex{
	NSLog(@"clickedButton on DisplayController actionsheets");
	if(actionSheet.tag ==3 || actionSheet.tag==4)
	{
		NSLog(@"ColorSheet action sheet pressed");
	}
	else
		[self changeSort:clickedButtonAtIndex];
}

%new -(void)changeSort:(NSInteger)index {
	NSLog(@"Changing the sort type for the iPad");

	NotesListController * nlc = [[UIApplication sharedApplication] listController];
	NSFetchedResultsController* listFRC = MSHookIvar<NSFetchedResultsController*>(nlc,"_listFRC");

	NoteObject * selectedNote = MSHookIvar<NoteObject*>(self,"_note");

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

	UITableView * tbv = MSHookIvar<UITableView*>(nlc,"_table");
	NSLog(@"iPad table: %@", tbv);

	NSLog(@"indexpath: %@",ipath);
	[tbv beginUpdates];
	[tbv reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
	[tbv endUpdates];

	if(selectedNote)
	{
		NSArray * fetchedObjects = [listFRC fetchedObjects];
		long row = [fetchedObjects indexOfObject:selectedNote];
		NSIndexPath * scrollPath = [NSIndexPath indexPathForRow:row inSection:0];
		[tbv scrollToRowAtIndexPath:scrollPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
	}
}


-(void)viewDidAppear:(BOOL)view{

	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		UINavigationController * ret = [[UIApplication sharedApplication] navigationController];
		NSLog(@"navController: %@", ret);

		UINavigationBar * bar = [ret navigationBar];
		NSLog(@"navbar: %@",bar);
		NSLog(@"topItem: %@",[bar topItem]);
		NSLog(@"rightItems: %@",[[bar topItem] rightBarButtonItems]);

		if([[[bar topItem] rightBarButtonItems] count] < 6)
		{
			NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
			UIBarButtonItem *btnSort = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(sortActionSheet)];
			[items addObject:btnSort];
			[[bar topItem] setRightBarButtonItems:items];
			[btnSort release];
		}

		/*UIBarButtonItem * bi = MSHookIvar<UIBarButtonItem*>(self,"_shareButtonItem");
		UIViewController * target = bi.target;

		ret = target.navigationController;
		NSLog(@"navController: %@", ret);

		bar = [ret navigationBar];
		NSLog(@"navbar: %@",bar);
		NSLog(@"topItem: %@",[bar topItem]);
		NSLog(@"rightItems: %@",[[bar topItem] rightBarButtonItems]);

		if([[[bar topItem] rightBarButtonItems] count] < 6)
		{
			NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
			UIBarButtonItem *btnSort = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(sortActionSheet)];
			[items addObject:btnSort];
			[[bar topItem] setRightBarButtonItems:items];
			[btnSort release];
		}*/
	}
	else
	{
		NoteObject * selectedNote = MSHookIvar<NoteObject*>(self,"_note");
		if([favorites containsObject:[selectedNote creationDate]])
		{
			UINavigationController * ret = [[UIApplication sharedApplication] navigationController];
			UINavigationBar * bar = [ret navigationBar];
			NSLog(@"navc: %@", ret);
			NSLog(@"bar: %@",bar);

			if([[[bar topItem] rightBarButtonItems] count] < 1)
			{
				NSString *colorPalette = @"\U0001F3A8\U0000FE0E";
				UIBarButtonItem * color = [[UIBarButtonItem alloc] initWithTitle:colorPalette style:UIBarButtonItemStylePlain target:self action:@selector(colorActionSheet)];
			    [[bar topItem] setRightBarButtonItems:[NSArray arrayWithObjects:color,nil]];
			    [color release];
			}
		}
	}
}

%end

%hook NotesListTableView

-(void)deselectRowAtIndexPath:(NSIndexPath*)indexPath animated:(BOOL)view
{
	NSLog(@"deselected: row %ld, animated: %ld",(long)indexPath.row,(long)view);
	%orig;
}

%end
