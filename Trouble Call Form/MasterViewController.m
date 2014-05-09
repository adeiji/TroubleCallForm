//
//  MasterViewController.m
//  Trouble Call Form
//
//  Created by Developer on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MasterViewController.h"
#import "sqlite3.h"
#import "DetailViewController.h"
#import "JobNumberViewController.h"
#import "ArrayStorage.h"
#import <UIKit/UIKit.h>

@interface MasterViewController () {
    sqlite3 *contactDB;
    NSString *databasePath;
    NSMutableArray *myHoistSrlNumbers;
    NSMutableArray *containsOrders;
    BOOL firstRun;
   // NSMutableArray *myJobNumbers;
    //JobNumberViewController *JNVController;
}
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize hoistSrlArray;
@synthesize JobNumberVC = _JobNumberVC;
@synthesize JNVController;

- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void) GetValuesFromDatabase
{
    //NSURL *url = [NSURL URLWithString:@"shiloh/"];
    
   // NSString *result = [[NSString alloc] initWithContentsOfURL:url encoding:<#(NSStringEncoding)#> error:<#(NSError *__autoreleasing *)#>
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [self.splitViewController setPresentsWithGesture:NO];
    containsOrders = [[NSMutableArray alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    documentsDir = [paths objectAtIndex:0];
    //full file location string
    databasePath = [[NSString alloc] initWithString:[documentsDir stringByAppendingPathComponent:@"contacts.db"]];
    //databasePath = @"/Users/Developer/Documents/databases/contacts.db";
    paths = nil;
    documentsDir = nil;
    [self GetValuesFromDatabase];
    
    JNVController = [self.storyboard instantiateViewControllerWithIdentifier:@"JNVController"];
    [JNVController LoadMasterViewController:self];
    [self createDatabase];
    //myJobNumbers = [[NSMutableArray alloc] init];
    myHoistSrlNumbers = [[NSMutableArray alloc] init];
    [myHoistSrlNumbers addObject:@"Add New Crane/Job +"];
    [self GetHoistNumbers];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(RefreshHoistSrlNumbers:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    if (self.detailViewController == nil)
    {
        self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
        [self.detailViewController LoadMasterViewController:self];
    }
    
    if (__managedObjectContext == nil) 
	{ 
        __managedObjectContext = [(MasterViewController *)[[UIApplication sharedApplication] delegate] managedObjectContext]; 
        //NSLog(@"After managedObjectContext_: %@",  managedObjectContext_);
	}
    
    //Initialize the array.
    listOfItems = [[NSMutableArray alloc] init];
 
    //Initialize the copy array and search array for searching.
    copyListOfItems = [[NSMutableArray alloc] init];
    searchArray = [[NSMutableArray alloc] init];
    //Add the search bar
    self.tableView.tableHeaderView = searchBar;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    
    searching = NO;
    letUserSelectRow = YES;
    //this method will go through every hoistsrl and see which hoistsrl contains orders
    [self DoesContainOrders];
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    //[self setJobNumberVC:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) UpdateHoistSrlArray:(NSString *) input
{
    if (![myHoistSrlNumbers containsObject:input])
    {
        [myHoistSrlNumbers addObject:input];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)insertNewObject:(id)sender
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void) DoesContainOrders
{
    [containsOrders removeAllObjects];
    int count;
    if (!searching)
        count = myHoistSrlNumbers.count;
    else {
        count = copyListOfItems.count;
    }
    for (int row = 0; row < count; row++)
    {
        if (!searching)
        {
            [self LoadJobNumbers:[myHoistSrlNumbers objectAtIndex:row]];
            
            if (JNVController.jobNumberArray.count > 0)
                [containsOrders addObject:@"YES"];
            else {
                [containsOrders addObject:@"NO"];
            }
        }
        else {
            [self LoadJobNumbers:[copyListOfItems objectAtIndex:row]];
            if (JNVController.jobNumberArray.count > 0)
                [containsOrders addObject:@"YES"];
            else {
                [containsOrders addObject:@"NO"];
            }
        }
        //JNVController.jobNumberArray = nil;
    }
    count = 0;
}

- (BOOL) isWaterDistrictCrane: (NSString *) myHoistSrl
{
    sqlite3_stmt *statement;
    //get the path where to hold the database
    
    const char *dbPath = [databasePath UTF8String];
    bool orderExist = NO;
    [myHoistSrlNumbers removeAllObjects];
    
    [myHoistSrlNumbers addObject:@"Add New Crane/Job +"];
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT HOISTSRL FROM WATERDISTRICTCRANES WHERE HOISTSRL=\"%@\";", myHoistSrl];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        selectSQL = nil;
        select_stmt = nil;
        sqlite3_close(contactDB);
    }
    return orderExist;
}

- (void) GetHoistNumbers
{
    sqlite3_stmt *statement;
    //get the path where to hold the database
    
    const char *dbPath = [databasePath UTF8String];
    bool orderExist = NO;
    [myHoistSrlNumbers removeAllObjects];
    
    [myHoistSrlNumbers addObject:@"Add New Crane/Job +"];
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
       // NSString *selectSQL = [NSString stringWithFormat:@"SELECT HOISTSRL FROM JOBS UNION ALL SELECT HOISTSRL FROM ALLTROUBLEORDERS UNION ALL SELECT HOISTSRL FROM WATERDISTRICTCRANES;"];
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT HOISTSRL FROM JOBS UNION ALL SELECT HOISTSRL FROM ALLTROUBLEORDERS;"];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                const char *chHoistSrl = (char*) sqlite3_column_text(statement, 0);
                
                NSString *hoistSrl = [NSString stringWithUTF8String:chHoistSrl];
                
                if (![myHoistSrlNumbers containsObject:hoistSrl])
                {
                    [myHoistSrlNumbers addObject:hoistSrl]; 
                    //NSLog(@"Retrieved condition from the table");
                }
                
                //release memory
                chHoistSrl = nil;
                hoistSrl = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        selectSQL = nil;
        select_stmt = nil;
        sqlite3_close(contactDB);
    }
}

- (void) DeleteCrane:(NSString *) hoistSrl
{
    sqlite3_stmt *statement;
    //get the path where to hold the database
    
    const char *dbPath = [databasePath UTF8String];

    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *removeSQL = [NSString stringWithFormat:@"DELETE FROM JOBS WHERE HOISTSRL=\"%@\"", hoistSrl];
        const char *remove_stmt = [removeSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, remove_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            //sqlite3_bind_text(statement, 1, [txtJobNumber.text UTF8String], -1, NULL);
        }
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Crane Removed Succesfully from Jobs table");
        }   
        else 
        {
            NSLog(@"Error removing crane from Jobs Table");
        }
        sqlite3_finalize(statement);
        
        removeSQL = [NSString stringWithFormat:@"DELETE FROM ALLTROUBLEORDERS WHERE HOISTSRL=\"%@\"", hoistSrl];
        remove_stmt = [removeSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, remove_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            //sqlite3_bind_text(statement, 1, [txtJobNumber.text UTF8String], -1, NULL);
        }
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"ORDER Removed Succesfully from Jobs table");
        }   
        else 
        {
            NSLog(@"Error removing crane from Jobs Table");
        }
        sqlite3_close(contactDB);
        removeSQL = nil;
        remove_stmt = nil;
    }
}

