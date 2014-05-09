//
//  DateDisplayViewController.m
//  Trouble Call Form
//
//  Created by Developer on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DateDisplayViewController.h"
#import "DetailViewController.h"
#import "sqlite3.h"
#import "MasterViewController.h"

@interface DateDisplayViewController ()
{
    //DetailViewController *CDVController;
    sqlite3 *contactDB;
    NSString *databasePath;
    MasterViewController *MVController;
}
@end

@implementation DateDisplayViewController
@synthesize detailViewController;
@synthesize dateArray;
@synthesize jobNumber;
@synthesize hoistSrl;

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
    //CDVController = [self.storyboard instantiateViewControllerWithIdentifier:@"CDVController"];
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void) LoadMasterViewController:(MasterViewController *) input
{
    self.detailViewController = (DetailViewController *)[[input.splitViewController.viewControllers lastObject] topViewController];
    MVController = input;
}


- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

#pragma mark - Get Trouble Call Info
- (void) GetTroubleCalls:(id) date
{
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
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH FROM ALLTROUBLEORDERS WHERE HOISTSRL=\"%@\" AND JOBNUMBER=\"%@\" AND DATE=\"%@\";", hoistSrl, jobNumber, date];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                //grabs all information from the table as characters
                orderExist = YES;
                const char *chOpCheck = (char*) sqlite3_column_text(statement, 0);              //row 1
                const char *chWorkPerformed = (char*) sqlite3_column_text(statement, 1);        //row 2
                const char *chMaterialUsed = (char*) sqlite3_column_text(statement, 2);         //row 3
                const char *chMaterialOrdered = (char*) sqlite3_column_text(statement, 3);      //row 4
                const char *chMfgMdl = (char*) sqlite3_column_text(statement, 4);               //row 5
                const char *chChainLength = (char*) sqlite3_column_text(statement, 5);          //row 6
                const char *chRopeLength = (char*) sqlite3_column_text(statement, 6);           //row 7
                
                NSString *opCheck = [NSString stringWithUTF8String:chOpCheck];
                NSString *workPerformed = [NSString stringWithUTF8String:chWorkPerformed];
                NSString *materialUsed = [NSString stringWithUTF8String:chMaterialUsed];
                NSString *materialOrdered = [NSString stringWithUTF8String:chMaterialOrdered];
                NSString *mfgMdl = [NSString stringWithUTF8String:chMfgMdl];
                NSString *chainLength = [NSString stringWithUTF8String:chChainLength];
                NSString *ropeLength = [NSString stringWithUTF8String:chRopeLength];
                //sets the CDVController variables so that the trouble call form can be filled appropriately from the table
                
                if (![MVController.detailViewController.CIVController.CDVController isViewLoaded])
                {
                    MVController.detailViewController.CIVController.CDVController = [self.storyboard instantiateViewControllerWithIdentifier:@"CDVController"];
                }
                //if there is no CIV Controller which is the contronller that should always be before the CDV Controller in the stack, then push on the CIV Controller first, then push on
                //the CDV Controller
                if (![MVController.detailViewController.navigationController.viewControllers containsObject:MVController.detailViewController.CIVController])
                {
                    [MVController.detailViewController.navigationController pushViewController:MVController.detailViewController.CIVController animated:NO];
                    [MVController.detailViewController.navigationController pushViewController:MVController.detailViewController.CIVController.CDVController animated:YES];
                   // [MVController.detailViewController.CIVController.CDVController LoadMasterViewController:MVController];
                    
                }
                else if (![MVController.detailViewController.navigationController.viewControllers containsObject:MVController.detailViewController.CIVController.CDVController])
                {
                    //push on the CDV Controller
                    [MVController.detailViewController.navigationController pushViewController:MVController.detailViewController.CIVController.CDVController animated:YES];
                  //  [MVController.detailViewController.CIVController.CDVController LoadMasterViewController:MVController];
                    
                }
                else {
                    [MVController.detailViewController.navigationController popToViewController:MVController.detailViewController.CIVController.CDVController animated:YES];
                }
                [MVController.detailViewController.CIVController.CDVController FillCallForm:opCheck
                                                                     :workPerformed
                                                                     :materialUsed
                                                                     :materialOrdered
                                                                     :mfgMdl
                                                                     :chainLength
                                                                     :ropeLength];
                //fill the correct variables so that the information from the crane is stored on the CIV Controller object
                [MVController.detailViewController.CIVController FillLocalVariables];
                [MVController.detailViewController.CIVController.CDVController SetOpCheckSelection:opCheck];
                MVController.detailViewController.CIVController.txtDate.text = date;
                MVController.detailViewController.CIVController.CDVController.date = date;
                NSLog(@"Retrieved condition from the table");
                //release memory
                chOpCheck = nil;
                chWorkPerformed = nil;
                chMaterialUsed = nil;
                chMaterialOrdered = nil;
                chMfgMdl = nil;
                chChainLength = nil;
                chRopeLength = nil;
                
                opCheck = nil;
                workPerformed = nil;
                materialUsed = nil;
                materialOrdered = nil;
                mfgMdl = nil;
                chainLength = nil;
                ropeLength = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        self.detailViewController.CIVController.CDVController.errorExist = [self.detailViewController.CIVController.CDVController isError];
    }
}

