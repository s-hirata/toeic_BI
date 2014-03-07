//
//  profileViewController.h
//  toeic_BI
//
//  Created by hirata on 2014/03/03.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDatabase.h"
@interface profileViewController : UIViewController
@property FMDatabase *db;
- (IBAction)onBkgTapped:(id)sender;

@end