- (void) UpdateJobTables:(NSString *) myHoistSrl
{
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];
    
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO UPDATEJOBORDERS (HOISTSRL, JOBNUMBER, DATE, OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH, ACTION) VALUES(\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\");",
                           myHoistSrl,
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"DELETE"];
    
    //check to make sure that the database is correct
    if (sqlite3_open(dbPath, &contactDB) == SQLITE_OK)
    {
        const char *insert_stmt = [insertSQL UTF8String];
        
        sqlite3_prepare_v2(contactDB, insert_stmt, -1, &statement, nil);
        
        if (sqlite3_step(statement) != SQLITE_DONE)
        {
            NSAssert(0, @"Error updating table: UPDATEJOBORDERS");
        }
        else {
            NSLog(@"Inserted successfully");
        }
        sqlite3_finalize(statement);
        sqlite3_close(contactDB);
    }
    //delete from the UPDATEJOBS table, this table stores all the changes that have been done to the cranes
    insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO UPDATEJOBS (HOISTSRL, CUSTOMERNAME, CONTACT, JOBNUMBER, DATE, ADDRESS, EMAIL, EQUIPNUM, CRANEMFG, HOISTMFG, HOISTMDL, CRANEDESCRIPTION, CAP, CRANESRL, ACTION) VALUES(\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\");",
                           myHoistSrl,
                           @"",
                           @"",
                           @"" ,
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"DELETE"];
    //NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ALLORDERS (JOBNUMBER, PART, DEFICIENT, DEFICIENTPART, NOTES, PICKERSELECTION) VALUES (?,?,?,?,?,?)"];
    
    
    //check to make sure that the database is correct
    if (sqlite3_open(dbPath, &contactDB) == SQLITE_OK)
    {
        const char *insert_stmt = [insertSQL UTF8String];
        
        sqlite3_prepare_v2(contactDB, insert_stmt, -1, &statement, nil);
        
        if (sqlite3_step(statement) != SQLITE_DONE)
        {
            NSAssert(0, @"Error updating table: UPDATEJOBS");
        }
        else {
            NSLog(@"Inserted successfully");
            //UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Customer Added" message:@"The Customer Contact Information was Saved" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            //[view show];
        }
        sqlite3_close(contactDB);
    }
    insertSQL = nil;
}

