//
//  adminDetailInfoViewController.h
//  toeic_BI
//
//  Created by hirata on 2014/02/20.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDatabase.h"


@interface adminDetailInfoViewController : UIViewController<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *jissibiTextField;
@property (weak, nonatomic) IBOutlet UITextField *mokuhyouTextField;
@property (weak, nonatomic) IBOutlet UITextField *zennenTextField;
@property (weak, nonatomic) IBOutlet UITextField *kaisibiTextField;
@property (weak, nonatomic) IBOutlet UITextField *simekiriTextField;
@property (weak, nonatomic) IBOutlet UITextField *syubetuTextField;
@property (weak, nonatomic) IBOutlet UITextField *jissikaiTextField;
- (IBAction)bkgTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIDatePicker *myDatepicker;
- (IBAction)dateChanged:(id)sender;
- (IBAction)doneTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *childView;
@property (weak, nonatomic) IBOutlet UIButton *myButton;

@property FMDatabase *db;

@end
