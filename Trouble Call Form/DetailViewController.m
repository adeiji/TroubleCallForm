 //
//  DetailViewController.m
//  Trouble Call Form
//
//  Created by Developer on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "sqlite3.h"
#import "MasterViewController.h"
#import "DropboxSDK/DropboxSDK.h"
#import "JobNumberViewController.h"
#import "DateDisplayViewController.h"
#import "GradientView.h"
#import <malloc/malloc.h>

@interface DetailViewController () {
    sqlite3 *contactDB;
    NSString *databasePath;
    DetailViewController *CDVController;
    UIDatePicker *myDatePicker;
    DetailViewController *CIVController;
    UIButton *btnSelectDate;
    MasterViewController *MVController;
    DBRestClient *restClient;
    NSString *owner;
    //UIDocumentInteractionController *controller;
    int numFilesUploaded, numFilesFailed;
    NSString *previousFullTable;
    NSString *jobTableCVSString;
    NSString *orderTableCVSString;
    NSString *fullCarlPath, *fullChuckPath, *fullJessiePath, *fullCarlOrderPath, *fullChuckOrderPath, *fullJessieOrderPath;
    int currentOrientation;
    BOOL finalSubmitPressed;
    NSString *hoursSpent;
    UIAlertView *waitAlert;
    BOOL syncComplete;
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@property (strong, nonatomic) UITextField  *activeField;
@property (strong, nonatomic) NSArray *opCheckArray;
@end

@implementation DetailViewController
@synthesize jobNumber;
@synthesize date;
@synthesize hoistSrl;
@synthesize customerName;
@synthesize email;
@synthesize equipNum;
@synthesize craneMfg;
@synthesize hoistMfg;
@synthesize hoistMdl;
@synthesize craneDescription;
@synthesize craneSrl;
@synthesize cap;
@synthesize techName;
@synthesize customerContact;
@synthesize customerAddress;
@synthesize errorExist;
@synthesize ropeLength;
@synthesize chainLength;
@synthesize workPerformed;
@synthesize materialUsed;
@synthesize materialOrdered;
@synthesize mfgMdl;
@synthesize opCheckSelection;
/*
@synthesize opCheckSelection;
@synthesize materialOrdered;
@synthesize materialUsed;
@synthesize workPerformed;
@synthesize mfgMdl;
@synthesize ropeLength;
@synthesize chainLength;
*/
@synthesize detailItem = _detailItem;
@synthesize detailDescriptionLabel = _detailDescriptionLabel;
@synthesize ScrollView = _ScrollView;
@synthesize DetailsScrollView = _DetailsScrollView;
@synthesize OpCheckPicker = _OpCheckPicker;
@synthesize txtHoistSrl = _txtHoistSrl;
@synthesize txtTechName = _txtTechName;
@synthesize txtCustomerName = _txtCustomerName;
@synthesize txtCustomerContact = _txtCustomerContact;
@synthesize txtJobNumber = _txtJobNumber;
@synthesize txtDate = _txtDate;
@synthesize txtCustomerAddress = _txtCustomerAddress;
@synthesize txtEmail = _txtEmail;
@synthesize txtEquipNum = _txtEquipNum;
@synthesize txtCraneMfg = _txtCraneMfg;
@synthesize txtHoistMfg = _txtHoistMfg;
@synthesize txtHoistMdl = _txtHoistMdl;
@synthesize txtCraneDescription = _txtCraneDescription;
@synthesize txtCraneSrl = _txtCraneSrl;
@synthesize txtCap = _txtCap;
@synthesize txtWorkPerformed = _txtWorkPerformed;
@synthesize txtMaterialUsed = _txtMaterialUsed;
@synthesize txtMaterialOrder = _txtMaterialOrder;
@synthesize txtMfgMdl = _txtMfgMdl;
@synthesize txtChainLength = _txtChainLength;
@synthesize txtRopeLength = _txtRopeLength;
@synthesize lblCraneDescription = _lblCraneDesc;
@synthesize GView = _GView;
@synthesize masterPopoverController = _masterPopoverController;
@synthesize activeField;
@synthesize opCheckArray;
@synthesize CIVController;
@synthesize CDVController;

#pragma mark - Text Field Methods
//When you begin editing any text field this method is called in order to tell the compiler which text field is currently in focus
//so that it is known where the screen needs to scroll to, to show the text box when it is being edited

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}
//memmory management
- (void) textFieldDidEndEditing:(UITextField *)textField {
    if (([activeField isEqual:_txtRopeLength]  && ![activeField.text isEqual:@""]) || ([activeField isEqual:_txtChainLength] && ![activeField isEqual:@""]))
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check Field!" message:@"Are you accounting for additional ROPE/CHAIN on DRUM and on UPPER SHIV NEST and PARTS OF LINE?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        
        [alert show];
        alert = nil;
    }
    activeField = nil;
}

- (void)SelectDatePressed:(id)sender {
    //Create a new date and formatter so that date will be in the MM/DD/YYYY format when displayed, and this method grabs the date from the datePicker and displays it 
    //in the textbox
    NSDate *myDate = [myDatePicker date];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MM/dd/yyyy"];
    NSString *dateString = [format stringFromDate:myDate];
    NSLog (@"date: %@", dateString);
    _txtDate.text = dateString;
    [myDatePicker removeFromSuperview];
    dateString = nil;
    myDate = nil;
    format = nil;
    btnSelectDate.hidden = YES;
    //center the scroll view
}

- (IBAction)TxtDateTouchUp:(id)sender {
    btnSelectDate.hidden = NO;
}

- (IBAction)TroubleDetailsButtonPressed:(id)sender {
    
    if (![CDVController isViewLoaded])
    {
        CDVController = [self.storyboard instantiateViewControllerWithIdentifier:@"CDVController"];
    }
    
    [self FillLocalVariables];
    //makes sure that if there is an error on page, you cannot proceed on the other for example, if you have not entered all the fields on the Customer Info page and then you try
    //and submit the order on the Trouble Order Page then it will say that there are still errors on nthe Customer Info Page
    CDVController.errorExist = [self isError];
    
    [self.navigationController pushViewController:CDVController animated:YES];
    //[CDVController LoadMasterViewController:MVController];
}
- (void) FillLocalVariables
{
    //The jobNumber Hoistsrl and Date are all updated on the CDVController object because these three variables are not updated when the user clicks on the job from the
    //table view because this information will most likely be changed by the user
    CDVController.jobNumber = _txtJobNumber.text;
    CDVController.hoistSrl = _txtHoistSrl.text;
    CDVController.date = _txtDate.text;
    CDVController.customerName = _txtCustomerName.text;
    CDVController.email = _txtEmail.text;
    CDVController.equipNum = _txtEquipNum.text;
    CDVController.craneMfg = _txtCraneMfg.text;
    CDVController.hoistMfg = _txtHoistMfg.text;
    CDVController.hoistMdl = _txtHoistMdl.text;
    CDVController.craneDescription = _txtCraneDescription.text;
    CDVController.craneSrl = _txtCraneSrl.text;
    CDVController.cap = _txtCap.text;
    CDVController.techName = _txtTechName.text;
    CDVController.customerContact = _txtCustomerContact.text;
    CDVController.customerAddress = _txtCustomerAddress.text;
}


- (IBAction)NewCustomerButtonPressed:(id)sender {
    [self EmptyTextFields];
}

#pragma mark Update Tables on iPad
- (void) UpdateTablesOniPad
{
    
}

#pragma mark Update Functionality

- (IBAction)UpdateButtonPressed:(id)sender {
    //create an array and store result of our search for the documents directory in it
    waitAlert = [[UIAlertView alloc] initWithTitle:@"Updating Information\nPlease Wait..." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // Adjust the indicator so it is up a few pixels from the bottom of the alert
    indicator.center = CGPointMake(waitAlert.bounds.size.width + 140, waitAlert.bounds.size.height + 90);
    [indicator startAnimating];
    [waitAlert addSubview:indicator];
    
    [waitAlert show];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    //create NSString object, that holds our exact path to the documents directory
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"Document Dir: %@",documentsDirectory);
    NSString *results, *results2, *results3;
    NSString *fullPath, *fullOrdersPath, *completeOrdersPath;

    //if this iPad is owned by carl then we read the information from the updatejobtable and updateordertable of the other iPad
    //then grabs the updateordertable of this iPad
    if ([owner isEqualToString:@"Carl"])
    {
        //read in the information from chuck's ipad
        fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"ChuckUpdateJobTable.csv"]]; //add our file to the path
        [[self restClient] loadFile:@"/ChuckUpdateJobTable.csv" intoPath:fullPath];
        fullPath = nil;
        //get the orders from the tables
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"ChuckUpdateOrderTable.csv"]];
        [[self restClient] loadFile:@"/ChuckUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results = [self readOrdersCSVFile:fullOrdersPath];

        //read in the information from jessie's ipad
        fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"JessieUpdateJobTable.csv"]]; //add our file to the path
        //[self UploadCSVFileToDropbox:fullPath :@"JessieUpdateJobTable.csv"];
        [[self restClient] loadFile:@"/JessieUpdateJobTable.csv" intoPath:fullPath];
        fullPath = nil;
        //get the orders from the tables
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"JessieUpdateOrderTable.csv"]];
        //[self UploadCSVFileToDropbox:fullPath :@"JessieUpdateOrderTable.csv"];
        [[self restClient] loadFile:@"/JessieUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results = [self readOrdersCSVFile:fullOrdersPath];
        
        //read the iPad's own csv file which stores the ChuckUpdateOrderTable
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"CarlUpdateOrderTable.csv"]];
        [[self restClient] loadFile:@"/CarlUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results2 = [self readOrdersCSVFile:fullOrdersPath];
    }
    else if ([owner isEqualToString:@"Chuck"])
    {
        //read in the information from chuck's ipad
        fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"CarlUpdateJobTable.csv"]]; //add our file to the path
        [[self restClient] loadFile:@"/CarlUpdateJobTable.csv" intoPath:fullPath];
        //get the jobs from the table
        //[self readJobsCSVFile:fullPath];
        
        //get the orders from the tables
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"CarlUpdateOrderTable.csv"]];
        [[self restClient] loadFile:@"/CarlUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results = [self readOrdersCSVFile:fullOrdersPath];
        
        //read in the information from jessie's ipad
        fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"JessieUpdateJobTable.csv"]]; //add our file to the path
        [[self restClient] loadFile:@"/JessieUpdateJobTable.csv" intoPath:fullPath];
        fullPath = nil;
        //get the orders from the tables
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"JessieUpdateOrderTable.csv"]];
        [[self restClient] loadFile:@"/JessieUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results = [self readOrdersCSVFile:fullOrdersPath];
        
        //read the iPad's own csv file which stores the ChuckUpdateOrderTable
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"ChuckUpdateOrderTable.csv"]];
        [[self restClient] loadFile:@"/ChuckUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results2 = [self readOrdersCSVFile:fullOrdersPath];
    }
    else if ([owner isEqualToString:@"Jessie"])
    {
        //read in the information from chuck's ipad
        fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"CarlUpdateJobTable.csv"]]; //add our file to the path
        [[self restClient] loadFile:@"/CarlUpdateJobTable.csv" intoPath:fullPath];
        //get the jobs from the table
        //[self readJobsCSVFile:fullPath];
        
        //get the orders from the tables
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"CarlUpdateOrderTable.csv"]];
        [[self restClient] loadFile:@"/CarlUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results = [self readOrdersCSVFile:fullOrdersPath];
        
        //read in the information from jessie's ipad
        fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"ChuckUpdateJobTable.csv"]]; //add our file to the path
        [[self restClient] loadFile:@"/ChuckUpdateJobTable.csv" intoPath:fullPath];
        fullPath = nil;
        //get the orders from the tables
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"ChuckUpdateOrderTable.csv"]];
        [[self restClient] loadFile:@"/ChuckUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results = [self readOrdersCSVFile:fullOrdersPath];
        
        //read the iPad's own csv file which stores the JessieUpdateOrderTable
        fullOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"JessieUpdateOrderTable.csv"]];
        [[self restClient] loadFile:@"/JessieUpdateOrderTable.csv" intoPath:fullOrdersPath];
        results3 = [self readOrdersCSVFile:fullOrdersPath];
    }
    //read the changes off of Andrews computer
    //if ([results isEqualToString:@"Sync Complete"] && [results2 isEqualToString:@"Sync Complete"])
    //{
        completeOrdersPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"CompleteTable.csv"]]; //add our file to the path
        [[self restClient] loadFile:@"/CompleteTable.csv" intoPath:completeOrdersPath];
    //}
    
    //if (results&&results2&&results3)
   // {
     //   syncComplete = true;
   // }
    //else {
     //   syncComplete = false;
   // }
    //we send the tables from this iPad to the server
    [self SendTablesToServer];
    fullPath  = nil;
    results = nil;
    results2 = nil;
    fullOrdersPath = nil;
    completeOrdersPath = nil;
    paths = nil;
    numFilesUploaded = 0;
    numFilesFailed = 0;
}

