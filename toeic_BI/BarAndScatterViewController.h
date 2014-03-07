//
//  BarAndScatterViewController.h
//  toeic_BI
//
//  Created by hirata on 2014/01/24.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

//  TestCorePLot
//
//  Created by shojiro yanagisawa on 11/26/13.
//  Copyright (c) 2013 shojiro yanagisawa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "FMDatabase.h"


@interface BarAndScatterViewController : UIViewController<CPTPlotDataSource>{
    
    @private
    // グラフ表示領域（この領域に棒グラフを追加する）
    IBOutlet CPTGraphHostingView *hostingView;
    CPTXYGraph *graph;
    NSArray *plotData;
}

// 表示するデータを保持する配列
@property(nonatomic, strong) NSMutableArray *dataForBar;        // 棒グラフ用
@property(nonatomic, strong) NSMutableArray *dataForScatter;    // 折れ線グラフ用
@property(nonatomic, strong) NSMutableArray *Z_dataForScatter;    // 前年実施回の折れ線グラフ用
@property(nonatomic, strong) NSMutableArray *M_dataForScatter;    // 目標ライン用
@property (weak, nonatomic) IBOutlet UILabel *Z_todayOfSubview;
- (IBAction)onTapBtnOfSubview:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *uketukekikanOfSubview;
@property (weak, nonatomic) IBOutlet UILabel *ruikeiOfSubview;
@property (weak, nonatomic) IBOutlet UILabel *mokuhyouOfSubview;
@property (weak, nonatomic) IBOutlet UILabel *keikarituOfSubview;
@property (weak, nonatomic) IBOutlet UILabel *ZuketukekikanOfSubview;
@property (weak, nonatomic) IBOutlet UILabel *ZruikeiOfSubview;
@property (weak, nonatomic) IBOutlet UILabel *tassieiOfSubview;
@property (weak, nonatomic) IBOutlet UILabel *zennenhiOfSubview;



@end