- (void) createTable {
    
    NSString *querySql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS ALLTROUBLEORDERS (ID INTEGER PRIMARY KEY AUTOINCREMENT, HOISTSRL TEXT, JOBNUMBER TEXT, DATE TEXT, OPCHECK TEXT, WORKPERFORMED TEXT, MATERIALUSED TEXT, MATERIALORDERED TEXT, MFGMDL TEXT, CHAINLENGTH TEXT, ROPELENGTH TEXT)"];
    const char *sql_stmt = [querySql UTF8String];
    char *errMess;
    
    //open the database
    if (sqlite3_open([databasePath UTF8String], &contactDB) == SQLITE_OK)
    {
        //creates the table using the querySql NSString
        if (sqlite3_exec(contactDB, sql_stmt, NULL, NULL, &errMess) == SQLITE_OK) 
        {
            NSLog(@"ALL TROUBLE ORDERS TABLE CREATED");
        }
        sqlite3_close(contactDB);
    }

    //release memory
    querySql = nil;
    sql_stmt = nil;
    
    querySql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS IPADOWNER (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT)"];
    sql_stmt = [querySql UTF8String];
    
    //open the database
    if (sqlite3_open([databasePath UTF8String], &contactDB) == SQLITE_OK)
    {
        //creates the table using the querySql NSString
        if (sqlite3_exec(contactDB, sql_stmt, NULL, NULL, &errMess) == SQLITE_OK) 
        {
            NSLog(@"ALL TROUBLE ORDERS TABLE CREATED");
        }
        sqlite3_close(contactDB);
    }
    
    //release memory
    querySql = nil;
    sql_stmt = nil;
    errMess = nil;
    
    querySql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS JOBS (ID INTEGER PRIMARY KEY AUTOINCREMENT, HOISTSRL TEXT, CUSTOMERNAME TEXT, CONTACT TEXT, JOBNUMBER TEXT, DATE TEXT, ADDRESS TEXT, EMAIL TEXT, EQUIPNUM TEXT, CRANEMFG TEXT, HOISTMFG TEXT, HOISTMDL TEXT, CRANEDESCRIPTION TEXT, CAP TEXT, CRANESRL TEXT)"];
    sql_stmt = [querySql UTF8String];
    
    //open the database
    if (sqlite3_open([databasePath UTF8String], &contactDB) == SQLITE_OK)
    {
        //creates the table using the querySql NSString
        if (sqlite3_exec(contactDB, sql_stmt, NULL, NULL, &errMess) == SQLITE_OK) 
        {
            NSLog(@"JOBS TABLE CREATED");
        }
        sqlite3_close(contactDB);
    }
    
    //release memory
    querySql = nil;
    sql_stmt = nil;
    errMess = nil;
    
    [self InsertName];
}


- (void) InsertName
{
    /*
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];
    
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO IPADOWNER (NAME) VALUES (\"%@\");",
                           @"Chuck"];
    //NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ALLORDERS (JOBNUMBER, PART, DEFICIENT, DEFICIENTPART, NOTES, PICKERSELECTION) VALUES (?,?,?,?,?,?)"];
    
    
    //check to make sure that the database is correct
    if (sqlite3_open(dbPath, &contactDB) == SQLITE_OK)
    {
        const char *insert_stmt = [insertSQL UTF8String];
        
        sqlite3_prepare_v2(contactDB, insert_stmt, -1, &statement, nil);
        
        if (sqlite3_step(statement) != SQLITE_DONE)
        {
            NSAssert(0, @"Error updating table: ALLTROUBLEORDERS");
        }
        else {
            NSLog(@"Inserted successfully");
            //UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Customer Added" message:@"The Customer Contact Information was Saved" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            //[view show];
        }
    }
 */
}