//we copy all the information from the UpdateJobOrders table to the AllTroubleOrders table, this is so that we can make sure that whatever changes have been made since the last sync stay on
//the iPad and aren't overrun by the information from Andrew's iPad
- (void) CopyUpdateTableToAllOrdersTable
{
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *selectSQL = [NSString stringWithFormat:@"INSERT INTO ALLTROUBLEORDERS (HOISTSRL, JOBNUMBER, DATE, OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH) SELECT HOISTSRL, JOBNUMBER, DATE, OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH FROM UPDATEJOBORDERS WHERE ACTION=\"ADD\""];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            if (sqlite3_step(statement) != SQLITE_DONE)
            {
                NSAssert(0, @"Error copying UpdateJobOrders data to AllTroubleOrders");
            }
            else {
                NSLog(@"Copy of tables succesful");
            }
            sqlite3_finalize(statement);
            sqlite3_close(contactDB);
        }
        else {
            NSLog(@"Failed to copy UpdateJobOrders data to AllTroubleOrders");
        }
        selectSQL = nil;
        select_stmt = nil;
    }
    
    sqlite3_finalize(statement);
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT HOISTSRL FROM UPDATEJOBSORDERS WHERE ACTION = \"DELETE\""];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            const char *order = (char*) sqlite3_column_text(statement, 0); 
            NSString *myOrder = [NSString stringWithUTF8String:order];
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *selectSQL = [NSString stringWithFormat:@"DELETE FROM ALLTROUBLEORDERS WHERE HOISTSRL = \"%@\"", myOrder];
                const char *select_stmt = [selectSQL UTF8String];
                if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
                {

                }
            }
            sqlite3_finalize(statement);
            sqlite3_close(contactDB);
        }
        else {
            NSLog(@"Failed to copy UpdateJobOrders data to AllTroubleOrders");
        }
        selectSQL = nil;
        select_stmt = nil;
    }
    
    sqlite3_finalize(statement);
    statement = nil;
    dbPath = nil;
}

- (void) readFullTable:(NSString *) fileName
{
    NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
    NSCharacterSet *myCharacterSet = [NSCharacterSet newlineCharacterSet];
    //gets all the lines of the csv file
    NSArray *pointStrings = [fileContents componentsSeparatedByCharactersInSet:myCharacterSet];
    NSString *myHoistSrl, *myJobNumber, *myDate, *myWorkPerformed, *myOpCheck, *myMaterialUsed, *myMaterialOrder, *myMfgMdl, *myChainLength, *myRopeLength;
    //goes through each line of the csv file
    //we first though need to make sure that the new csv file has really been read, and it's not the old one
    if (![fileContents isEqualToString:previousFullTable])
    {
        [self DeleteAllJobs];
        
        //go to pointStrings.count - 1 because the last line will always be empty
        for (int index = 0; index < pointStrings.count - 1; index++)
        {
            NSString *currentPointString = [pointStrings objectAtIndex:index];
            NSArray *arr = [currentPointString componentsSeparatedByString:@"###"];
            //if the csv file is not empty
            if (![currentPointString isEqualToString:@""])
            {
                myHoistSrl = [[NSString alloc] initWithString:[[arr objectAtIndex:0] description ]];
                myJobNumber = [[NSString alloc] initWithString:[[arr objectAtIndex:1] description]];
                myDate = [[NSString alloc] initWithString:[[arr objectAtIndex:2] description]];
                myWorkPerformed = [[NSString alloc] initWithString:[[arr objectAtIndex:3] description]];
                myOpCheck = [[NSString alloc] initWithString:[[arr objectAtIndex:4] description]];
                myMaterialUsed = [[NSString alloc] initWithString:[[arr objectAtIndex:5] description]];
                myMaterialOrder = [[NSString alloc] initWithString:[[arr objectAtIndex:6] description]];
                myMfgMdl = [[NSString alloc] initWithString:[[arr objectAtIndex:7] description]];
                myChainLength = [[NSString alloc] initWithString:[[arr objectAtIndex:8] description]];
                myRopeLength = [[NSString alloc] initWithString:[[arr objectAtIndex:9] description]];
                
                //[self DeleteJob:myHoistSrl :myJobNumber :myDate];
                [self InsertJobInfoIntoTable:@"ALLTROUBLEORDERS" 
                                                :myHoistSrl 
                                                :myJobNumber 
                                                :myDate 
                                                :myOpCheck 
                                                :myWorkPerformed
                                                :myMaterialUsed
                                                :myMaterialOrder
                                                :myMfgMdl
                                                :myChainLength
                                                :myRopeLength];
                
                myHoistSrl = nil;
                myJobNumber = nil;
                myDate = nil;
                myWorkPerformed = nil;
                myOpCheck = nil;
                myMaterialUsed = nil;
                myMaterialOrder = nil;
                myMfgMdl = nil;
                myChainLength = nil;
                myRopeLength = nil;
            }
        }
        [self CopyUpdateTableToAllOrdersTable];
        previousFullTable = fileContents;
    }
}
//this method will drop the update tables so that they can be emptied and then every time the person adds a crane or a job it will be added to the update tables
- (void) DropOrdersTable
{
    NSString *querySql = [NSString stringWithFormat:@"DROP TABLE UPDATEJOBORDERS"];
    const char *sql_stmt = [querySql UTF8String];
    char *errMess;
    const char *dbPath = [databasePath UTF8String];
    
    //open the database
    if (sqlite3_open(dbPath, &contactDB) == SQLITE_OK)
    {
        //creates the table using the querySql NSString
        if (sqlite3_exec(contactDB, sql_stmt, NULL, NULL, &errMess) == SQLITE_OK) 
        {
            NSLog(@"ALL UPDATE JOB ORDERS TABLE DROPPED");
        }
        sqlite3_close(contactDB);
    }
    
    querySql = nil;
    sql_stmt = nil;
    errMess = nil;
    dbPath = nil;
}
- (void) DropJobsTable
{
    NSString *querySql = [NSString stringWithFormat:@"DROP TABLE UPDATEJOBS"];
    const char *sql_stmt = [querySql UTF8String];
    char *errMess;
    const char *dbPath = [databasePath UTF8String];
    
    //open the database
    if (sqlite3_open(dbPath, &contactDB) == SQLITE_OK)
    {
        //creates the table using the querySql NSString
        if (sqlite3_exec(contactDB, sql_stmt, NULL, NULL, &errMess) == SQLITE_OK) 
        {
            NSLog(@"ALL UPDATE JOBS TABLE DROPPED");
        }
        sqlite3_close(contactDB);
    }
    //release memory
    querySql = nil;
    sql_stmt = nil;
    errMess = nil;
}

#pragma mark Write CSV Files
//this method writes the csv file and thne uploads it to the database
- (void) SendTablesToServer
{
    //create an array and store result of our search for the documents directory in it
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    //create NSString object, that holds our exact path to the documents directory
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"Document Dir: %@",documentsDirectory);
    
    //load the Job CSV file onto the iPad
    if ([owner isEqualToString:@"Carl"])
    {
        //read in the information from chuck's ipad
        fullCarlPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"CarlUpdateJobTable.csv"]]; //add our file to the path
        [[self restClient] loadFile:@"/CarlUpdateJobTable.csv" intoPath:fullCarlPath];
    }
    else if ([owner isEqualToString:@"Chuck"])
    {
        //read in the information from chuck's ipad
        fullChuckPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"ChuckUpdateJobTable.csv"]]; //add our file to the path
        [[self restClient] loadFile:@"/ChuckUpdateJobTable.csv" intoPath:fullChuckPath];
    }
    else {
        //read in the information from Jessie's iPad
        fullJessiePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"JessieUpdateJobTable.csv"]];//add our file to the path
        [[self restClient] loadFile:@"/JessieUpdateJobTable.csv" intoPath:fullJessiePath];
    }
    //get the paths for the Order Tables
    fullCarlOrderPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"CarlUpdateOrderTable.csv"]]; //add our file to the path
    fullChuckOrderPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"ChuckUpdateOrderTable.csv"]]; //add our file to the path
    fullJessieOrderPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"JessieUpdateOrderTable.csv"]];
    
    if ([owner isEqualToString:@"Chuck"])
    {
        //we send the full paths so that we can check to see if there is any items already inside of the file
        jobTableCVSString = [self GetJobsTable:fullChuckPath];   
        orderTableCVSString = [self GetOrdersTable:fullChuckOrderPath];
    }
    else if ([owner isEqualToString:@"Carl"])
    {
        jobTableCVSString = [self GetJobsTable:fullCarlPath];
        orderTableCVSString = [self GetOrdersTable:fullCarlOrderPath];
    }
    else {
        jobTableCVSString = [self GetJobsTable:fullJessiePath];
        orderTableCVSString = [self GetOrdersTable:fullJessieOrderPath];
    }
    
    if ([owner isEqualToString:@"Chuck"])
    {
        //sends the fullChuckPath and fullCarlPath because these are the CSV files that already exist, if they're not empty then add to these files, rather then make new ones
        //because if they're not empty that means that the other iPad has not synced yet
        [self WriteCSVFile:jobTableCVSString:[NSString stringWithFormat:@"%@UpdateJobTable.csv", owner]:fullChuckPath];
    }
    else if ([owner isEqualToString:@"Carl"])
    {
        [self WriteCSVFile:jobTableCVSString:@"CarlUpdateJobTable.csv":fullCarlPath];
    }
    else {
        [self WriteCSVFile:jobTableCVSString :@"JessieUpdateJobTable.csv" :fullJessiePath];
    }
    
    //fullCarlPath = nil;
    //fullCarlOrderPath = nil;
    //fullChuckPath = nil;
    //fullChuckOrderPath = nil;
    //jobTableCVSString = nil;
    //orderTableCVSString = nil;
    paths = nil;
    documentsDirectory = nil;
}
//this method gets the cranes from the updatejobs table and writes the results to a single string
- (NSString *) GetJobsTable:(NSString *) fullPath
{
    //get the contents of it's own file and makes sure that there's nothing in it, if there is, then we add to what is already there, otherwise we start from scratch
    NSString *fileContents = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
    
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];
    bool orderExist = NO;
    NSMutableString *myCSVString = [[NSMutableString alloc] init];
    
    //makes sure that we're not sending any empty file because we're just writing sync complete
    if (![fileContents isEqualToString:@"Sync Complete"] && ![fullPath isEqualToString:@""])
    {
        [myCSVString appendString: fileContents];
    }
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT HOISTSRL, CUSTOMERNAME, CONTACT, JOBNUMBER, DATE, ADDRESS, EMAIL, EQUIPNUM, CRANEMFG, HOISTMFG, HOISTMDL, CRANEDESCRIPTION, CAP, CRANESRL, ACTION FROM UPDATEJOBS"];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                const char *chHoistSrl = (char*) sqlite3_column_text(statement, 0);
                const char *chCustName = (char*) sqlite3_column_text(statement, 1);
                const char *chContact = (char*) sqlite3_column_text(statement, 2);
                const char *chJobNumber = (char*) sqlite3_column_text(statement, 3);
                const char *chDate = (char*) sqlite3_column_text(statement, 4);
                const char *chAddress = (char*) sqlite3_column_text(statement, 5);
                const char *chEmail = (char*) sqlite3_column_text(statement, 6);
                const char *chEquipNum = (char*) sqlite3_column_text(statement, 7);
                const char *chCraneMfg = (char*) sqlite3_column_text(statement, 8);
                const char *chHoistMfg = (char*) sqlite3_column_text(statement, 9);
                const char *chHoistMdl = (char*) sqlite3_column_text(statement, 10);
                const char *chCraneDescription = (char*) sqlite3_column_text(statement, 11);
                const char *chCap = (char*) sqlite3_column_text(statement, 12);
                const char *chCraneSrl = (char*) sqlite3_column_text(statement, 13);
                const char *chAction = (char*) sqlite3_column_text(statement, 14);
                
                NSString *myHoistSrl = [NSString stringWithUTF8String:chHoistSrl];
                NSString *myCustName = [NSString stringWithUTF8String:chCustName];
                NSString *myContact = [NSString stringWithUTF8String:chContact];
                NSString *myJobNumber = [NSString stringWithUTF8String:chJobNumber];
                NSString *myDate = [NSString stringWithUTF8String:chDate];
                NSString *myAddress = [NSString stringWithUTF8String:chAddress];
                NSString *myEmail = [NSString stringWithUTF8String:chEmail];
                NSString *myEquipNum = [NSString stringWithUTF8String:chEquipNum];
                NSString *myCraneMfg = [NSString stringWithUTF8String:chCraneMfg];
                NSString *myHoistMfg = [NSString stringWithUTF8String:chHoistMfg];
                NSString *myHoistMdl = [NSString stringWithUTF8String:chHoistMdl];
                NSString *myCraneDescription = [NSString stringWithUTF8String:chCraneDescription];
                NSString *myCap = [NSString stringWithUTF8String:chCap];
                NSString *myCraneSrl = [NSString stringWithUTF8String:chCraneSrl];
                NSString *myAction = [NSString stringWithUTF8String:chAction];
                //writes the csv file with the seperator being ###
                [myCSVString appendString:[NSString stringWithFormat:@"%@###%@###%@###%@###%@###%@###%@###%@###%@###%@###%@###%@###%@###%@###%@### \n", myHoistSrl, myCustName, myContact, myJobNumber, myDate, myAddress, myEmail, myEquipNum, myCraneMfg, myHoistMfg, myHoistMdl, myCraneDescription, myCap, myCraneSrl, myAction]];
                
                NSLog(@"Retrieved condition from the table");
                //release memory
                chHoistSrl = nil;
                chCustName = nil;
                chContact = nil;
                chAddress = nil;
                chDate = nil;
                chEmail = nil;
                chEquipNum = nil;
                chCraneMfg = nil;
                chHoistMfg = nil;
                chHoistMdl = nil;
                chCraneDescription = nil;
                chCap = nil;
                chCraneSrl = nil;
                chJobNumber = nil;
                chAction = nil;
                chAction = nil;
                
                myHoistSrl = nil;
                myCustName = nil;
                myContact = nil;
                myJobNumber = nil;
                myDate = nil;
                myAddress = nil;
                myEmail = nil;
                myEquipNum = nil;
                myCraneMfg = nil;
                myHoistMfg = nil;
                myHoistMdl = nil;
                myCraneDescription = nil;
                myCap = nil;
                myCraneSrl = nil;
                myAction = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        sqlite3_close(contactDB);
    }
    sqlite3_finalize(statement);
    return myCSVString;
    myCSVString = nil;
}

