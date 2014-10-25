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
    long getNumComponents = CGColorGetNumberOfComponents(color.CGColor);

    CGFloat r;
    CGFloat g;
    CGFloat b;

    if(getNumComponents==4)
    {
	    r = components[0];
	    g = components[1];
	    b = components[2];
	}
    else
    {
	    r = components[0];
	    g = components[0];
	    b = components[0];
    }

    return [NSString stringWithFormat:@"%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

%new - (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:0];
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

	if(index==7)
	{
		NSLog(@"Action canceled");
		return;
	}

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
		NSLog(@"SelectedNote: %@", [selectedNote title]);

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
	NSLog(@"Changing the color of the note from the ListController, index: %ld", (long)index);
	NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
	NSDate * creationDate = [noteToChangeColor creationDate];
	NSLog(@"noteToChangeColor: %@", [noteToChangeColor title]);

	if(index==14)
	{
		noteToChangeColor = nil;
		return;
	}

	if(index==0)
	{
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Enter The Hex Of The Color(no #)" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok",nil];
		alertView.tag=1;
		alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alertView show];
		[alertView release];
		return;
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

	[[NSUserDefaults standardUserDefaults] setObject:colorMap forKey:@"colorMap"];
	NSLog(@"Modified color - resorting");
	[self changeSort:selection-1];
	
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
				noteToChangeColor = nil;
			}
		}

	}
}

-(void)tableView:(id)view didSelectRowAtIndexPath:(id)indexPath
{
	/*if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		UITableView * tbv = view;
		if(tbv && ipath)
		{
			[tbv deselectRowAtIndexPath:ipath animated:YES];
		}
	}*/
	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		NSLog(@"didSelectRowAtIndexPath - iPad");
		UINavigationController * nav = [[UIApplication sharedApplication] navigationController];
		UINavigationBar * bar = [nav navigationBar];
		NSLog(@"rightItems: %@",[[bar topItem] rightBarButtonItems]);

		if([[[bar topItem] rightBarButtonItems] count] == 6  || [[[bar topItem] rightBarButtonItems] count] == 7)
		{
			NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
			
			NotesDisplayController * ndc = [[UIApplication sharedApplication] displayController];
			NoteObject * selectedNote = MSHookIvar<NoteObject*>(ndc,"_note");
			NSLog(@"selectedNote: %@", [selectedNote title]);

			if([favorites containsObject:[selectedNote creationDate]])
			{
				if([[[bar topItem] rightBarButtonItems] count] == 6)
				{
					NSLog(@"favorited selected by palette not added");
					NSString *colorPalette = @"\U0001F3A8\U0000FE0E";
					UIBarButtonItem * color = [[UIBarButtonItem alloc] initWithTitle:colorPalette style:UIBarButtonItemStylePlain target:ndc action:@selector(colorActionSheet)];
					[items addObject:color];
					[color release];
				}
				else
				{
					NSLog(@"(do nothing)the selected note is a favorite and palette is shown");
				}

			}
			else
			{
				if([[[bar topItem] rightBarButtonItems] count] == 6)
				{
					NSLog(@"(do nothing)the favorite is NOT selected and it doesn't have palette");
				}
				else
				{
					NSLog(@"favorited is NOT selected but has the palette, removing");
					[items removeObjectAtIndex:6];
				}
			}
			[[bar topItem] setRightBarButtonItems:items];
			NSLog(@"rightItems after: %@",[[bar topItem] rightBarButtonItems]);
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
		//alternativeIP = alt index path
		NSIndexPath  * alternativeIP = [tbv indexPathForRowAtPoint:p];

		if(alternativeIP ==nil)
		{
			NSLog(@"Error retrieivng creationDate.");
			return;
		}

		NSLog(@"Pressed alternative row: %ld",(long)alternativeIP.row);
		NSDate * creationDate = [[[listFRC fetchedObjects] objectAtIndex:alternativeIP.row] creationDate];	
		NSLog(@"date of note long pressed: %@",creationDate);
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

		NSLog(@"resorting after long press");
		[self changeSort:selection-1];
	}
}