- (void) GetDates
{
    dateArray = [[NSMutableArray alloc] init];
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
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT UNIQUE DATE FROM ALLTROUBLEORDERS WHERE JOBNUMBER = \"%@\" AND HOISTSRL = \"%@\" AND STATUS IS NULL", jobNumber, hoistSrl];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                const char *chDate = (char*) sqlite3_column_text(statement, 0);
                
                NSString *date = [NSString stringWithUTF8String:chDate];
                //this is the array that stores all the dates in the Date Table View
                [dateArray addObject:date]; 
                
                NSLog(@"Retrieved condition from the table");
                //release memory
                chDate = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        selectSQL = nil;
        select_stmt = nil;
    }
    paths = nil;
    documentsDir = nil;
    dbPath = nil;
    
}

- (void) DeleteDate:(NSString *) myDate
{
    sqlite3_stmt *statement;
    //get the path where to hold the database
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    documentsDir = [paths objectAtIndex:0];
    //full file location string
    databasePath = [[NSString alloc] initWithString:[documentsDir stringByAppendingPathComponent:@"contacts.db"]];
    const char *dbPath = [databasePath UTF8String];

    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *removeSQL = [NSString stringWithFormat:@"DELETE FROM ALLTROUBLEORDERS WHERE HOISTSRL=\"%@\" AND JOBNUMBER=\"%@\" AND DATE=\"%@\";", hoistSrl, jobNumber, myDate];
        const char *remove_stmt = [removeSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, remove_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            //sqlite3_bind_text(statement, 1, [txtJobNumber.text UTF8String], -1, NULL);
        }
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Date Removed Succesfully from Jobs table");
        }   
        else 
        {
            NSLog(@"Error removing date from AllTroubleOrders Table");
        }
    }
    [MVController.tableView reloadData];
    statement = nil;
    dbPath = nil;
    paths = nil;
    documentsDir = nil;
    databasePath = nil;
}

- (void) UpdateTables:(NSString *) myDate
{
    sqlite3_stmt *statement;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    documentsDir = [paths objectAtIndex:0];
    //full file location string
    databasePath = [[NSString alloc] initWithString:[documentsDir stringByAppendingPathComponent:@"contacts.db"]];
    const char *dbPath = [databasePath UTF8String];
    
    //updates the table and tells it that there is going to be a deletion of these fields
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO UPDATEJOBORDERS (HOISTSRL, JOBNUMBER, DATE, OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH, ACTION) VALUES(\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\");",
                           hoistSrl,
                           jobNumber,
                           myDate,
                           @"" ,
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"",
                           @"DELETE DATE"];
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
        insert_stmt = nil;
    }
    statement = nil;
    insertSQL = nil;
    paths = nil;
    documentsDir = nil;
    databasePath = nil;
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
    return [dateArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleTableIdentifier];
    }
    
    NSInteger row = [indexPath row];
    cell.textLabel.text = [dateArray objectAtIndex:row];
    
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
        // Delete the row from the data source
        //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        [self DeleteDate:selectedCell.textLabel.text];
        [self UpdateTables:selectedCell.textLabel.text];
        [self GetDates];
        [tableView reloadData];
        selectedCell = nil;
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
    
    if (![self.detailViewController.CDVController isViewLoaded])
    {
        self.detailViewController.CDVController = [self.storyboard instantiateViewControllerWithIdentifier:@"CDVController"];
        [self.detailViewController.CDVController LoadMasterViewController:MVController];
    }
    [self GetTroubleCalls:cellText];
    selectedCell = nil;
    cellText = nil;
}

@end