//this method gets the trouble calls from the updateorders table and writes the results to a single string
- (NSString *) GetOrdersTable:(NSString *) fullPath;
{
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];
    bool orderExist = NO;
    NSMutableString *myCSVString = [[NSMutableString alloc] init];
   
    NSString *fileContents = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
    if (![fileContents isEqualToString:@"Sync Complete"] && ![fullPath isEqualToString:@""])
    {
        [myCSVString appendString: fileContents];
    }
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT HOISTSRL, JOBNUMBER, DATE, OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH, ACTION FROM UPDATEJOBORDERS"];
        const char *select_stmt = [selectSQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                const char *chHoistSrl = (char*) sqlite3_column_text(statement, 0);
                const char *chJobNumber = (char*) sqlite3_column_text(statement, 1);
                const char *chDate = (char*) sqlite3_column_text(statement, 2);
                const char *chOpCheck = (char*) sqlite3_column_text(statement, 3);
                const char *chWorkPerformed = (char*) sqlite3_column_text(statement, 4);
                const char *chMaterialUsed = (char*) sqlite3_column_text(statement, 5);
                const char *chMaterialOrder = (char*) sqlite3_column_text(statement, 6);
                const char *chMfgMdl = (char*) sqlite3_column_text(statement, 7);
                const char *chChainLength = (char*) sqlite3_column_text(statement, 8);
                const char *chRopeLength = (char*) sqlite3_column_text(statement, 9);
                const char *chAction = (char*) sqlite3_column_text(statement, 10);
            
                NSString *myHoistSrl = [NSString stringWithUTF8String:chHoistSrl];
                NSString *myJobNumber = [NSString stringWithUTF8String:chJobNumber];
                NSString *myDate = [NSString stringWithUTF8String:chDate];
                NSString *myOpCheck = [NSString stringWithUTF8String:chOpCheck];
                NSString *myWorkPerformed = [NSString stringWithUTF8String:chWorkPerformed];
                NSString *myMaterialused = [NSString stringWithUTF8String:chMaterialUsed];
                NSString *myMaterialOrder = [NSString stringWithUTF8String:chMaterialOrder];
                NSString *myMfgMdl = [NSString stringWithUTF8String:chMfgMdl];
                NSString *myChainLength = [NSString stringWithUTF8String:chChainLength];
                NSString *myRopeLength = [NSString stringWithUTF8String:chRopeLength];
                NSString *myAction = [NSString stringWithUTF8String:chAction];
                //writes the csv file with the seperator being ###
                [myCSVString appendString:[NSString stringWithFormat:@"%@###%@###%@###%@###%@###%@###%@###%@###%@###%@###%@### \n", myHoistSrl, myJobNumber, myDate, myOpCheck, myWorkPerformed, myMaterialused, myMaterialOrder, myMfgMdl, myChainLength, myRopeLength, myAction]];
                
                NSLog(@"Retrieved condition from the table");
                //release memory
                chHoistSrl = nil;
                chJobNumber = nil;
                chDate = nil;
                chOpCheck = nil;
                chWorkPerformed = nil;
                chMaterialUsed = nil;
                chMaterialOrder = nil;
                chMfgMdl = nil;
                chChainLength = nil;
                chRopeLength = nil;
                //chAction = nil;
                myHoistSrl = nil;
                myJobNumber =nil;
                myDate = nil;
                myOpCheck = nil;
                myWorkPerformed = nil;
                myMaterialused = nil;
                myMaterialOrder = nil;
                myMfgMdl = nil;
                myChainLength = nil;
                myRopeLength = nil;
                myAction = nil;
            }
                
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        sqlite3_close(contactDB);
    }
    
    sqlite3_finalize(statement);
    statement = nil;
    dbPath = nil;
    
    return myCSVString;
}
//converts the specified csvString into a file with the name being the given fileName
- (void) WriteCSVFile:(NSString *) csvString: (NSString *) fileName: (NSString *) filePath
{
    NSLog(@"csvString:%@",csvString);
    
    // Create .csv file and save in Documents Directory.
    
    //create instance of NSFileManager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //create an array and store result of our search for the documents directory in it
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    //create NSString object, that holds our exact path to the documents directory
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"Document Dir: %@",documentsDirectory);
    
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileName]]; //add our file to the path
    [fileManager createFileAtPath:fullPath contents:[csvString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil]; //finally save the path (file)
    
    [self UploadCSVFileToDropbox:fullPath:fileName];  
    csvString = nil;
    fullPath = nil;
    fileManager = nil;
    paths = nil;
    documentsDirectory = nil;
    fileName = nil;
}

//when the first submit button is pressed on the Customer Information View Controller
- (IBAction)SubmitButtonPressed:(id)sender {
    if (![CDVController isViewLoaded])
    {
        CDVController = [self.storyboard instantiateViewControllerWithIdentifier:@"CDVController"];
    }
    [self FillLocalVariables];
    //checks to make sure that there are no errors on the customer info page before you are allowed to proceed
    if ([self isError] == @"NO")
    {
        [self InsertCraneIntoTable:@"JOBS":
         _txtHoistSrl.text:
         _txtCustomerName.text:
         _txtCustomerContact.text:
         _txtJobNumber.text:
         _txtDate.text:
         _txtCustomerAddress.text:
         _txtEmail.text:
         _txtEquipNum.text:
         _txtCraneMfg.text:
         _txtHoistMfg.text:
         _txtHoistMdl.text:
         _txtCraneDescription.text:
         _txtCap.text:
         _txtCraneSrl.text];
        
        [self InsertCraneIntoTable:@"UPDATEJOBS":
         _txtHoistSrl.text:
         _txtCustomerName.text:
         _txtCustomerContact.text:
         _txtJobNumber.text:
         _txtDate.text:
         _txtCustomerAddress.text:
         _txtEmail.text:
         _txtEquipNum.text:
         _txtCraneMfg.text:
         _txtHoistMfg.text:
         _txtHoistMdl.text:
         _txtCraneDescription.text:
         _txtCap.text:
         _txtCraneSrl.text];
        
        finalSubmitPressed = YES;
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Customer Added" message:@"The Customer Contact Information was Saved" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [view show];
        finalSubmitPressed = NO;
        [self FillLocalVariables];
 
        [self.navigationController pushViewController:CDVController animated:YES];
        view =nil;
    }
    else if (errorExist==@"Some values are still empty on the Customer Info Page") {
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Error" message:errorExist delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [view show];
        
        view = nil;
    }
    else if (errorExist==@"Can not enter character 'quotations mark' ' \" ' into any customer fields!") {
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Error" message:errorExist delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [view show];
        
        view = nil;
    }
    
}

- (void) UploadCSVFileToDropbox: (NSString *) fullPath: (NSString *) myFileName
{
    //gets the location of the CSV file
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    //create NSString object, that holds our exact path to the documents directory
    //NSString *documentsDirectory = [NSString stringWithFormat:@"%@/", [paths objectAtIndex:0]];
    //NSString *localPath = [[NSBundle mainBundle] pathForResource:@"JonnyCranes" ofType:@"csv"];
    NSString *filename = myFileName;
    NSString *destDir = @"/";
    //makes sure that when the file is uploaded to the Dropbox server the existing file is overwritten, in order to make it so that the file is not overriden the code should look like this
    /*
     [[self restClient] uploadFile:filename toPath:destDir
     parentRev:nil fromPath:fullPath];
     */
    
    [[self restClient] uploadFile:filename toPath:destDir
                         fromPath:fullPath];
    
    //[[self restClient] loadMetadata:@"/"];
    filename = nil;
    destDir = nil;
}
//this method reads the csv file which contains information from the other iPad and then inserts these values onto the table of this iPad
- (NSString *)readJobsCSVFile:(NSString *) fileName
{
    NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
    NSCharacterSet *myCharacterSet = [NSCharacterSet newlineCharacterSet];
    //gets all the lines of the csv file
    NSArray *pointStrings = [fileContents componentsSeparatedByCharactersInSet:myCharacterSet];
    NSString *myHoistSrl, *myCustomerName, *myContact, *myJobNumber, *myDate, *myAddress, *myEmail, *myEquipNum, *myCraneMfg, *myHoistMfg, *myHoistMdl, *myCraneDescription, *myCap, *myCraneSrl, *myAction;
    //goes through each line of the csv file
    if (![fileContents isEqualToString:@"Sync Complete"])
    {
        for (int index = 0; index < pointStrings.count - 1; index++)
        {
            NSString *currentPointString = [pointStrings objectAtIndex:index];
            NSArray *arr = [currentPointString componentsSeparatedByString:@"###"];
            //if the csv file is not empty
            if (![currentPointString isEqualToString:@""])
            {
                myHoistSrl = [[NSString alloc] initWithString:[[arr objectAtIndex:0] description ]];
                myCustomerName = [[NSString alloc] initWithString:[[arr objectAtIndex:1] description]];
                myContact = [[NSString alloc] initWithString:[[arr objectAtIndex:2] description]];
                myJobNumber = [[NSString alloc] initWithString:[[arr objectAtIndex:3] description]];
                myDate = [[NSString alloc] initWithString:[[arr objectAtIndex:4] description]];
                myAddress = [[NSString alloc] initWithString:[[arr objectAtIndex:5] description]];
                myEmail = [[NSString alloc] initWithString:[[arr objectAtIndex:6] description]];
                myEquipNum = [[NSString alloc] initWithString:[[arr objectAtIndex:7] description]];
                myCraneMfg = [[NSString alloc] initWithString:[[arr objectAtIndex:8] description]];
                myHoistMfg = [[NSString alloc] initWithString:[[arr objectAtIndex:9] description]];
                myHoistMdl = [[NSString alloc] initWithString:[[arr objectAtIndex:10] description]];
                myCraneDescription = [[NSString alloc] initWithString:[[arr objectAtIndex:11] description]];
                myCap = [[NSString alloc] initWithString:[[arr objectAtIndex:12] description]];
                myCraneSrl = [[NSString alloc] initWithString:[[arr objectAtIndex:13] description]];
                myAction = [[NSString alloc] initWithString:[[arr objectAtIndex:14] description]];

            //insert this new crane onto this new table
            
                if ([myAction isEqualToString:@"ADD"])
                {
                    [self InsertCraneIntoTable:@"JOBS"
                                            :myHoistSrl
                                            :myCustomerName
                                            :myContact
                                            :myJobNumber
                                            :myDate
                                            :myAddress
                                            :myEmail
                                            :myEquipNum
                                            :myCraneMfg
                                            :myHoistMfg
                                            :myHoistMdl
                                            :myCraneDescription
                                            :myCap
                                            :myCraneSrl];
                }
                else {
                   // [MVController DeleteCrane:myHoistSrl];
                    //[MVController UpdateJobTables:myHoistSrl];
                }
                myHoistSrl = nil;
                myCustomerName = nil;
                myContact = nil;
                myJobNumber = nil;
                myDate = nil;
                myAddress = nil;
                myEmail = nil;
                myEquipNum = nil;
                myCraneMfg = nil;
                myHoistMfg = nil;
                myHoistMdl = nil;
                myCraneDescription = nil;
                myCap = nil;
                myCraneSrl = nil;
                myAction = nil;
            }
        }
        //writes sync complete on the other iPad's CSV file
        if ([owner isEqualToString:@"Carl"])
        {
            [self WriteCSVFile:@"Sync Complete" :@"ChuckUpdateJobTable.csv":@""];
        }
        else {
            [self WriteCSVFile:@"Sync Complete":@"CarlUpdateJobTable.csv" :@""];
        }
    }

    return fileContents;
}

- (NSString *)readOrdersCSVFile:(NSString *) fileName
{
    NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];

    return fileContents;
    fileContents = nil;
}

