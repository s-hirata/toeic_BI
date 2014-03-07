//
//  setteiViewController.h
//  toeic_BI
//
//  Created by hirata on 2014/02/01.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDatabase.h"


@interface setteiViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property FMDatabase *db;



@end

