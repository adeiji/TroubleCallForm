//
//  DetailViewController.h
//  Trouble Call Form
//
//  Created by Developer on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MasterViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "GradientView.h"

@class DBRestClient;

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, UIPickerViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIDocumentInteractionControllerDelegate, DBRestClientDelegate, UITextViewDelegate, UIApplicationDelegate, UIAlertViewDelegate, RKRequestDelegate>
{
}

@property (strong, nonatomic) id detailItem;
@property (strong, retain) NSString *jobNumber;
@property (strong, retain) NSString *hoistSrl;
@property (strong, retain) NSString *date;
@property (strong, retain) NSString *customerName;
@property (strong, retain) NSString *email;
@property (strong, retain) NSString *equipNum;
@property (strong, retain) NSString *craneMfg;
@property (strong, retain) NSString *hoistMfg;
@property (strong, retain) NSString *hoistMdl;
@property (strong, retain) NSString *craneDescription;
@property (strong, retain) NSString *craneSrl;
@property (strong, retain) NSString *cap;
@property (strong, retain) NSString *techName;
@property (strong, retain) NSString *customerContact;
@property (strong, retain) NSString *customerAddress;
@property (strong, retain) NSString *opCheckSelection;
@property (strong, retain) NSString *materialOrdered;
@property (strong, retain) NSString *materialUsed;
@property (strong, retain) NSString *workPerformed;
@property (strong, retain) NSString *mfgMdl;
@property (strong, retain) NSString *ropeLength;
@property (strong, retain) NSString *chainLength;
@property (strong, retain) DetailViewController *CIVController;
@property (strong, retain) DetailViewController *CDVController;
@property (strong, nonatomic) NSString *errorExist;


@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIScrollView *ScrollView;
@property (strong, nonatomic) IBOutlet UIScrollView *DetailsScrollView;
@property (strong, nonatomic) IBOutlet UIPickerView *OpCheckPicker;
@property (strong, atomic) IBOutlet UITextField *txtHoistSrl;
@property (strong, nonatomic) IBOutlet UITextField *txtTechName;
@property (strong, nonatomic) IBOutlet UITextField *txtCustomerName;
@property (strong, nonatomic) IBOutlet UITextField *txtCustomerContact;
@property (strong, atomic) IBOutlet UITextField *txtJobNumber;
@property (strong, atomic) IBOutlet UITextField *txtDate;
@property (strong, nonatomic) IBOutlet UITextField *txtCustomerAddress;
@property (strong, nonatomic) IBOutlet UITextField *txtEmail;
@property (strong, nonatomic) IBOutlet UITextField *txtEquipNum;
@property (strong, nonatomic) IBOutlet UITextField *txtCraneMfg;
@property (strong, nonatomic) IBOutlet UITextField *txtHoistMfg;
@property (strong, nonatomic) IBOutlet UITextField *txtHoistMdl;
@property (strong, nonatomic) IBOutlet UITextField *txtCraneDescription;
@property (strong, nonatomic) IBOutlet UITextField *txtCraneSrl;
@property (strong, nonatomic) IBOutlet UITextField *txtCap;
@property (strong, nonatomic) IBOutlet UITextView *txtWorkPerformed;
@property (strong, nonatomic) IBOutlet UITextView *txtMaterialUsed;
@property (strong, nonatomic) IBOutlet UITextView *txtMaterialOrder;
@property (strong, nonatomic) IBOutlet UITextField *txtMfgMdl;
@property (strong, nonatomic) IBOutlet UITextField *txtChainLength;
@property (strong, nonatomic) IBOutlet UITextField *txtRopeLength;
@property (strong, nonatomic) IBOutlet UILabel *lblCraneDescription;
@property (strong, retain) IBOutlet GradientView *GView;

- (IBAction)TxtDateTouchUp:(id)sender;
- (IBAction)TroubleDetailsButtonPressed:(id)sender;
- (IBAction)NewCustomerButtonPressed:(id)sender;
- (IBAction)LoadHoistSrlPressed;
- (IBAction)textFieldDidBeginEditing:(UITextField *)sender;
- (IBAction)textFieldDidEndEditing:(UITextField *)sender; 
- (IBAction)NewCustomerButtonPressed:(id)sender;
- (IBAction)UpdateButtonPressed:(id)sender;
- (IBAction)SubmitButtonPressed:(id)sender;
- (IBAction)FinalSubmitButtonPressed:(id)sender;
- (IBAction)TroubleCallFormButtonPressed:(id)sender;
- (IBAction)ViewPDFButtonPressed:(id)sender;
- (IBAction)NewOrderButtonPressed:(id)sender;
- (void) EmptyOrderFormFields;
- (void) EmptyTextFields;

- (void) LoadMasterViewController : (MasterViewController *) input;

- (NSString *) isError;

- (void) FillCallForm   : (NSString *) opCheck
                        : (NSString *) workPerformed
                        : (NSString *) materialUsed
                        : (NSString *) materialOrdered
                        : (NSString *) mfgMdl
                        : (NSString *)chainLength
                        : (NSString *) ropeLength;

- (void) UpdateTextFields:(NSString *) hoistsrl
                         :(NSString *) custName
                         :(NSString *) contact
                         :(NSString *) address
                         :(NSString *) emailAddress
                         :(NSString *) equipNumber
                         :(NSString *) myCraneMfg
                         :(NSString *) myHoistMfg
                         :(NSString *) myHoistMdl
                         :(NSString *) myCraneDescription
                         :(NSString *) myCap
                         :(NSString *) myCraneSrl;
- (void) FillLocalVariables;
- (void) SetOpCheckSelection:(NSString *)myType;
@end