#pragma mark Dropbox Methods
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    numFilesUploaded++;
    if ([destPath rangeOfString:@"Job"].location != NSNotFound)
    {
        [self DropJobsTable];
        [self CreateUpdateTables];
        if ([owner isEqualToString:@"Chuck"])
            [self WriteCSVFile:orderTableCVSString :[NSString stringWithFormat:@"%@UpdateOrderTable.csv", owner]:fullChuckOrderPath];
        else if ([owner isEqualToString:@"Carl"]) {
            [self WriteCSVFile:orderTableCVSString :[NSString stringWithFormat:@"%@UpdateOrderTable.csv", owner]:fullCarlOrderPath];
        }
        else {
            [self WriteCSVFile:orderTableCVSString :[NSString stringWithFormat:@"%@UpdateOrderTable.csv", owner] :fullJessieOrderPath];
        }
    }
    else if ([destPath rangeOfString:@"Order"].location != NSNotFound)
    {
        [self DropOrdersTable];
        [self CreateUpdateTables];
        if (syncComplete)
        {
            syncComplete = false;
        }
        
    }
     
    if (numFilesUploaded == 2)
    {
        [waitAlert dismissWithClickedButtonIndex:0 animated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Updated Succesfully" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        
        alert = nil;
        waitAlert = nil;
    }
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}
//-----------------------------------------------------------####################-------------------------------------------------------------------------
//-----------------------------------------------------------####################-------------------------------------------------------------------------
//-----------------------------------------------------------####################-------------------------------------------------------------------------
//THIS IS WHERE WE"VE LEFT OFF
- (void) sendRequests {
    //Perform a simple HTTP GET and call me back with the results
    [[RKClient sharedClient] get:@"/foo.xml" delegate:self];
    // Send a POST to a remote resource. The dictionary will be transparently  
    // converted into a URL encoded representation and sent along as the request body 
    NSDictionary* params = [NSDictionary dictionaryWithObject:@"RestKit" forKey:@"Sender"];  
    [[RKClient sharedClient] post:@"/other.json" params:params delegate:self];  
    // DELETE a remote resource from the server  
    [[RKClient sharedClient] delete:@"/missing_resource.txt" delegate:self];  
}
//-----------------------------------------------------------####################-------------------------------------------------------------------------
//-----------------------------------------------------------####################-------------------------------------------------------------------------
//-----------------------------------------------------------####################-------------------------------------------------------------------------

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    numFilesFailed++;
    if (numFilesFailed == 2)
    {
        [waitAlert dismissWithClickedButtonIndex:0 animated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Failed" message:@"Some information did not succesfully update..." delegate:nil cancelButtonTitle:nil    otherButtonTitles:@"OK", nil];
        [alert show];
        alert = nil;
    }
    NSLog(@"File upload failed with error - %@", error);
}

- (DBRestClient *) restClient {
    if (!restClient) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        NSLog(@"Folder '%@' contains:", metadata.path);
        for (DBMetadata *file in metadata.contents) {
            NSLog(@"\t%@", file.filename);
        }
    }
}
//this links the current view controller to dropbox, the dropbox dialog box will appear
- (void)didPressLink {
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath {
   if ([localPath rangeOfString:owner].location == NSNotFound)
   {
        if ([localPath rangeOfString:@"CompleteTable"].location != NSNotFound)
        {
            //read in the order list table from Andrews computer and then copy the information from the update table to the alltroubleorders table so that whatever changes were made can be seen by the iPad and it's not overriden
            [self readFullTable:localPath];
        }
        else if ([localPath rangeOfString:@"Job"].location != NSNotFound)
        {
            [self readJobsCSVFile:localPath];
        }
        else if ([localPath rangeOfString:@"Order"].location != NSNotFound)
        {
            [self readOrdersCSVFile:localPath];
        }
   }
    NSLog(@"File loaded into path: %@", localPath);
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    NSLog(@"There was an error loading the file - %@", error);
}

- (void)restClient:(DBRestClient *)client
loadMetadataFailedWithError:(NSError *)error {
    
    NSLog(@"Error loading metadata: %@", error);
}
//delete the crane from the database first, so that we don't recieve any duplicates
- (void) DeleteCrane:(NSString *) myHoistSrl
{
    sqlite3_stmt *statement;
    //get the path where to hold the database
    
    const char *dbPath = [databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *removeSQL = [NSString stringWithFormat:@"DELETE FROM JOBS WHERE HOISTSRL=\"%@\"", myHoistSrl];
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
        
        removeSQL = nil;
        remove_stmt = nil;
        
        sqlite3_close(contactDB);
    }
}

//this method will insert a new crane into the job table and then update that table so that it appears there from now on
- (void) InsertCraneIntoTable:(NSString *) tableName
                             :(NSString *) myHoistSrl
                             :(NSString *) myCustomerName
                             :(NSString *) myCustomerContact
                             :(NSString *) myJobNumber
                             :(NSString *) myDate
                             :(NSString *) myCustomerAddress
                             :(NSString *) myEmail
                             :(NSString *) myEquipNum
                             :(NSString *) myCraneMfg
                             :(NSString *) myHoistMfg
                             :(NSString *) myHoistMdl
                             :(NSString *) myCraneDescription
                             :(NSString *) myCap
                             :(NSString *) myCraneSrl
{
    if (tableName==@"JOBS")
    {
        [self DeleteCrane:_txtHoistSrl.text];
    }
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];
    
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (HOISTSRL, CUSTOMERNAME, CONTACT, JOBNUMBER, DATE, ADDRESS, EMAIL, EQUIPNUM, CRANEMFG, HOISTMFG, HOISTMDL, CRANEDESCRIPTION, CAP, CRANESRL) VALUES(\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\"",
                           tableName,
                           myHoistSrl,
                           myCustomerName,
                           myCustomerContact ,
                           myJobNumber,
                           myDate,
                           myCustomerAddress,
                           myEmail,
                           myEquipNum,
                           myCraneMfg,
                           myHoistMfg,
                           myHoistMdl,
                           myCraneDescription,
                           myCap,
                           myCraneSrl];
    
    if (tableName==@"JOBS")
    {
        insertSQL = [insertSQL stringByAppendingString:@");"];
    }
    else 
    {
        insertSQL = [insertSQL stringByAppendingString:@", \"ADD\");"];
        insertSQL = [insertSQL stringByReplacingOccurrencesOfString:@"CRANESRL" withString:@"CRANESRL, ACTION"];
    }
    
    //check to make sure that the database is correct
    if (sqlite3_open(dbPath, &contactDB) == SQLITE_OK)
    {
        const char *insert_stmt = [insertSQL UTF8String];
        
        sqlite3_prepare_v2(contactDB, insert_stmt, -1, &statement, nil);
        
        if (sqlite3_step(statement) != SQLITE_DONE)
        {
            NSAssert(0, @"Error updating table: JOBS");
        }
        else {
            NSLog(@"Inserted successfully into JOBS table");
            
        }
        
        sqlite3_finalize(statement);
        sqlite3_close(contactDB);
    }
    tableName = nil;
    myHoistSrl = nil;
    myCustomerName = nil;
    myCustomerContact = nil;
    myJobNumber = nil;
    myDate = nil;
    myCustomerAddress = nil;
    myEmail = nil;
    myEquipNum = nil;
    myCraneMfg = nil;
    myHoistMfg = nil;
    myHoistMdl = nil;
    myCraneDescription = nil;
    myCap = nil;
    myCraneSrl = nil;
    insertSQL = nil;
    
}

- (void) LoadMasterViewController:(MasterViewController *)input
{
    MVController = input;
}
#pragma mark - Alert View Delegate Methods
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex!=0)
    {
        if (finalSubmitPressed)
        {
            for (UIView* view in alertView.subviews)
            {
                if ([view isKindOfClass:[UITextField class]])
                {
                    UITextField *textField = (UITextField*) view;
                    if (![[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
                    {
                        hoursSpent = textField.text;
                        [self writeTextFile];
                        [self DisplayPDF];
                    }
                    else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect Input" message:@"Must enter a value for hours worked" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                        
                        [alert show];
                    }
                }
            }
            finalSubmitPressed = false;
        }
    }
}

//this method is insert all the information from the Trouble Call Order into the database and then update the MVController table view and then display the PDF
- (IBAction)FinalSubmitButtonPressed:(id)sender {
    //if when the error checking method was called last there was an error then you can not proceed
    if ([self isError] == @"NO")
    {
        //[MVController.JNVController.DVController GetDates];
        //[MVController.JNVController.DVController.tableView reloadData];
        
        NSString *myDeficientPart = [self GetOpCheckSelection];

        [self InsertJobInfoIntoTable:@"ALLTROUBLEORDERS":
                            hoistSrl:
                           jobNumber:
                                date:
              _txtWorkPerformed.text:
                     myDeficientPart:
               _txtMaterialUsed.text:
              _txtMaterialOrder.text:
                     _txtMfgMdl.text:
                _txtChainLength.text:
                _txtRopeLength.text];
        [self InsertJobInfoIntoTable:@"UPDATEJOBORDERS":
                            hoistSrl:
                           jobNumber:
                                date:
              _txtWorkPerformed.text:
                     myDeficientPart:
               _txtMaterialUsed.text:
              _txtMaterialOrder.text:
                     _txtMfgMdl.text:
                _txtChainLength.text:
                _txtRopeLength.text];
        finalSubmitPressed = true;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Overall hours" message:@"What is the hours at this job?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"ok", nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert show];
        
        //[self writeTextFile];
        //this will push the PDFViewController onto the stack
        //[self DisplayPDF];
       
        myDeficientPart = nil;
    }
    else if (errorExist==@"Some values are still empty on the Customer Info Page") {
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Error" message:errorExist delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [view show];
        
        view = nil;
    }
    else if (errorExist==@"Can not enter character 'quotations mark' ' \" ' into any customer fields!") {
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Error" message:errorExist delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [view show];
        
        view = nil;
    }
    else {
        [self isError];
    }
    
}

#pragma mark - PDF Handling
//this method shows the PDF by creating it, and then pushing the controller up
- (void) DisplayPDF
{
   // [self.navigationController pushViewController:PDFVController animated:YES];
    
    NSString *dateNoSlashes = [date stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    NSString* fileName = [NSString stringWithFormat:@"%@ %@ %@.PDF",customerName, hoistSrl, dateNoSlashes];
    
    NSArray *arrayPaths =
    NSSearchPathForDirectoriesInDomains(
                                        NSDocumentDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString *path = [arrayPaths objectAtIndex:0];
    NSString* pdfFileName = [path stringByAppendingPathComponent:fileName];
    
    UIDocumentInteractionController *controller = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:pdfFileName]];
    controller.delegate = self;
    
    CGRect navRect = self.navigationController.navigationBar.frame;
    navRect.size = CGSizeMake(1500.0f, 40.0f);
    
    [controller presentPreviewAnimated:NO];
    
    dateNoSlashes = nil;
    fileName = nil;
    arrayPaths = nil;
    path = nil;
    pdfFileName = nil;
    controller = nil;
}

- (IBAction)TroubleCallFormButtonPressed:(id)sender {
    if (![CIVController isViewLoaded])
    {
        CIVController = [self.storyboard instantiateViewControllerWithIdentifier:@"CIVController"];
        [CIVController LoadMasterViewController:MVController];
    }
    [MVController.detailViewController.navigationController pushViewController:MVController.detailViewController.CIVController animated:YES];
    //[self.navigationController pushViewController:CIVController animated:YES];
}

- (IBAction)ViewPDFButtonPressed:(id)sender {
    [self writeTextFile];
    [self DisplayPDF];
}

- (IBAction)NewOrderButtonPressed:(id)sender {
    [self EmptyOrderFormFields];
}

- (void) EmptyOrderFormFields
{
    CDVController.txtWorkPerformed.text = @"";
    CDVController.txtMaterialOrder.text = @"";
    CDVController.txtMaterialUsed.text = @"";
    CDVController.txtMfgMdl.text = @"";
    CDVController.txtRopeLength.text = @"";
    CDVController.txtChainLength.text = @"";
}

- (UIViewController *) documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

#pragma mark - Date Picker Methods


#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.detailDescriptionLabel.text = [[self.detailItem valueForKey:@"timeStamp"] description];
    }
}

- (void)simulateMemoryWarning
{
    // Post 'low memory' notification that will propagate out to controllers
    // Note: UIApplicationDidReceiveMemoryWarningNotification doesn't work for some reason.
    [[NSNotificationCenter defaultCenter] postNotificationName:
     @"UIApplicationDidReceiveMemoryWarningNotification" object:[UIApplication sharedApplication]];
}