- (void) createDatabase
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    if ([fileMgr fileExistsAtPath: databasePath ] == NO)
    {
        const char *dbpath = [databasePath UTF8String];

        if (sqlite3_open(dbpath, &contactDB) == SQLITE_OK)
        {
            if (sqlite3_exec(contactDB, "PRAGMA CACHE_SIZE=50;", NULL, NULL, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to set cache size with message '%s'.", sqlite3_errmsg(contactDB));
            }
            sqlite3_close(contactDB);
            
        } else {
            NSLog(@"Failed to create the database");
            //txtDate.text = @"Failed to open/create database";
        }
        // Modify cache size so we don't overload memory. 50 * 1.5kb
    }
    [self createTable];
    //release memory
    fileMgr = nil;
}

#pragma mark - Table View

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
    //return [[self.fetchedResultsController sections] count];
  //  return 1;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (searching)
        return [copyListOfItems count];
    else {
        return [myHoistSrlNumbers count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell;
    NSInteger row = [indexPath row];
    

    if ([[containsOrders objectAtIndex:row] isEqual:@"YES"])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"EmptyCell"];    
    }
    if (!searching)
    {
        cell.textLabel.text = [myHoistSrlNumbers objectAtIndex:row];
    }
    else 
    {
        cell.textLabel.text = [copyListOfItems objectAtIndex:row];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        
        if (!searching)
        {
            //[context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
            [self DeleteCrane:selectedCell.textLabel.text];
            [self UpdateJobTables:selectedCell.textLabel.text];
            [self RefreshHoistSrlNumbers:nil];
            [tableView reloadData];
            
        }
        else {
            [self DeleteCrane:selectedCell.textLabel.text];
            [self UpdateJobTables:selectedCell.textLabel.text];
            if (![self isWaterDistrictCrane:selectedCell.textLabel.text])
            {
                [copyListOfItems removeObject:selectedCell.textLabel.text];
            }
            [self RefreshHoistSrlNumbers:nil];
            [tableView reloadData];
        }
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //[self.navigationController pushViewController:_JobNumberVC animated:YES];
    //NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
   // self.detailViewController.detailItem = object;
    
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *cellText = selectedCell.textLabel.text;

    if (![self.detailViewController.CIVController isViewLoaded])
    {
        self.detailViewController.CIVController = [self.storyboard instantiateViewControllerWithIdentifier:@"CIVController"];
        [self.detailViewController.CIVController LoadMasterViewController:self];
        [self.detailViewController.navigationController pushViewController:self.detailViewController.CIVController animated:YES];
    }
    [self LoadJobNumbers:cellText];
    [self PushJNVControllerOntoStack:cellText];
    [self.detailViewController.CIVController EmptyOrderFormFields];
    
    cellText = nil;
}