%new - (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)clickedButtonAtIndex{
	//tag 1 = sort type from list controller(iphone)
	//tag 5 = sort type from display controller(ipad)
	//tag 2 = sort favortes from list controller(both iphone and ipad)
	//tag 3 = sort color from display controller(ipad)
	//tag 4 = sort color from display controller(iphone)
	NSLog(@"as_clickedButtonAtIndex - ListController, index: %ld",(long)clickedButtonAtIndex);
	if(actionSheet.tag==1 || actionSheet.tag==5)
	{
		if(clickedButtonAtIndex==6)
		{
			if(actionSheet.tag!=5)//if tag !=5, it is tag 1 which means we are in this action sheet from an iPhone
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
  			{
	  			NotesDisplayController * ndc = [[UIApplication sharedApplication] displayController];
				UIActionSheet * actionSheet2 =[[UIActionSheet alloc] initWithTitle:@"Sort favorites by color?"
				delegate:[ndc delegate]
				cancelButtonTitle:@"Cancel"
				destructiveButtonTitle:nil
				otherButtonTitles:@"Yes",@"No",nil];
				actionSheet2.tag = 2;

				UINavigationController * nav = [[UIApplication sharedApplication] navigationController];
			   	UINavigationBar * bar = [nav navigationBar];
			   	UIBarButtonItem * bi = nil;

				if([[[bar topItem] rightBarButtonItems] count] > 5)
				{
					NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
					bi = [items objectAtIndex:5];
				}

			   if(bi)
			   {
			   	    [actionSheet2 showFromBarButtonItem:bi animated:YES];
			   }
			   [actionSheet2 release];
  			}
		}
		else
			[self changeSort:clickedButtonAtIndex];
	}
	else if(actionSheet.tag==2)
	{
		bool sortFavCurrent = sortFavByColor;

		if(clickedButtonAtIndex==0)
		{
			sortFavByColor = YES;
		}else if(clickedButtonAtIndex==1)
		{
			sortFavByColor = NO;
		}

		//only sort if it differs from how it was previously
		if(sortFavCurrent != sortFavByColor)
			[self changeSort:selection-1];
	}
	else if(actionSheet.tag ==3 || actionSheet.tag==4)
	{
		[self changeColor:clickedButtonAtIndex];
	}

}