- (void) didReceiveMemoryWarning {
   // [self setScrollView:nil];
    //[self setDetailsScrollView:nil];
    //[self setOpCheckPicker:nil];
    [self splitViewController:self.splitViewController popoverController:self.masterPopoverController willPresentViewController:MVController];
    if (![self.title isEqualToString:@"CustomerInfoViewController"])
    {
        [self setTxtHoistSrl:nil];
        [self setTxtTechName:nil];
        [self setTxtCustomerName:nil];
        [self setTxtCustomerContact:nil];
        [self setTxtJobNumber:nil];
        [self setTxtDate:nil];
        [self setTxtCustomerAddress:nil];
        [self setTxtEmail:nil];
        [self setTxtEquipNum:nil];
        [self setTxtCraneMfg:nil];
        [self setTxtHoistMfg:nil];
        [self setTxtHoistMdl:nil];
        [self setTxtCraneDescription:nil];
        [self setTxtCraneSrl:nil];
        [self setTxtCap:nil];
        [self setLblCraneDescription:nil];
    }
    if (![self.title isEqualToString:@"Call Details"])
    {    
        //[self setTxtWorkPerformed:nil];
        //[self setTxtMaterialUsed:nil];
        //[self setTxtMaterialOrder:nil];
        //[self setTxtMfgMdl:nil];
        //[self setTxtChainLength:nil];
        //[self setTxtRopeLength:nil];
        [self setHoistSrl:nil];
        [self setCustomerName:nil];
        [self setCustomerAddress:nil];
        [self setCustomerContact:nil];
        [self setHoistMdl:nil];
        [self setHoistMfg:nil];
        [self setEmail:nil];
        [self setEquipNum:nil];
        [self setCraneDescription:nil];
        [self setCraneMfg:nil];
        [self setCraneSrl:nil];
        [self setDate:nil];
        [self setCap:nil];
       // [self setScrollView:nil];
        [self setTechName:nil];
        [self setActiveField:nil];
    }
    
    @try {
        fullJessiePath = nil;
        fullJessieOrderPath = nil;
        fullCarlPath = nil;
        fullCarlOrderPath = nil;
        fullChuckPath = nil;
        fullChuckOrderPath = nil;
        jobTableCVSString = nil;
        orderTableCVSString = nil;
        self.ropeLength = nil;
        self.chainLength = nil;
        self.mfgMdl= nil;
        self.workPerformed = nil;
        self.materialUsed = nil;
        self.materialOrdered = nil; 
         
        // currentOrientation = 0;
    }
    @catch (NSException *e) {
        
    }
    //btnSelectDate = nil;
    //owner = nil;
    [self setGView:nil];
    
    // Release any retained subviews of the main view.
    self.detailDescriptionLabel = nil;
    //[super didReceiveMemoryWarning];
}

- (void) viewDidAppear:(BOOL)animated
{
    [self changeOrientation];
}

- (void)viewDidLoad
{
   // [[NSNotificationCenter defaultCenter] addObserver:[[UIApplication sharedApplication] delegate]
    //                                         selector:@selector(applicationDidReceiveMemoryWarning:) 
     //                                            name:@"UIApplicationDidReceiveMemoryWarningNotification"
      //                                         object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [self changeOrientation];
    //owner = @"Carl";
    previousFullTable = [[NSString alloc] init];
    numFilesFailed  = 0;
    numFilesUploaded = 0;
    errorExist = [[NSString alloc] init];
    //create the different View Controllers that will be pushed and popped from the stack, I create them here so that you can have access to them at all times
    //throughout the program
    //controller = [[UIDocumentInteractionController alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    documentsDir = [paths objectAtIndex:0];
    
    
    //full file location string
    databasePath = [[NSString alloc] initWithString:[documentsDir stringByAppendingPathComponent:@"contacts.db"]];
    //databasePath = @"/Users/Developer/Documents/databases/contacts.db";
    
    //these lines attach the txtDate to a datePicker
    btnSelectDate = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btnSelectDate setTitle:@"Select Date" forState:UIControlStateNormal];
    btnSelectDate.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    NSDate *now = [NSDate date];
    myDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
    [myDatePicker setDate:now animated:NO];
    [myDatePicker setDatePickerMode:UIDatePickerModeDate];
    _txtDate.inputView = myDatePicker; 
    btnSelectDate.hidden = YES;
    
    //attaches the SelectdatePressed action to the button
    [btnSelectDate addTarget:self
                      action:@selector(SelectDatePressed:)
            forControlEvents:UIControlEventTouchDown];
    
    _txtDate.inputAccessoryView = btnSelectDate;
    [self.view addSubview:btnSelectDate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWasShown:) 
                                                 name:UIKeyboardDidShowNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:) 
                                                 name:UIKeyboardWillHideNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    //create the array that stores the operational check information, this is what is shown in the picker view
    opCheckArray = [[NSArray alloc] initWithObjects:@"Hoist Main", @"Hoist Aux", @"Trolley", @"Bridge", @"Runway", nil];
    
    
    //setContentSize makes sure that the area that is scrollable is smaller than the scroll view so that it cant scroll side to side but can scroll up and down,
    [_ScrollView setContentSize:CGSizeMake(500, 916)];
    [_DetailsScrollView setContentSize:CGSizeMake(500, 916)];
    [self didPressLink];
    owner = [self GetOwner];
    //owner = @"Carl";
    now = nil;
    
   // [self CreateUpdateTables];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    
    [super viewDidLoad];
   // [self simulateMemoryWarning];
    
    //CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"UISimulatedMemoryWarningNotification", NULL, NULL, true);
    [self CreateUpdateTables];
}

-(void) viewWillDisappear:(BOOL)animated
{
    //[self setScrollView:nil];
    //[self setDetailsScrollView:nil];
    if (![self.title isEqualToString:@"CustomerInfoViewController"])
    {
        [self setTxtHoistSrl:nil];
        [self setTxtTechName:nil];
        [self setTxtCustomerName:nil];
        [self setTxtCustomerContact:nil];
        [self setTxtJobNumber:nil];
        [self setTxtDate:nil];
        [self setTxtCustomerAddress:nil];
        [self setTxtEmail:nil];
        [self setTxtEquipNum:nil];
        [self setTxtCraneMfg:nil];
        [self setTxtHoistMfg:nil];
        [self setTxtHoistMdl:nil];
        [self setTxtCraneDescription:nil];
        [self setTxtCraneSrl:nil];
        [self setTxtCap:nil];
        [self setLblCraneDescription:nil];
    }
    if (![self.title isEqualToString:@"Call Details"])
    {    
        [self setTxtWorkPerformed:nil];
        [self setTxtMaterialUsed:nil];
        [self setTxtMaterialOrder:nil];
        [self setTxtMfgMdl:nil];
        [self setTxtChainLength:nil];
        [self setTxtRopeLength:nil];
        [self setHoistSrl:nil];
        [self setCustomerName:nil];
        [self setCustomerAddress:nil];
        [self setCustomerContact:nil];
        [self setHoistMdl:nil];
        [self setHoistMfg:nil];
        [self setEmail:nil];
        [self setEquipNum:nil];
        [self setCraneDescription:nil];
        [self setCraneMfg:nil];
        [self setCraneSrl:nil];
        [self setDate:nil];
        [self setCap:nil];
       // [self setOpCheckPicker:nil];
    }
    
   // [self setCDVController:nil];
   // [self setCIVController:nil];
   // [self setScrollView:nil];
    [self setTechName:nil];
    [self setActiveField:nil];
    @try {
        fullJessieOrderPath = nil;
        fullJessiePath = nil;
        fullCarlPath = nil;
        fullCarlOrderPath = nil;
        fullChuckPath = nil;
        fullChuckOrderPath = nil;
        jobTableCVSString = nil;
        orderTableCVSString = nil;
        self.ropeLength = nil;
        self.chainLength = nil;
        self.mfgMdl= nil;
        self.workPerformed = nil;
        self.materialUsed = nil;
        self.materialOrdered = nil; 
       // currentOrientation = 0;
    }
    @catch (NSException *e) {
        
    }
    //btnSelectDate = nil;
    [self setGView:nil];
    //[super viewDidUnload];
    // Release any retained subviews of the main view.
    self.detailDescriptionLabel = nil;     
}


- (void)viewDidUnload
{
    
    [self setScrollView:nil];
    [self setDetailsScrollView:nil];
    //[self setOpCheckPicker:nil];
    if (![self.title isEqualToString:@"CustomerInfoViewController"])
    {
        [self setTxtHoistSrl:nil];
        [self setTxtTechName:nil];
        [self setTxtCustomerName:nil];
        [self setTxtCustomerContact:nil];
        [self setTxtJobNumber:nil];
        [self setTxtDate:nil];
        [self setTxtCustomerAddress:nil];
        [self setTxtEmail:nil];
        [self setTxtEquipNum:nil];
        [self setTxtCraneMfg:nil];
        [self setTxtHoistMfg:nil];
        [self setTxtHoistMdl:nil];
        [self setTxtCraneDescription:nil];
        [self setTxtCraneSrl:nil];
        [self setTxtCap:nil];
        [self setLblCraneDescription:nil];
    }
    if (![self.title isEqualToString:@"Call Details"])
    {    
        [self setTxtWorkPerformed:nil];
        [self setTxtMaterialUsed:nil];
        [self setTxtMaterialOrder:nil];
        [self setTxtMfgMdl:nil];
        [self setTxtChainLength:nil];
        [self setTxtRopeLength:nil];
        [self setHoistSrl:nil];
        [self setCustomerName:nil];
        [self setCustomerAddress:nil];
        [self setCustomerContact:nil];
        [self setHoistMdl:nil];
        [self setHoistMfg:nil];
        [self setEmail:nil];
        [self setEquipNum:nil];
        [self setCraneDescription:nil];
        [self setCraneMfg:nil];
        [self setCraneSrl:nil];
        [self setDate:nil];
        [self setCap:nil];
       // [self setScrollView:nil];
        [self setTechName:nil];
        [self setActiveField:nil];
    }

    @try {
        fullCarlPath = nil;
        fullCarlOrderPath = nil;
        fullChuckPath = nil;
        fullChuckOrderPath = nil;
        jobTableCVSString = nil;
        orderTableCVSString = nil;
        self.ropeLength = nil;
        self.chainLength = nil;
        self.mfgMdl= nil;
        self.workPerformed = nil;
        self.materialUsed = nil;
        self.materialOrdered = nil; 
       // currentOrientation = 0;
    }
    @catch (NSException *e) {
        
    }
    //btnSelectDate = nil;
    //owner = nil;
    [self setGView:nil];
  
    // Release any retained subviews of the main view.
    self.detailDescriptionLabel = nil;
    
    [super viewDidUnload];
}

- (NSString *) GetOwner
{
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];
    NSString *selectSQL = [[NSString alloc] init];
    const char *select_stmt;
    NSString *myName;
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        //select all the information that in the actual trouble call form
        selectSQL = [NSString stringWithFormat:@"SELECT NAME FROM IPADOWNER"];
        select_stmt = [selectSQL UTF8String];
        
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                const char *name = (char*) sqlite3_column_text(statement, 0); 
                myName = [NSString stringWithUTF8String:name];
                name = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        sqlite3_close(contactDB);
    }
    
    return myName;
    myName = nil;
}

#pragma mark Update Tables Methods
//this methods creates the table that will hold all the new information that has been inserted so that the other iPad can grab the new information from one iPad
- (void) CreateUpdateTables
{
    NSString *querySql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS UPDATEJOBORDERS (ID INTEGER PRIMARY KEY AUTOINCREMENT, HOISTSRL TEXT, JOBNUMBER TEXT, DATE TEXT, OPCHECK TEXT, WORKPERFORMED TEXT, MATERIALUSED TEXT, MATERIALORDERED TEXT, MFGMDL TEXT, CHAINLENGTH TEXT, ROPELENGTH TEXT, ACTION TEXT)"];
    const char *sql_stmt = [querySql UTF8String];
    char *errMess;
    sqlite3_stmt *statement = NULL;
    
    //open the database
    if (sqlite3_open([databasePath UTF8String], &contactDB) == SQLITE_OK)
    {
        //creates the table using the querySql NSString
        if (sqlite3_exec(contactDB, sql_stmt, NULL, NULL, &errMess) == SQLITE_OK) 
        {
            NSLog(@"ALL UPDATE JOB ORDERS TABLE CREATED");

        }
        sqlite3_close(contactDB);
    }
    //release memory
    querySql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS UPDATEJOBS (ID INTEGER PRIMARY KEY AUTOINCREMENT, HOISTSRL TEXT, CUSTOMERNAME TEXT, CONTACT TEXT, JOBNUMBER TEXT, DATE TEXT, ADDRESS TEXT, EMAIL TEXT, EQUIPNUM TEXT, CRANEMFG TEXT, HOISTMFG TEXT, HOISTMDL TEXT, CRANEDESCRIPTION TEXT, CAP TEXT, CRANESRL TEXT, ACTION TEXT)"];
    sql_stmt = [querySql UTF8String];
    
    //open the database
    if (sqlite3_open([databasePath UTF8String], &contactDB) == SQLITE_OK)
    {
        //creates the table using the querySql NSString
        if (sqlite3_exec(contactDB, sql_stmt, NULL, NULL, &errMess) == SQLITE_OK) 
        {
            NSLog(@"UPDATE JOBS TABLE CREATED");
        }
        sqlite3_close(contactDB);
        sqlite3_finalize(statement);
    }
    
    //release memory
    querySql = nil;
    sql_stmt = nil;
    errMess = nil;
    
    sqlite3_finalize(statement);
}

//delete the crane from the database first, so that we don't recieve any duplicates
- (void) DeleteJob:(NSString *) myHoistSrl: (NSString *) myJobNumber: (NSString *) myDate
{
    sqlite3_stmt *statement;
    //get the path where to hold the database
    
    const char *dbPath = [databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *removeSQL = [NSString stringWithFormat:@"DELETE FROM ALLTROUBLEORDERS WHERE HOISTSRL=\"%@\" AND JOBNUMBER=\"%@\" AND DATE=\"%@\"", myHoistSrl, myJobNumber, myDate];
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
        
        removeSQL = nil;
        remove_stmt = nil;
        
        sqlite3_close(contactDB);
    }
    dbPath = nil;
    statement = nil;
    
    sqlite3_finalize(statement);
}

