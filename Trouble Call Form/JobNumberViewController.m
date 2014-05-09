//
//  JobNumberViewController.m
//  Trouble Call Form
//
//  Created by Developer on 5/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JobNumberViewController.h"
#import "sqlite3.h"
#import "ArrayStorage.h"
#import "DateDisplayViewController.h"

@interface JobNumberViewController ()
{
    sqlite3 *contactDB;
    NSString *databasePath;
    NSMutableArray *myJobNumbers;
    //DateDisplayViewController *DVController;
    MasterViewController *MVController;
}
@end

@implementation JobNumberViewController
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize jobNumberArray;
@synthesize hoistSrl;
@synthesize jobNumber;
@synthesize detailViewController;
@synthesize DVController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [self.splitViewController setPresentsWithGesture:YES];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    documentsDir = [paths objectAtIndex:0];
    //full file location string
    databasePath = [[NSString alloc] initWithString:[documentsDir stringByAppendingPathComponent:@"contacts.db"]];
    self.detailViewController = (DetailViewController *) [[self.splitViewController.viewControllers lastObject] topViewController];
    DVController = [self.storyboard instantiateViewControllerWithIdentifier:@"DVController"];
    [DVController LoadMasterViewController:MVController];
    
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) LoadMasterViewController: (MasterViewController *) input
{
    MVController = input;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) DeleteJob:(NSString *) myJobNumber
{
    sqlite3_stmt *statement;
    //get the path where to hold the database
        
    const char *dbPath = [databasePath UTF8String];
        
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *removeSQL = [NSString stringWithFormat:@"DELETE FROM ALLTROUBLEORDERS WHERE HOISTSRL=\"%@\" AND JOBNUMBER=\"%@\"", hoistSrl, myJobNumber];
        const char *remove_stmt = [removeSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, remove_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            //sqlite3_bind_text(statement, 1, [txtJobNumber.text UTF8String], -1, NULL);
        }
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Job Number Removed Succesfully from Jobs Table");
        }   
        else 
        {
            NSLog(@"Error removing Job Number from Jobs Table");
        }
    }
    [MVController.tableView reloadData];
    [self UpdateJobTable:myJobNumber];
    jobNumber = nil;
}

- (void) UpdateJobTable:(NSString *) myJobNumber
{
    sqlite3_stmt *statement;
    
    const char *dbPath = [databasePath UTF8String];
    
    //updates the table and tells it that there is going to be a deletion of these fields
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO UPDATEJOBORDERS (HOISTSRL, JOBNUMBER, DATE, OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH, ACTION) VALUES(\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\");",
                           hoistSrl,
                           myJobNumber,
                           @"",
                           @"" ,
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"DELETE JOBNUMBER"];
    //NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ALLORDERS (JOBNUMBER, PART, DEFICIENT, DEFICIENTPART, NOTES, PICKERSELECTION) VALUES (?,?,?,?,?,?)"];
    
    
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
            //UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Customer Added" message:@"The Customer Contact Information was Saved" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            //[view show];
        }
    }

}

- (void) GetJobNumbers
{
    jobNumberArray = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    //get the path where to hold the database
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    documentsDir = [paths objectAtIndex:0];
    //full file location string
    databasePath = [[NSString alloc] initWithString:[documentsDir stringByAppendingPathComponent:@"contacts.db"]];
    //databasePath = @"/Users/Developer/Documents/databases/contacts.db";
    const char *dbPath = [databasePath UTF8String];
    bool orderExist = NO;
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT JOBNUMBER FROM ALLTROUBLEORDERS WHERE HOISTSRL = \"%@\" AND STATUS IS NULL", hoistSrl];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                const char *chJobNumber = (char*) sqlite3_column_text(statement, 0);
                
                NSString *myJobNumber = [NSString stringWithUTF8String:chJobNumber];
                //this is the array that stores all the dates in the Date Table View
                [jobNumberArray addObject:myJobNumber]; 
                
                NSLog(@"Retrieved condition from the table");
                //release memory
                chJobNumber = nil;
                myJobNumber = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
    }/*
    if (![DVController.dateArray count]==0)
    {
        //change the textbox on the CIV Controller so that the user knows which job number he is currently viewing
        MVController.detailViewController.CIVController.txtJobNumber.text = myJobNumber;
        //change the jobNumber variable on the CDV Controller, so that this variable will be filled when the user clicks on submit, if this line were not here
        //then when the user clicked on submit, the job number would display as null
        // self.detailViewController.CDVController.jobNumber = myJobNumber;
        [DVController.tableView reloadData];
        [self.navigationController pushViewController:DVController animated:YES];
        DVController.jobNumber = myJobNumber;
        DVController.hoistSrl = hoistSrl;
    }
*/
statement = nil;
paths = nil;
documentsDir = nil;
dbPath = nil;
}

- (void) GetDates : (NSString *) myJobNumber
{
    DVController.dateArray = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    //get the path where to hold the database
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    documentsDir = [paths objectAtIndex:0];
    //full file location string
    databasePath = [[NSString alloc] initWithString:[documentsDir stringByAppendingPathComponent:@"contacts.db"]];
    //databasePath = @"/Users/Developer/Documents/databases/contacts.db";
    const char *dbPath = [databasePath UTF8String];
    bool orderExist = NO;
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT DISTINCT DATE FROM ALLTROUBLEORDERS WHERE JOBNUMBER = \"%@\" AND HOISTSRL = \"%@\"", myJobNumber, hoistSrl];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                const char *chDate = (char*) sqlite3_column_text(statement, 0);
                
                NSString *date = [NSString stringWithUTF8String:chDate];
                //this is the array that stores all the dates in the Date Table View
                [DVController.dateArray addObject:date]; 
                
                NSLog(@"Retrieved condition from the table");
                //release memory
                chDate = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
    }
    if (![DVController.dateArray count]==0)
    {
        //change the textbox on the CIV Controller so that the user knows which job number he is currently viewing
        MVController.detailViewController.CIVController.txtJobNumber.text = myJobNumber;
        //change the jobNumber variable on the CDV Controller, so that this variable will be filled when the user clicks on submit, if this line were not here
        //then when the user clicked on submit, the job number would display as null
       // self.detailViewController.CDVController.jobNumber = myJobNumber;
        [DVController.tableView reloadData];
        [self.navigationController pushViewController:DVController animated:YES];
        DVController.jobNumber = myJobNumber;
        DVController.hoistSrl = hoistSrl;
    }
    statement =nil;
    paths = nil;
    documentsDir = nil;
    dbPath= nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  //  return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [jobNumberArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleTableIdentifier];
    }
    
    NSInteger row = [indexPath row];
    cell.textLabel.text = [jobNumberArray objectAtIndex:row];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        
        // Delete the row from the data source
        [self DeleteJob:selectedCell.textLabel.text];
        [self GetJobNumbers];
        [tableView reloadData];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *cellText = selectedCell.textLabel.text;
    
    [self GetDates:cellText];
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

@end
