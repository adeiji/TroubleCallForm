//
//  JobNumberViewController.h
//  Trouble Call Form
//
//  Created by Developer on 5/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "MasterViewController.h"
#import <UIKit/UIKit.h>
#import "DateDisplayViewController.h"

@interface JobNumberViewController : UITableViewController <NSFetchedResultsControllerDelegate>
@property DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) DateDisplayViewController *DVController;
@property (strong, nonatomic) NSMutableArray *jobNumberArray;
@property (strong, retain) NSString *jobNumber;
@property (strong, retain) NSString *hoistSrl;
- (void) GetDates;
- (void) LoadMasterViewController: (MasterViewController *) input;
@end