//delete the crane from the database first, so that we don't recieve any duplicates
- (void) DeleteAllJobs
{
    sqlite3_stmt *statement;
    //get the path where to hold the database
    
    const char *dbPath = [databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        NSString *removeSQL = [NSString stringWithFormat:@"DELETE FROM ALLTROUBLEORDERS WHERE HOISTSRL!=\"0\""];
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
        
        sqlite3_close(contactDB);
    }
    
    sqlite3_finalize(statement);
}

//this method will insert job information into the Update Job Orders or All Trouble Orders tables depending on what tableName is sent to this method
- (void) InsertJobInfoIntoTable :(NSString *) tableName
                                :(NSString *) myHoistSrl
                                :(NSString *) myJobNumber
                                :(NSString *) myDate
                                :(NSString *) myWorkPerformed
                                :(NSString *) myDeficientPart
                                :(NSString *) myMaterialUsed
                                :(NSString *) myMaterialOrder
                                :(NSString *) myMfgMdl
                                :(NSString *) myChainLength
                                :(NSString *) myRopeLength
{
    if (tableName==@"ALLTROUBLEORDERS")
    {
        [self DeleteJob:myHoistSrl:myJobNumber:myDate];
    }
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];

    NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (HOISTSRL, JOBNUMBER, DATE, OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH) VALUES(\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\"",
                           tableName,
                           myHoistSrl,
                           myJobNumber,
                           myDate,
                           myDeficientPart ,
                           [myWorkPerformed stringByReplacingOccurrencesOfString:@"\"" withString:@"\\"],
                           [myMaterialUsed stringByReplacingOccurrencesOfString:@"\"" withString:@"\\"],
                           [myMaterialOrder stringByReplacingOccurrencesOfString:@"\"" withString:@"\\"],
                           [myMfgMdl stringByReplacingOccurrencesOfString:@"\"" withString:@"\\"],
                           [myChainLength stringByReplacingOccurrencesOfString:@"\"" withString:@"\\"],
                           [myRopeLength stringByReplacingOccurrencesOfString:@"\"" withString:@"\\"]];
    //NSString *insertSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ALLORDERS (JOBNUMBER, PART, DEFICIENT, DEFICIENTPART, NOTES, PICKERSELECTION) VALUES (?,?,?,?,?,?)"];
    
    if (tableName==@"ALLTROUBLEORDERS")
    {
        insertSQL = [insertSQL stringByAppendingString:@");"];
    }
    else {
        insertSQL = [insertSQL stringByAppendingString:@", \"ADD\");"];
        insertSQL = [insertSQL stringByReplacingOccurrencesOfString:@"ROPELENGTH" withString:@"ROPELENGTH, ACTION"];
    }
    
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
        insert_stmt = nil;
        sqlite3_close(contactDB);
    }
    tableName = nil;
    myHoistSrl = nil;
    myJobNumber = nil;
    myDate = nil;
    myDeficientPart = nil;
    myWorkPerformed = nil;
    myMaterialUsed = nil;
    myMaterialOrder = nil;
    myMfgMdl = nil;
    myChainLength = nil;
    myRopeLength = nil;
    insertSQL = nil;
    
    sqlite3_finalize(statement);
}

- (void) UpdateTextFields:(NSString *) myHoistsrl
                         :(NSString *) myCustName
                         :(NSString *) myContact
                         :(NSString *) myAddress
                         :(NSString *) myEmailAddress
                         :(NSString *) myEquipNumber
                         :(NSString *) myCraneMfg
                         :(NSString *) myHoistMfg
                         :(NSString *) myHoistMdl
                         :(NSString *) myCraneDescription
                         :(NSString *) myCap
                         :(NSString *) myCraneSrl
{
    _txtHoistSrl.text = myHoistsrl;
    _txtCustomerName.text = myCustName;
    _txtCustomerContact.text = myContact;
    _txtCustomerAddress.text = myAddress;
    _txtEmail.text = myEmailAddress;
    _txtEquipNum.text = myEquipNumber;
    _txtCraneMfg.text = myCraneMfg;
    _txtHoistMfg.text = myHoistMfg;
    _txtCraneDescription.text = myCraneDescription;
    _txtCap.text = myCap;
    _txtCraneSrl.text = myCraneSrl;
    _txtHoistMdl.text = myHoistMdl;
    CDVController.hoistSrl = myHoistsrl;
    CDVController.customerName = myCustName;
    CDVController.customerContact = myContact;
    CDVController.customerAddress = myAddress;
    CDVController.email = myEmailAddress;
    CDVController.craneMfg = myCraneMfg;
    CDVController.hoistMfg = myHoistMfg;
    CDVController.craneDescription = myCraneDescription;
    CDVController.cap = myCap;
    CDVController.craneSrl = myCraneSrl;
    CDVController.hoistMdl = myHoistMdl;
    
    myHoistsrl = nil;
    myCustName = nil;
    myContact = nil;
    myAddress = nil;
    myEmailAddress = nil;
    myEquipNumber = nil;
    myCraneMfg = nil;
    myHoistMfg = nil;
    myHoistMdl = nil;
    myCraneDescription = nil;
    myCap = nil;
    myCraneSrl = nil;

}

- (void) FillCallForm   : (NSString *) opCheck
                        : (NSString *) myWorkPerformed
                        : (NSString *) myMaterialUsed
                        : (NSString *) myMaterialOrdered
                        : (NSString *) myMfgMdl
                        : (NSString *) myChainLength
                        : (NSString *) myRopeLength
{
    _txtWorkPerformed.text = myWorkPerformed;
    _txtMaterialUsed.text = myMaterialUsed;
    _txtMaterialOrder.text = myMaterialOrdered;
    _txtMfgMdl.text = myMfgMdl;
    _txtChainLength.text = myChainLength;
    _txtRopeLength.text = myRopeLength;
    
    opCheck = nil;
    myWorkPerformed = nil;
    myMaterialUsed = nil;
    myMaterialOrdered = nil;
    myMfgMdl = nil;
    myChainLength = nil;
    myRopeLength = nil;
}
/*
- (IBAction)LoadHoistSrlPressed {
    sqlite3_stmt *statement;
    bool waterDistrictCrane = NO;
    const char *dbPath = [databasePath UTF8String];
    bool craneExist=NO;
    if (![_txtHoistSrl.text isEqualToString:@""])
    {
        if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
        { 
            //grab only the crane information from the WATERDISTRICTCRANES table, which simply contains the water district cranes
            NSString *selectSQL = [NSString stringWithFormat:@"SELECT TYPE, CAPACITY, MDL_HOIST, SRL_CRANE_MFG, MANUFACTURER, UNIT_ID FROM WATERDISTRICTCRANES WHERE SRL_HOIST=\"%@\"", _txtHoistSrl.text];   
            const char *select_stmt = [selectSQL UTF8String];
            if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    craneExist = YES;
                    const char *type = (char*) sqlite3_column_text(statement, 0);           //information at first column
                    const char *capacity = (char*) sqlite3_column_text(statement, 1);       //second column
                    const char *mdlHoist = (char*) sqlite3_column_text(statement, 2);       //third column
                    const char *srlCraneMfg = (char*) sqlite3_column_text(statement, 3);    //fourth column
                    const char *myEquipNum = (char*) sqlite3_column_text(statement, 5);
                    //const char *manufacturer = (char*) sqlite3_column_text(statement, 4);
                    
                    // NSString *custName = txtCustomerName.text;
                    NSString *myHoistSrl = _txtHoistSrl.text;
                    
                    [self EmptyTextFields];
                    
                    _txtHoistSrl.text = myHoistSrl;
                    
                    //-----------------------Water district information -----------------
                    _txtCustomerName.text = @"LVVWD";
                    _txtCustomerContact.text = @"DAVID BOURN";
                    _txtCustomerAddress.text = @"1001 S VALLEY VIEW BLVD, LAS VEGAS, NV 89107";
                    _txtEmail.text = @"DAVID.BOURN@LVVWD.COM";
                    //txtCustomerName.text = custName;
                    //txtCustomerName.text = [NSString stringWithUTF8String:manufacturer];
                    _txtCraneDescription.text = [NSString stringWithUTF8String:type];    //store type
                    _txtCap.text = [NSString stringWithUTF8String:capacity];             //store cap
                    _txtHoistMdl.text = [NSString stringWithUTF8String:mdlHoist];        //store hoistMdl
                    _txtCraneSrl.text = [NSString stringWithUTF8String:srlCraneMfg];     //store CraneSrl
                    _lblCraneDesc.text = [NSString stringWithUTF8String:type];           //store CraneDesc
                    _txtEquipNum.text = [NSString stringWithUTF8String:myEquipNum];
                    
                    NSLog(@"Retrieved condition from the table");
                    //release memory
                    type = nil;
                    capacity = nil;
                    mdlHoist = nil;
                    srlCraneMfg = nil;
                    myEquipNum = nil;
                    myHoistSrl = nil;
                    waterDistrictCrane = YES;
                }
            }
            else {
                NSLog(@"Failed to find jobnumber in table");
            }
            //Grab customer and crane information from the JOBS table with the srl hoist as the identifier
            selectSQL = [NSString stringWithFormat:@"SELECT HOISTSRL, CUSTOMERNAME, CONTACT, DATE, ADDRESS, EMAIL, EQUIPNUM, CRANEMFG, HOISTMFG, HOISTMDL, CRANEDESCRIPTION, CAP, CRANESRL, JOBNUMBER FROM JOBS WHERE HOISTSRL=\"%@\"", _txtHoistSrl.text];
            select_stmt = [selectSQL UTF8String];
            if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    waterDistrictCrane = NO;
                    craneExist = YES;
                    //get the information from the table
                    const char *myHoistSrl = (char*) sqlite3_column_text(statement, 0);                   //info at column 1: HOISTSRL
                    const char *myCustName = (char*) sqlite3_column_text(statement, 1);                   //column 2: CUSTOMERNAME
                    const char *myContact = (char*) sqlite3_column_text(statement, 2);                    //column 3: CONTACT
                    const char *myDate = (char*) sqlite3_column_text(statement, 3);                       //column 4: DATE
                    const char *myAddress = (char*) sqlite3_column_text(statement, 4);                    //column 5: ADDRESS
                    const char *myEmail = (char*) sqlite3_column_text(statement, 5);                      //column 6: EMAIL
                    const char *myEquipNum = (char*) sqlite3_column_text(statement, 6);                   //column 7: EQUIPNUM
                    const char *myCraneMfg = (char*) sqlite3_column_text(statement, 7);                   //column 8: CRANEMFG
                    const char *myHoistMfg = (char*) sqlite3_column_text(statement, 8);                   //column 9: HOISTMFG
                    const char *myHoistMdl = (char*) sqlite3_column_text(statement, 9);                   //column 10: HOISTMDL
                    const char *myCraneDescription = (char*) sqlite3_column_text(statement, 10);          //column 11: CRANEDESCRIPTION
                    const char *myCap = (char*) sqlite3_column_text(statement, 11);                       //column 12: CAP
                    const char *myCraneSrl = (char*) sqlite3_column_text(statement, 12);                  //column 13: CRANESRL
                    const char *chJobNumber = (char*) sqlite3_column_text(statement, 13);               //column 14: JOBNUMBER
                    //makes sure that the job number stays displayed
                    
                    //txtJobNumber.text = [NSString stringWithUTF8String:chJobNumber];
                    _txtHoistSrl.text = [NSString stringWithUTF8String:myHoistSrl];
                    _txtDate.text = [NSString stringWithUTF8String:myDate];
                    if (waterDistrictCrane == YES)
                    {
                        _txtCustomerName.text = @"LVVWD";
                        _txtCustomerContact.text = @"DAVID BOURN";
                        _txtCustomerAddress.text = @"1001 S VALLEY VIEW BLVD, LAS VEGAS, NV 89107";
                        _txtEmail.text = @"DAVID.BOURN@LVVWD.COM";
                    }
                    else {
                        _txtCustomerName.text = [NSString stringWithUTF8String:myCustName];
                        _txtCustomerContact.text = [NSString stringWithUTF8String:myContact];
                        _txtCustomerAddress.text = [NSString stringWithUTF8String:myAddress];
                        _txtEmail.text = [NSString stringWithUTF8String:myEmail];
                    }
                    _txtEquipNum.text = [NSString stringWithUTF8String:myEquipNum];
                    _txtCraneMfg.text = [NSString stringWithUTF8String:myCraneMfg];
                    _txtHoistMfg.text = [NSString stringWithUTF8String:myHoistMfg];
                    _txtHoistMdl.text = [NSString stringWithUTF8String:myHoistMdl];
                    if ([_txtCraneDescription.text isEqualToString:@""])
                    {
                        _txtCraneDescription.text = [NSString stringWithUTF8String:myCraneDescription];
                    }
                    if ([_txtCap.text isEqualToString:@""])
                    {
                        _txtCap.text = [NSString stringWithUTF8String:myCap];
                        
                    }
                    if ([_txtCraneSrl.text isEqualToString:@""])
                    {
                        _txtCraneSrl.text = [NSString stringWithUTF8String:myCraneSrl];
                    }
                    if ([_txtEquipNum.text isEqualToString:@""])
                    {
                        _txtEquipNum.text = [NSString stringWithUTF8String:myEquipNum];
                    }
                    if ([_lblCraneDesc.text isEqualToString:@""])
                    {
                        _lblCraneDesc.text = [NSString stringWithUTF8String:myCraneDescription];
                    }
                    _txtJobNumber.text = [NSString stringWithUTF8String:chJobNumber];
                    NSLog(@"Retrieved condition from the table");
                    //release memory
                    myHoistSrl = nil;
                    myDate = nil;
                    myEquipNum = nil;
                    myCraneMfg = nil;
                    myHoistMfg = nil;
                    myHoistMdl = nil;
                    myCraneDescription = nil;
                    myCap = nil;
                    myCraneSrl = nil;
                    chJobNumber = nil;
                }
            }
            else {
                NSLog(@"Failed to find jobnumber in table");
            }
            //if this crane does not exist, which means that it is not a water district crane then display that it does not exist
            if (craneExist ==NO)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NO CRANE" message:@"No CRANE by this HOIST SERIAL NUMBER was found" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK"    , nil];
                [alert show];
            }
        }
    }
}*/

