//
//  MasterViewController.h
//  Trouble Call Form
//
//  Created by Developer on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

@class DetailViewController;
@class JobNumberViewController;

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, RKRequestDelegate, UISearchBarDelegate, UISplitViewControllerDelegate>
{
    NSMutableArray *listOfItems;
    NSMutableArray *copyListOfItems;
    NSMutableArray *searchArray;
    IBOutlet UISearchBar *searchBar;
    BOOL searching;
    BOOL letUserSelectRow;
   // extern MasterViewController *MVController;
}

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) JobNumberViewController *JNVController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSMutableArray *hoistSrlArray;
@property (weak, nonatomic) IBOutlet UITableView *JobNumberVC;

- (IBAction)RefreshHoistSrlNumbers:(id)sender;
- (void) searchTableView;
- (void) doneSearching_Clicked:(id)sender;
- (void) UpdateHoistSrlArray:(NSString *)input;
- (void) GetHoistNumbers;
- (void) DeleteCrane:(NSString *) hoistSrl;
- (void) UpdateJobTables:(NSString *) myHoistSrl;
@end