%new -(void)sortActionSheet{
   NSLog(@"sortActionSheet - ListController");

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
	NSLog(@"viewDidAppear - ListController");

	if( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
	{
		UINavigationController * nav = [self noteDisplayNavigationController];
		UINavigationBar * bar = [nav navigationBar];

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
	NSLog(@"viewWillAppear  - ListController");
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

		if(sortFavByColor)
		{
			NSArray * sortedKeys = [colorMap keysSortedByValueUsingComparator:^(NSString * obj1, NSString * obj2){
				return (NSComparisonResult)[obj1 compare:obj2];
			}];

			for(long i=0; i< [sortedKeys count]; i++)
			{
				for(long j=i; j< [favorites count]; j++)
				{
					NoteObject * note = [fetchedObjects objectAtIndex:j];
					if([[dateFormat stringFromDate:[note creationDate]] isEqualToString:[sortedKeys objectAtIndex:i]] && i!=j)
					{
						[fetchedObjects exchangeObjectAtIndex:i withObjectAtIndex:j];
						break;
					}
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
   NSLog(@"sortActionSheet - DisplayController");
   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
   														delegate:[self delegate]
   														cancelButtonTitle:@"Cancel"
   														destructiveButtonTitle:nil
   														otherButtonTitles:alphaAscending,alphaDescending,modAscending,modDescending,createAscending,createDescending,sortFavDescription,nil];
   actionSheet.tag = 5;
   UINavigationController * nav = [[UIApplication sharedApplication] navigationController];
   UINavigationBar * bar = [nav navigationBar];
   UIBarButtonItem * bi = nil;

	if([[[bar topItem] rightBarButtonItems] count] > 5)
	{
		NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
		bi = [items objectAtIndex:5];
	}

   if(bi)
   {
   	    [actionSheet showFromBarButtonItem:bi animated:YES];
   }
   [actionSheet release];

}

%new -(void)colorActionSheet{
   NSLog(@"colorActionSheet - DisplayController");

   noteToChangeColor = MSHookIvar<NoteObject*>(self,"_note");
   NSLog(@"noteToChangeColor: %@",[noteToChangeColor title]);

	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		NSLog(@"colorActionSheet_dc - ipad");
	   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
	   														delegate:[self delegate]
	   														cancelButtonTitle:@"Cancel"
	   														destructiveButtonTitle:nil
	   														otherButtonTitles:customColor,redColor,greenColor,blueColor,cyanColor,yellowColor,magentaColor,orangeColor,purpleColor,brownColor,blackColor,darkGrayColor,lightGrayColor,grayColor,nil];
	   actionSheet.tag=3;
	   
	   //Get the button item for the Action Sheet to point to
	   UINavigationController * nav = [[UIApplication sharedApplication] navigationController];
	   UINavigationBar * bar = [nav navigationBar];
	   UIBarButtonItem * bi = nil;

		if([[[bar topItem] rightBarButtonItems] count] == 7)
		{
			NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
			bi = [items objectAtIndex:6];
		}

	   if(bi)
	   {
	   	    [actionSheet showFromBarButtonItem:bi animated:YES];
	   }

	   [actionSheet release];
	}
	else
	{
		NSLog(@"colorActionSheet_dc - iphone");
	   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
	   														delegate:[self delegate]
	   														cancelButtonTitle:@"Cancel"
	   														destructiveButtonTitle:nil
	   														otherButtonTitles:customColor,redColor,greenColor,blueColor,cyanColor,yellowColor,magentaColor,orangeColor,purpleColor,brownColor,blackColor,darkGrayColor,lightGrayColor,grayColor,nil];
	   actionSheet.tag=4;
	   UIView * mview = MSHookIvar<UIView*>(self,"_backgroundView");
	   [actionSheet showInView:mview];
	   [actionSheet release];
	}
}

-(void)viewDidAppear:(BOOL)view{
	NSLog(@"viewDidAppear - DisplayController");

	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		NSLog(@"vda_dc - ipad");
		UINavigationController * nav = [[UIApplication sharedApplication] navigationController];
		UINavigationBar * bar = [nav navigationBar];

		//NSLog(@"rightItems: %@",[[bar topItem] rightBarButtonItems]); //can use this to visually verify the correct amount of button items

		if([[[bar topItem] rightBarButtonItems] count] < 6)
		{
			NSMutableArray * items = [(NSArray*)[[bar topItem] rightBarButtonItems] mutableCopy];
			UIBarButtonItem *btnSort = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(sortActionSheet)];
			[items addObject:btnSort];

			NoteObject * selectedNote = MSHookIvar<NoteObject*>(self,"_note");
			NSLog(@"selectedNote: %@", [selectedNote title]);

			if([favorites containsObject:[selectedNote creationDate]])
			{
				NSString *colorPalette = @"\U0001F3A8\U0000FE0E";
				UIBarButtonItem * color = [[UIBarButtonItem alloc] initWithTitle:colorPalette style:UIBarButtonItemStylePlain target:self action:@selector(colorActionSheet)];
				[items addObject:color];
				[color release];
			}
			[[bar topItem] setRightBarButtonItems:items];
			[btnSort release];
		}
	}
	else
	{
		NSLog(@"vda_dc - iphone");
		NoteObject * selectedNote = MSHookIvar<NoteObject*>(self,"_note");
		NSLog(@"selectedNote: %@", [selectedNote title]);

		if([favorites containsObject:[selectedNote creationDate]])
		{
			UINavigationController * nav = [[UIApplication sharedApplication] navigationController];
			UINavigationBar * bar = [nav navigationBar];

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