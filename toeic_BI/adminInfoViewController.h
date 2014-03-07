//
//  adminInfoViewController.h
//  toeic_BI
//
//  Created by hirata on 2014/02/19.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDatabase.h"


@interface adminInfoViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property FMDatabase *db;


@end
