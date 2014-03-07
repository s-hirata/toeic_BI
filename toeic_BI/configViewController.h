//
//  configViewController.h
//  
//
//  Created by hirata on 2014/02/06.
//
//

#import <UIKit/UIKit.h>

@interface configViewController : UIViewController
- (IBAction)swChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *valOfSwitch;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
- (IBAction)bkgTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
- (IBAction)dateSwChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UIDatePicker *workDayPicker;
- (IBAction)datePickerChandeg:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *tempDateLabel;

@end