- (void) EmptyTextFields
{
    _txtCustomerName.text = @"";
    _txtCustomerAddress.text=@"";
    _txtJobNumber.text = @"";
    _txtCustomerContact.text = @"";
    _txtCap.text = @"";
    _txtCraneMfg.text = @"";
    _txtCraneSrl.text = @"";
    _txtCustomerName.text = @"";
    _txtEquipNum.text = @"";
    _txtHoistMdl.text = @"";
    _txtHoistMfg.text = @"";
    _txtHoistSrl.text = @"";
    _txtEmail.text = @"";
    _txtCraneDescription.text = @"";
    _lblCraneDesc.text = @"";
}

//this method will need to open the order by getting both the hoist srl number or equip number and the job number so that they can get any hoist srl at any time
- (void) OpenOrderFromJobNumber: (NSString *) input;
{
    sqlite3_stmt *statement;
    const char *dbPath = [databasePath UTF8String];
    int counter=0;
    bool orderExist = NO;
    NSString *selectSQL = [[NSString alloc] init];
    const char *select_stmt;
    
    if (sqlite3_open(dbPath, &contactDB)==SQLITE_OK)
    { 
        //select all the information that in the actual trouble call form
        selectSQL = [NSString stringWithFormat:@"SELECT OPCHECK, WORKPERFORMED, MATERIALUSED, MATERIALORDERED, MFGMDL, CHAINLENGTH, ROPELENGTH WHERE HOISTSRL=\"%@\"", _txtHoistSrl.text];
        select_stmt = [selectSQL UTF8String];
        
        if (sqlite3_prepare_v2(contactDB, select_stmt, -1, &statement, NULL)==SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                orderExist = YES;
                const char *chOpCheck = (char*) sqlite3_column_text(statement, 1);
                const char *chWorkPerformed = (char*) sqlite3_column_text(statement, 2);
                const char *chMaterialUsed = (char*) sqlite3_column_text(statement, 3);
                const char *chMfgMdl = (char*) sqlite3_column_text(statement, 4);
                const char *chChainLength = (char*) sqlite3_column_text(statement, 5);
                const char *chRopeLength = (char*) sqlite3_column_text(statement, 6);
                
               // NSUInteger *myPickerSelection = (NSUInteger *) [[NSString stringWithUTF8String:chOpCheck] integerValue];
                _txtWorkPerformed = [NSString stringWithUTF8String:chWorkPerformed];
                _txtMaterialUsed = [NSString stringWithUTF8String:chMaterialUsed];
                _txtMfgMdl = [NSString stringWithUTF8String:chMfgMdl];
                _txtChainLength = [NSString stringWithUTF8String:chChainLength];
                _txtRopeLength = [NSString stringWithUTF8String:chRopeLength];
                
                counter++;
                //NSLog(@"Retrieved condition from the table");
                //release memory
                chOpCheck = nil;
                chWorkPerformed = nil;
                chMaterialUsed = nil;
                chMfgMdl = nil;
                chChainLength = nil;
                chRopeLength = nil;
            }
            sqlite3_finalize(statement);
        }
        else {
            NSLog(@"Failed to find jobnumber in table");
        }
        sqlite3_close(contactDB);
    }
    
    sqlite3_finalize(statement);
}

#pragma mark - Write Text File

