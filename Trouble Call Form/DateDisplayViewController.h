//
//  DateDisplayViewController.h
//  Trouble Call Form
//
//  Created by Developer on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;
#import "MasterViewController.h"
#import "DetailViewController.h"

@interface DateDisplayViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *dateArray;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, retain) NSString *hoistSrl;
@property (strong, retain) NSString *jobNumber;

- (void) LoadMasterViewController:(MasterViewController *) input;
- (void) GetDates;
@end