- (void) LoadJobNumbers: (NSString *) hoistSrl
{
    sqlite3_stmt *statement;

    const char *dbPath = [databasePath UTF8String];
    bool orderExist = NO;

    JNVController.jobNumberArray = [[NSMutableArray alloc] init ];
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT JOBNUMBER FROM ALLTROUBLEORDERS WHERE HOISTSRL=\"%@\"", hoistSrl];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                const char *chJobNumber = (char*) sqlite3_column_text(statement, 0);
                
                NSString *jobNumber = [NSString stringWithUTF8String:chJobNumber];
                
                if (![JNVController.jobNumberArray containsObject:jobNumber])
                {
                    [JNVController.jobNumberArray addObject:jobNumber]; 
                }
                //NSLog(@"Retrieved condition from the table");
                //release memory
                chJobNumber = nil;
                jobNumber = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        select_stmt = nil;
        selectSQL = nil;
        sqlite3_close(contactDB);
        
    }
    dbPath = nil;
    statement =nil;
    hoistSrl = nil;
}
//This method will push the JNVController onto the view controller stack and then fill out the customer form
- (void) PushJNVControllerOntoStack : (NSString *) hoistSrl
{
    if ([hoistSrl isEqualToString:@"Add New Crane/Job +"])
    {
        [self.detailViewController.CIVController EmptyOrderFormFields];
        [self.detailViewController.CIVController EmptyTextFields];
        if (![[self.detailViewController.navigationController viewControllers] containsObject:self.detailViewController.CIVController])
        {
            [self.detailViewController.navigationController pushViewController:self.detailViewController.CIVController animated:YES];
        }
        else {
            [self.detailViewController.navigationController popToViewController:self.detailViewController.CIVController animated:YES];
        }
    }
    if (![JNVController.jobNumberArray count] == 0)
    {
        [JNVController.tableView reloadData];
        [self.navigationController pushViewController:JNVController animated:YES ];
        [self.detailViewController.CIVController EmptyOrderFormFields];
    }
    

    [self FillOutCustomerForm:hoistSrl];
    JNVController.hoistSrl = hoistSrl;   
}
//This method grabs all the information about the customer from JOBS and then it fills out the CIVController form with the correct information
- (void) FillOutCustomerForm : (NSString *) hoistSrl
{
    sqlite3_stmt *statement;

    const char *dbPath = [databasePath UTF8String];
    bool orderExist = NO; 
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
       // NSString *selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT CUSTOMERNAME, CONTACT, ADDRESS, EMAIL, EQUIPNUM, CRANEMFG, HOISTMFG, HOISTMDL, CRANEDESCRIPTION, CAP, CRANESRL FROM JOBS WHERE HOISTSRL=\"%@\" UNION ALL SELECT DISTINCT CUSTOMERNAME, CONTACT, ADDRESS, EMAIL, EQUIPNUM, CRANEMFG, HOISTMFG, HOISTMDL, CRANEDESCRIPTION, CAP, CRANESRL FROM WATERDISTRICTCRANES WHERE HOISTSRL=\"%@\";", hoistSrl, hoistSrl];
         NSString *selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT CUSTOMERNAME, CONTACT, ADDRESS, EMAIL, EQUIPNUM, CRANEMFG, HOISTMFG, HOISTMDL, CRANEDESCRIPTION, CAP, CRANESRL FROM JOBS WHERE HOISTSRL=\"%@\";", hoistSrl];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                    
                const char *chCustName = (char*) sqlite3_column_text(statement, 0);
                const char *chContact = (char*) sqlite3_column_text(statement, 1);
                const char *chAddress = (char*) sqlite3_column_text(statement, 2);
                const char *chEmail = (char*) sqlite3_column_text(statement, 3);
                const char *chEquipNum = (char*) sqlite3_column_text(statement, 4);
                const char *chCraneMfg = (char*) sqlite3_column_text(statement, 5);
                const char *chHoistMfg = (char*) sqlite3_column_text(statement, 6);
                const char *chHoistMdl = (char*) sqlite3_column_text(statement, 7);
                const char *chCraneDescription = (char*) sqlite3_column_text(statement, 8);
                const char *chCap = (char*) sqlite3_column_text(statement, 9);
                const char *chCraneSrl = (char*) sqlite3_column_text(statement, 10);
                
                NSString *custName = [NSString stringWithUTF8String:chCustName];
                NSString *contact = [NSString stringWithUTF8String:chContact];
                NSString *address = [NSString stringWithUTF8String:chAddress];
                NSString *email = [NSString stringWithUTF8String:chEmail];
                NSString *equipNum = [NSString stringWithUTF8String:chEquipNum];
                NSString *craneMfg = [NSString stringWithUTF8String:chCraneMfg];
                NSString *hoistMfg = [NSString stringWithUTF8String:chHoistMfg];
                NSString *hoistMdl = [NSString stringWithUTF8String:chHoistMdl];
                NSString *craneDescription = [NSString stringWithUTF8String:chCraneDescription];
                NSString *cap = [NSString stringWithUTF8String:chCap];
                NSString *craneSrl = [NSString stringWithUTF8String:chCraneSrl];
                
               // NSLog(@"Retrieved condition from the table");
                //release memory
                
                chCustName = nil;
                chContact = nil;
                chAddress = nil;
                chEmail = nil;
                chEquipNum = nil;
                chCraneMfg = nil;
                chHoistMfg = nil;
                chHoistMdl = nil;
                chCraneDescription = nil;
                chCap = nil;
                chCraneSrl = nil;
                
                if ([self.detailViewController.navigationController.viewControllers containsObject:self.detailViewController.CIVController])
                {
                    [self.detailViewController.navigationController popToViewController:self.detailViewController.CIVController animated:YES];

                    //[self.detailViewController.navigationController pushViewController:self.detailViewController.CIVController animated:YES];
                    //[self.detailViewController.CIVController LoadMasterViewController:self];
                }
                else
                {
                    [self.detailViewController.navigationController pushViewController:self.detailViewController.CIVController animated:YES];
                }
                //first we need to empty every text box that is on the CIV Controller UIScreen, because then if the crane that they select does not have every field saved within the database
                //when it is selected a field from the previous crane will stay displayed which will be incorrect because it won't be the correct details for the new crane
                [self.detailViewController.CIVController EmptyTextFields];
                [self.detailViewController.CIVController UpdateTextFields:hoistSrl
                                                                         :custName
                                                                         :contact
                                                                         :address
                                                                         :email
                                                                         :equipNum
                                                                         :craneMfg
                                                                         :hoistMfg
                                                                         :hoistMdl
                                                                         :craneDescription
                                                                         :cap
                                                                         :craneSrl];
                [self.detailViewController.CIVController FillLocalVariables];
                custName =nil;
                contact = nil;
                address =nil;
                email = nil;
                equipNum = nil;
                craneMfg = nil;
                hoistMfg = nil;
                hoistMdl = nil;
                craneDescription = nil;
                cap = nil;
                craneSrl = nil;
            }
            sqlite3_finalize(statement);
            sqlite3_close(contactDB);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
    }
    
}