//This text file that is written contains all the information that has been created: Customer Information; Crane Information; and Inspection Information
- (void) writeTextFile {
    NSMutableString *printString = [NSMutableString stringWithString:@""];
    NSMutableString *customerInfoResultsColumn = [NSMutableString stringWithString:@""];
    NSMutableString *craneDescriptionLeftColumn = [NSMutableString stringWithString:@""];
    NSMutableString *craneDescriptionResultsColumn = [NSMutableString stringWithString:@""];
    NSMutableString *craneDescriptionRightColumn = [NSMutableString stringWithString:@""];
    NSMutableString *craneDescriptionRightResultsColumn = [NSMutableString stringWithString:@""];
    NSMutableString *footerLeft = [NSMutableString stringWithString:@""];
    NSMutableString *footerRight = [NSMutableString stringWithString:@""];
    NSMutableString *header = [NSMutableString stringWithString:@""];
    NSMutableString *myCraneDescription = [NSMutableString stringWithString:@""];
    NSMutableString *operationalCheck = [NSMutableString stringWithString:@""];
    NSMutableString *myWorkPerformed = [NSMutableString stringWithString:@""];
    NSMutableString *miscInfo = [NSMutableString stringWithString:@""];
    NSMutableString *myMaterialUsed = [NSMutableString stringWithString:@""];
    NSMutableString *myMaterialOrdered = [NSMutableString stringWithString:@""];
    
    //customer information titles and descriptions
    [printString appendString:@"Customer Information\n\n"];
    [printString appendString:[NSMutableString stringWithFormat:@"Customer Name:\n"]];
    [printString appendString:[NSString stringWithFormat:@"Customer Contact:\n"]];
    [printString appendString:[NSString stringWithFormat:@"Job Number:\n"]];
    [printString appendString:[NSString stringWithFormat:@"Email Address:\n"]];
    [printString appendString:[NSString stringWithFormat:@"Customer Address:\n\n"]];
    //the customer information results
    [customerInfoResultsColumn appendString:[NSMutableString stringWithFormat:@"\n\n%@\n", customerName]];
    [customerInfoResultsColumn appendString:[NSString stringWithFormat:@"%@\n", customerContact]];
    [customerInfoResultsColumn appendString:[NSString stringWithFormat:@"%@\n",jobNumber]];
    [customerInfoResultsColumn appendString:[NSString stringWithFormat:@"%@\n", email]];
    [customerInfoResultsColumn appendString:[NSString stringWithFormat:@"%@\n\n", customerAddress]];
    
    [myCraneDescription appendString:[NSString stringWithFormat:@"Crane Description: %@", craneDescription]];
    //the crane description titles
    [craneDescriptionLeftColumn appendString:@"Overall Hours Spent:\n"];
    [craneDescriptionLeftColumn appendString:@"Crane Mfg:\n"];
    [craneDescriptionLeftColumn appendString:@"Hoist Mfg:\n"];
    [craneDescriptionLeftColumn appendString:@"Hoist Model:\n"];
    //crane description results
    [craneDescriptionResultsColumn appendString:[NSMutableString stringWithFormat:@"\n\n%@\n", hoursSpent]];
    [craneDescriptionResultsColumn appendString:[NSString stringWithFormat:@"%@\n", craneMfg]];
    [craneDescriptionResultsColumn appendString:[NSString stringWithFormat:@"%@\n", hoistMfg]];
    [craneDescriptionResultsColumn appendString:[NSString stringWithFormat:@"%@\n", hoistMdl]];
    //crane description titles right column
    [craneDescriptionRightColumn appendString:@"\n\nCap:\n"];
    [craneDescriptionRightColumn appendString:@"Crane Srl:\n"];
    [craneDescriptionRightColumn appendString:@"Hoist Srl:\n"];
    [craneDescriptionRightColumn appendString:@"Equip #:\n"];
    //creane description results
    [craneDescriptionRightResultsColumn appendString:[NSMutableString stringWithFormat:@"\n\n%@\n", cap]];
    [craneDescriptionRightResultsColumn appendString:[NSString stringWithFormat:@"%@\n", craneSrl]];
    [craneDescriptionRightResultsColumn appendString:[NSString stringWithFormat:@"%@\n", hoistSrl]];
    [craneDescriptionRightResultsColumn appendString:[NSString stringWithFormat:@"%@\n", equipNum]];
    
    [footerLeft appendString:[NSString stringWithFormat:@"Technician:%@\nDate: %@",techName, date]];
    [footerRight appendString:[NSString stringWithFormat:@"Customer:%@\nDate: %@",customerName, date]];
    
    [header appendString:[NSString stringWithFormat:@"Silverstate Wire Rope and Rigging\n\n24-Hour Emergency Service\nSales - Service - Repair\nElectrical - Mechanical - Pneumatic\nCal-OSHA Accredited"]];
    
    [operationalCheck appendString:[NSString stringWithFormat:@"Operational Check: %@\n", [self GetOpCheckSelection]]];
    
    [myWorkPerformed appendString:[NSString stringWithFormat:@"Work Performed and Discrepancies Noted:\n\n%@", _txtWorkPerformed.text]];
    
    [miscInfo appendString:[NSString stringWithFormat:@"Rope Length: %@    Chain Length: %@    Mfg and Mdl or Remote or Pendant: %@", _txtRopeLength.text, _txtChainLength.text, _txtMfgMdl.text]];
    
    [myMaterialUsed appendString:[NSString stringWithFormat:@"Material Used: %@", _txtMaterialUsed.text]];
     
    [myMaterialOrdered appendString:[NSString stringWithFormat:@"Material Ordered: %@", _txtMaterialOrder.text]];
    //Create the file
    
    NSError *error;
    
    //create file manager
    
    NSString *dateNoSlashes = [date stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    NSString* fileName = [NSString stringWithFormat:@"%@ %@ %@.PDF",customerName, hoistSrl, dateNoSlashes];
    
    NSArray *arrayPaths =
    NSSearchPathForDirectoriesInDomains(
                                        NSDocumentDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString *path = [arrayPaths objectAtIndex:0];
    NSString* pdfFileName = [path stringByAppendingPathComponent:fileName];
    //NSString *documentsDirectory = @"/Users/Developer/Documents";
    NSString *filePath = pdfFileName;
    //NSString *afilePath = [documentsDirectory stringByAppendingPathComponent:@"jobInfoArray.txt"];
    
    NSLog(@"string to write:%@", printString);
    
    [printString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    [self CreatePDFFile:printString
                       :customerInfoResultsColumn
                       :craneDescriptionLeftColumn
                       :craneDescriptionResultsColumn
                       :craneDescriptionRightColumn
                       :craneDescriptionRightResultsColumn
                       :filePath
                       :footerLeft
                       :footerRight
                       :header
                       :myCraneDescription
                       :operationalCheck
                       :myWorkPerformed
                       :miscInfo
                       :myMaterialUsed
                       :myMaterialOrdered];
    dateNoSlashes = nil;
    fileName = nil;
    arrayPaths = nil;
    path = nil;
    pdfFileName =nil;
    filePath = nil;
    printString = nil;
    customerInfoResultsColumn = nil;
    craneDescriptionLeftColumn = nil;
    craneDescriptionResultsColumn = nil;
    craneDescriptionRightColumn = nil;
    craneDescriptionRightResultsColumn = nil;
    filePath = nil;
    footerLeft = nil;
    footerRight = nil;
    header = nil;
    myCraneDescription = nil;
    operationalCheck = nil;
    myWorkPerformed = nil;
    miscInfo = nil;
    myMaterialUsed = nil;
    myMaterialOrdered = nil;
}

- (NSString *) GetOpCheckSelection
{
    NSUInteger selectedRow = [_OpCheckPicker selectedRowInComponent:0];
    NSString *myDeficientPart =  [[_OpCheckPicker delegate] pickerView:_OpCheckPicker titleForRow:selectedRow forComponent:0];
    return myDeficientPart;
}

- (void) SetOpCheckSelection: (NSString *) myType
{
    NSUInteger selectedRow;
    
    if ([myType isEqualToString:@"Hoist Main"])
        selectedRow = 0;
    else if ([myType isEqualToString:@"Hoist Aux"])
        selectedRow = 1;
    else if ([myType isEqualToString:@"Trolley"])
        selectedRow = 2;
    else if ([myType isEqualToString:@"Bridge"])
        selectedRow = 3;
    else if ([myType isEqualToString:@"Runway"])
        selectedRow = 4;
    
    [_OpCheckPicker selectRow:selectedRow inComponent:0 animated:YES];
}

- (void) CreatePDFFile:(NSString *) printString
                      :(NSString *) customerInfoResultsColumn
                      :(NSString *) craneDescriptionLeftColumn
                      :(NSString *) craneDescriptionResultsColumn
                      :(NSString *) craneDescriptionRightColumn
                      :(NSString *) craneDescriptionRightResultsColumn
                      :(NSString *) filePath
                      :(NSString *) footerLeft
                      :(NSString *) footerRight
                      :(NSString *) header
                      :(NSString *) myCraneDescription
                      :(NSString *) operationalCheck
                      :(NSString *) myWorkPerformed
                      :(NSString *) miscInfo
                      :(NSString *) myMaterialUsed
                      :(NSString *) myMaterialOrdered
{
    // Create URL for PDF file
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    CGContextRef pdfContext = CGPDFContextCreateWithURL((__bridge CFURLRef)fileURL, NULL, NULL);
    CGPDFContextBeginPage(pdfContext, NULL);
    UIGraphicsPushContext(pdfContext);
    UIImage *myImage = [UIImage imageNamed:@"logo.png"];
    // Flip coordinate system
    CGRect bounds = CGContextGetClipBoundingBox(pdfContext);
    CGContextScaleCTM(pdfContext, 1.0, -1.0);
    CGContextTranslateCTM(pdfContext, 0.0, -bounds.size.height);
    //NSString *conditionRatingString = [[NSString alloc] initWithString:@"Crane Condition Rating: \n1=Great \n2=Good Minor Problems (scheduled repair) \n3=Maintenance Problems(Immediate Repair) \n4=Safety Concern(Immediate Repair) \n5=Crane's conditions require it to be taged out"];
    
    // Drawing commands
    //[printString drawAtPoint:CGPointMake(100, 100) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [myImage drawInRect:CGRectMake(50, 150, 500, 500) blendMode:kCGBlendModeLighten alpha:.15f];
    [header drawInRect:CGRectMake(20, 20, 200, 200) withFont:[UIFont systemFontOfSize:10.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
    [printString drawInRect:CGRectMake(225, 20, 120 , 120) withFont:[UIFont systemFontOfSize:10.0f] lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentLeft];
    [customerInfoResultsColumn drawInRect:CGRectMake(325, 20, 400, 120) withFont:[UIFont systemFontOfSize:10.0f]];
    [myCraneDescription drawInRect:CGRectMake(20, 120, 500, 160) withFont:[UIFont systemFontOfSize:10.0f]];
    [craneDescriptionLeftColumn drawInRect:CGRectMake(20, 145, 120, 160) withFont:[UIFont systemFontOfSize:10.0f]];
    [craneDescriptionResultsColumn drawInRect:CGRectMake(140, 120, 150, 120) withFont:[UIFont systemFontOfSize:10.0f]];
    [craneDescriptionRightColumn drawInRect:CGRectMake(300, 120, 120, 120) withFont:[UIFont systemFontOfSize:10.0f]];
    [craneDescriptionRightResultsColumn drawInRect:CGRectMake(410, 120, 120, 120) withFont:[UIFont systemFontOfSize:10.0f]];
    [operationalCheck drawInRect:CGRectMake(20, 220, 500, 30) withFont:[UIFont systemFontOfSize:10.0f]];
    [myWorkPerformed drawInRect:CGRectMake(20, 250, 500, 250) withFont:[UIFont systemFontOfSize:10.0f]];
    [miscInfo drawInRect:CGRectMake(20, 500, 500, 30) withFont:[UIFont systemFontOfSize:10.0f]];
    [myMaterialUsed drawInRect:CGRectMake(20, 530, 500, 50) withFont:[UIFont systemFontOfSize:10.0f]];
    [myMaterialOrdered drawInRect:CGRectMake(20, 580, 500, 100) withFont:[UIFont systemFontOfSize:10.0f]];
    //[conditionRatingString drawInRect:CGRectMake(20, 700, 600, 70) withFont:[UIFont systemFontOfSize:10.0f]];
    [footerLeft drawInRect:CGRectMake(300, 700, 600, 70) withFont:[UIFont systemFontOfSize:10.0f]];
    [footerRight drawInRect:CGRectMake(450, 700, 600, 70) withFont:[UIFont systemFontOfSize:10.0f]];
    // Clean up
    UIGraphicsPopContext();
    CGPDFContextEndPage(pdfContext);
    CGPDFContextClose(pdfContext);
    //release memory
    fileURL = nil;
    pdfContext = nil;
    myImage = nil;
    //conditionRatingString = nil;
    printString = nil;
    customerInfoResultsColumn = nil;
    craneDescriptionLeftColumn = nil;
    craneDescriptionResultsColumn = nil;
    craneDescriptionRightColumn = nil;
    craneDescriptionRightResultsColumn = nil;
    filePath = nil;
    footerLeft = nil;
    footerRight = nil;
    header = nil;
    myCraneDescription = nil;
    operationalCheck = nil;
    myWorkPerformed = nil; 
    miscInfo = nil;
    myMaterialUsed = nil;
    myMaterialOrdered = nil;
}

- (NSString *) isError
{
    //First we check to see if any of the fields in the customerInfo page and if there are any empty fields then the user is not allowed to submit the information and a UIAlertView pops
    //up telling you that there are fields where nothing was inserted into the fields
    if ([hoistSrl isEqualToString:@""] || 
        [techName isEqualToString:@""] || 
        [customerName isEqualToString:@""] ||
        [customerContact isEqualToString:@""] ||
        [jobNumber isEqualToString:@""] ||
        [date isEqualToString:@""] ||
        [customerAddress isEqualToString:@""] ||
        [email isEqualToString:@""] ||
        [equipNum isEqualToString:@""] ||
        [craneMfg isEqualToString:@""] ||
        [hoistMfg isEqualToString:@""] ||
        [hoistMdl isEqualToString:@""] ||
        [craneDescription isEqualToString:@""] ||
        [craneSrl isEqualToString:@""] ||
        [cap isEqualToString:@""])
    {
        errorExist = @"Some values are still empty on the Customer Info Page";
        return @"Some values are still empty on the Customer Info Page";
    }
    else if ([_txtHoistSrl.text isEqualToString:@""] || 
        [_txtTechName.text isEqualToString:@""] || 
        [_txtCustomerName.text isEqualToString:@""] ||
        [_txtCustomerContact.text isEqualToString:@""] ||
        [_txtJobNumber.text isEqualToString:@""] ||
        [_txtDate.text isEqualToString:@""] ||
        [_txtCustomerAddress.text isEqualToString:@""] ||
        [_txtEmail.text isEqualToString:@""] ||
        [_txtEquipNum.text isEqualToString:@""] ||
        [_txtCraneMfg.text isEqualToString:@""] ||
        [_txtHoistMfg.text isEqualToString:@""] ||
        [_txtHoistMdl.text isEqualToString:@""] ||
        [_txtCraneDescription.text isEqualToString:@""] ||
        [_txtCraneSrl.text isEqualToString:@""] ||
        [_txtCap.text isEqualToString:@""])
    {
        errorExist = @"Some values are still empty on the Customer Info Page";
        return @"Some values are still empty on the Customer Info Page";
    }
    //checks to see if there are any quotation marks inside of any of the fields, and if there are any then the user is not allowed to enter the customer, and a UIAlertView pops up
    //telling you that there are fields with quotations marks inside of it
    else if ((hoistSrl != NULL && [hoistSrl rangeOfString:@"\""].location != NSNotFound) || 
             (techName != NULL&&[techName rangeOfString:@"\""].location != NSNotFound) || 
             (customerName != NULL && [customerName rangeOfString:@"\""].location != NSNotFound) ||
             (customerContact != NULL &&[customerContact rangeOfString:@"\""].location != NSNotFound) ||
             (jobNumber != NULL &&[jobNumber rangeOfString:@"\""].location != NSNotFound) ||
             (date != NULL &&[date rangeOfString:@"\""].location != NSNotFound) ||
             (customerAddress != NULL &&[customerAddress rangeOfString:@"\""].location != NSNotFound) ||
             (email != NULL &&[email rangeOfString:@"\""].location != NSNotFound) ||
             (equipNum != NULL &&[equipNum rangeOfString:@"\""].location != NSNotFound) ||
             (craneMfg != NULL &&[craneMfg rangeOfString:@"\""].location != NSNotFound) ||
             (hoistMfg != NULL &&[hoistMfg rangeOfString:@"\""].location != NSNotFound) ||
             (hoistMdl != NULL &&[hoistMdl rangeOfString:@"\""].location != NSNotFound) ||
             (craneDescription != NULL &&[craneDescription rangeOfString:@"\""].location != NSNotFound) ||
             (craneSrl != NULL &&[craneSrl rangeOfString:@"\""].location != NSNotFound))
    {
        errorExist = @"Can not enter character 'quotations mark' ' \" ' into any customer fields!";
        return @"Can not enter character 'quotations mark' ' \" ' into any customer fields!";
    }
    else if ((_txtHoistSrl.text != NULL && [_txtHoistSrl.text rangeOfString:@"\""].location != NSNotFound) || 
             (_txtTechName.text != NULL && [_txtTechName.text rangeOfString:@"\""].location != NSNotFound) || 
             (_txtCustomerName.text != NULL && [_txtCustomerName.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtCustomerContact.text != NULL && [_txtCustomerContact.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtJobNumber.text != NULL && [_txtJobNumber.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtDate.text != NULL && [_txtDate.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtCustomerAddress.text != NULL && [_txtCustomerAddress.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtEmail.text != NULL && [_txtEmail.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtEquipNum.text != NULL && [_txtEquipNum.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtCraneMfg.text != NULL && [_txtCraneMfg.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtHoistMfg.text != NULL && [_txtHoistMfg.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtHoistMdl.text != NULL && [_txtHoistMdl.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtCraneDescription.text != NULL && [_txtCraneDescription.text rangeOfString:@"\""].location != NSNotFound) ||
             (_txtCraneSrl.text != NULL && [_txtCraneSrl.text rangeOfString:@"\""].location != NSNotFound))
    {
        errorExist = @"Can not enter character 'quotations mark' ' \" ' into any customer fields!";
        return @"Can not enter character 'quotations mark' ' \" ' into any customer fields!";
    }
    else {
        errorExist = @"NO";
        return  @"NO";
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) orientationChanged:(NSNotification *) notification
{
    [self changeOrientation];
}

-(void) changeOrientation
{
    UIInterfaceOrientation orientation = self.interfaceOrientation;
    
    currentOrientation = orientation;
}


#pragma mark - Split view
-(void)splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)aViewController
{
    aViewController.view.frame = CGRectMake(0, 0, 320, self.view.frame.size.height);
/*    
    [svc.view setNeedsLayout];
    svc.delegate = nil;
    svc.delegate = self;
    
    if ([self.splitViewController respondsToSelector:@selector(setPresentsWithGesture:)]) {
        [self.splitViewController setPresentsWithGesture:YES];
    }
 */
}

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Keyboard Methods

- (void) keyboardWasShown:(NSNotification *) notification
{
    NSDictionary *info = [notification userInfo];
    CGRect aRect = self.view.frame;
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    if ((currentOrientation==UIInterfaceOrientationLandscapeLeft) ||
        (currentOrientation==UIInterfaceOrientationLandscapeRight))
    {
        //Adjust the bottom content inset of your scroll view by the keyboard height
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.width, 0.0);
        //UIEdgeInsetsMake(<#CGFloat top#>, <#CGFloat left#>, <#CGFloat bottom#>, <#CGFloat right#>)
        _ScrollView.contentInset = contentInsets;
        _ScrollView.scrollIndicatorInsets = contentInsets;
        
        aRect.size.height -=keyboardSize.width;
        if (!CGRectContainsPoint(aRect, activeField.superview.frame.origin)) {
            CGPoint scrollPoint = CGPointMake(0.0, keyboardSize.width + activeField.superview.frame.size.height);
            [_ScrollView setContentOffset:scrollPoint animated:YES];
        }
    }
    else if ((currentOrientation==UIInterfaceOrientationPortrait) ||
             (currentOrientation==UIInterfaceOrientationPortraitUpsideDown))
        {
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
        _ScrollView.contentInset = contentInsets;
        _ScrollView.scrollIndicatorInsets = contentInsets;
        
        aRect.size.height -=keyboardSize.height;
        if (!CGRectContainsPoint(aRect, activeField.superview.frame.origin)) {
            CGPoint scrollPoint = CGPointMake(0.0, keyboardSize.height);
            [_ScrollView setContentOffset:scrollPoint animated:YES];
        }
    }
 
}
- (void) keyboardWillBeHidden:(NSNotification *) notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _ScrollView.contentInset = contentInsets;
    _ScrollView.scrollIndicatorInsets = contentInsets;
}
 
-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    if ([text rangeOfString:@"\n"].location != NSNotFound)
    {
        NSInteger nextTag = textView.tag + 1;
        UIResponder *nextResponder = [textView.superview.superview.superview viewWithTag:nextTag];
        
        if (nextResponder)
        {
            [nextResponder becomeFirstResponder];
            return NO;
        }
        else {
            [textView resignFirstResponder];
        }
    }
    return YES;
}

#pragma mark - Picker View Methods
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    //one column
    return 1;
}
- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //set item per row
    return opCheckArray.count;
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //set item per row
    return [opCheckArray objectAtIndex:row];
}

#pragma mark - Text Field Methods
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:[string uppercaseString]]; return NO;
}

@end
