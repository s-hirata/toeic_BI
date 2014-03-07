//
//  firstViewController.h
//  toeic_BI
//
//  Created by hirata on 2014/01/29.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDatabase.h"

 
@interface firstViewController : UIViewController <UITextFieldDelegate>
- (IBAction)btnTapped:(id)sender;

- (IBAction)bkgTapped:(id)sender;



- (IBAction)didEndOfjissikaiTextField:(id)sender;
- (IBAction)onSWchanged:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *syubetuTextField;
@property (weak, nonatomic) IBOutlet UISwitch *valOfSwitch;

@property (weak, nonatomic) IBOutlet UITextField *jissikaiTextField;

@property (nonatomic, retain) UIBarButtonItem *onTapDLButton;
@property (weak, nonatomic) IBOutlet UITextField *jissibiTextField;
@property (weak, nonatomic) IBOutlet UITextField *mokuhyouninzuTextField;
@property (weak, nonatomic) IBOutlet UITextField *mosikomiKikanTextField;

@property (weak, nonatomic) IBOutlet UITextField *zennenjissikaiTextField;

@property FMDatabase *db;

@end