//This method will write a CSV files from the tables that are inside of the database that is stored on the iPad
- (void) WriteCSVFiles
{
    
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
}

#pragma mark Search Bar
- (void) searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
    
    searching = YES;
    letUserSelectRow = YES;
    self.tableView.scrollEnabled = YES;
    
    //Add the done button.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                               target:self action:@selector(doneSearching_Clicked:)];
}
- (NSIndexPath *)tableView :(UITableView *)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(letUserSelectRow)
        return indexPath;
    else
        return nil;
}

//RootViewController.m
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
    
    //Remove all objects first.
    [copyListOfItems removeAllObjects];
    
    if([searchText length] > 0) {
        
        searching = YES;
        letUserSelectRow = YES;
        self.tableView.scrollEnabled = YES;
        [self searchTableView];
    }
    else {
        searching = NO;
        letUserSelectRow = NO;
        self.tableView.scrollEnabled = NO;
    }
    
    [self DoesContainOrders];
   // [self.tableView reloadData];
}
//We first create a temporary search array, which we will fill it all the objects from the original data source. We loop through the dictionary objects, and add all the array objects to “searchArray”. We then loop through all the items in “searchArray” and compare it with the search text. We add the string object to the “copyListOfItems” if we find the search text in one of the countries.
- (void) searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    copyListOfItems = [[NSMutableArray alloc] init];
    [self searchTableView];
}
//
- (IBAction)RefreshHoistSrlNumbers:(id)sender {
    [self GetHoistNumbers];
    [self DoesContainOrders];
    [self.tableView reloadData];
}

- (void) searchTableView {
    
    NSString *searchText = searchBar.text;

    [searchArray removeAllObjects];
    
    [searchArray addObjectsFromArray:myHoistSrlNumbers];
    for (NSString *sTemp in searchArray)
    {
        NSRange titleResultsRange = [sTemp rangeOfString:searchText options:NSCaseInsensitiveSearch];
        
        if (titleResultsRange.length > 0)
        {
            [copyListOfItems addObject:sTemp];
            //[self tableView:self.tableView cellForRowAtIndexPath:nil];
        }
    }
    [self.tableView reloadData];
    //searchArray = nil;
}
//when the donesearching button is clicked We hide the keyboard, let the user select a row, set “searching” to false and hide the right bar button item.
- (void) doneSearching_Clicked:(id)sender {
    
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    
    letUserSelectRow = YES;
    searching = NO;
    [copyListOfItems removeAllObjects];
    [searchArray removeAllObjects];
    self.navigationItem.rightBarButtonItem = nil;
    self.tableView.scrollEnabled = YES;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(RefreshHoistSrlNumbers:)];
    self.navigationItem.rightBarButtonItem = addButton;
    [self DoesContainOrders];
    [self.tableView reloadData];
}

@end
