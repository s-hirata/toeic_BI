//
//  BarAndScatterViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/01/24.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

//
//  BarAndScatterViewController.m
//  TestCorePLot
//
//  Created by shojiro yanagisawa on 11/26/13.
//  Copyright (c) 2013 shojiro yanagisawa. All rights reserved.
//
//  変更履歴
//
//  2014-02-26 前年比を当日進捗比率に変更する
//

// バーを識別するための識別文字列
#define IDENTIFIER_BAR_PLOT     @"Bar Plot"     // 棒グラフ用
#define IDENTIFIER_SCATTER_PLOT @"Scatter Plot" // 折れ線グラフ用
#define IDENTIFIER_Z_SCATTER_PLOT @"Z_Scatter Plot" // 前年実施回の折れ線グラフ用

    #define CLMS 5
#define Time_start @"2010-01-01 23:59:59 +0900"
#define SYUBETU     0
#define JISSIKAI    1
#define KESSAIBI    2
#define NINZU       3
#define RUININZU    4
#define DATEFORMAT  @"yyyy/MM/dd"
#define DEVICE      @"Main_iPhone"
#define DBNAME      @"TOEIC.DB"


#import "BarAndScatterViewController.h"
#import "shareData.h"


@interface BarAndScatterViewController ()

@end

@implementation BarAndScatterViewController
NSMutableData *receivedData;
NSMutableArray *gData;      // 指定実施回のプロット用データ
NSInteger rec_count;        // 指定実施回のレコード数
NSMutableArray *Z_gData;    // 前年実施回のプロット用データ
NSInteger Z_rec_count;      // 前年実施回のレコード数
NSInteger max_rec_count;    // X軸の最大値
NSInteger com_y_min = (long)999999999;  // 日別件数最小値・・・使ってない
NSInteger com_y_max = (long)-1;         // 日別件数最大値・・・棒グラフの最大値
NSInteger com_ry_min = (long)999999999; // 累計最小値・・・使っていない
NSInteger com_ry_max = (long)-1;        // 累計最大値・・・折れ線グラフの最大値
NSInteger disp_ruininzu;                // タイトル部に表示する累計人数
NSDate *x_min_date ;        // 決済日の最小値・・・使っていない
NSDate *x_max_date;         // 決済日の最大値・・・使っていない
NSInteger mokuhyouNinzu = 0;    // 目標人数
float YB_INTVL = 5000.0;        // 棒グラフの軸間隔値・・・自動計算に変更した
float YS_INTVL = 10000.0;       // 折れ線グラフの軸間隔値・・・同上
NSInteger tickCountForBar = 4;  // 軸間隔計算用(定数)
NSInteger tickCountForScatter = 10; // 同上
NSInteger roundUnit = 0;        // 軸間隔丸め用　1000単位、100単位とか・・・
UIButton* chButton;             // 使っていない
int saisin_ry;                  //当日最新累計人数
int zennen_ry;                  //前年当日の累計人数
UIButton *stack_button;
UIView *stack_view;
float keikaritu;
int kaisibiBetweenToday;
int ZkaisibiBetweentoday;
int kaisiBetweenSimekiribi;
int kaisiBetweenSimekiribiZen;
NSString *z_uketukekikan;
NSString *Z_today;

UIToolbar * stack_toolbar;

- (FMDatabase*)_getDB:(NSString*)dbName {
	NSArray*  pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docdir = [pathArray objectAtIndex:0];
	NSString* dbpath = [docdir stringByAppendingPathComponent:dbName];
	FMDatabase* db = [FMDatabase databaseWithPath:dbpath];
    if (![db open]) {
        @throw [NSException exceptionWithName:@"DBOpenException" reason:@"couldn't open specified db file" userInfo:nil];
    }
    
    return db;
}


// 共有データ置き場へのポインタ
shareData* sharedData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // 共有データインスタンスを取得
        sharedData = [shareData instance];
        
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // ナビゲーションバー表示
}
-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // ナビゲーションバー非表示
}
-(void)viewDidAppear:(BOOL)animated{

    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        //Do your textField animation here
        int width=self.view.frame.size.width;
        int height=self.view.frame.size.height - 32;
        
        hostingView.frame = CGRectMake(0, 0, width,height);
        
        [self toolBargen];
        [ self.view addSubview:stack_toolbar ];

 
    }
    
    
}

-(void)toolBargen{
    //ツールバー
    UIToolbar * toolBar = [ [ UIToolbar alloc ] initWithFrame:CGRectMake( 0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44 ) ];
    [toolBar setAlpha:0.7];
    //   [ self.view addSubview:toolBar ];
    
    // ボタンを作成する
    
    UIButton* cfButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [cfButton addTarget:self
                 action:@selector(onTapUchiwakeButton:)
       forControlEvents:UIControlEventTouchUpInside];
    cfButton.frame = CGRectMake(10, 10, 60, 30);
    [cfButton setTitle:@"内訳" forState:UIControlStateNormal];
    UIBarButtonItem* cfButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cfButton];
    
    UIButton* lgButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [lgButton addTarget:self
                 action:@selector(onTapDetailButton:)
       forControlEvents:UIControlEventTouchUpInside];
    lgButton.frame = CGRectMake(10, 10, 60, 30);
    [lgButton setTitle:@"詳細" forState:UIControlStateNormal];
    UIBarButtonItem* lgButtonItem = [[UIBarButtonItem alloc] initWithCustomView:lgButton];
    
    // 可変間隔のスペーサーを作成する
    UIBarButtonItem * flexibleSpacer = [ [ UIBarButtonItem alloc ]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil
                                        action:nil ];
    
    toolBar.items = [ NSArray arrayWithObjects:
                     lgButtonItem,
                     flexibleSpacer,
                     cfButtonItem,
                     nil ];
    
    stack_toolbar = toolBar;
    

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self toolBargen];
    
    self.dataForScatter = [NSMutableArray array];
    self.Z_dataForScatter = [NSMutableArray array];
    self.M_dataForScatter = [NSMutableArray array];
    self.dataForBar = [NSMutableArray array];
    
    com_y_min = (long)999999999;
    com_y_max = (long)-1;
    com_ry_min = (long)999999999;
    com_ry_max = (long)-1;
    
    
    // 共有データからデータを読み出し
    
    NSString *text = [sharedData getDataForKey:@"ダウンロードデータ"];
    gData = [[NSMutableArray array] init];
    
    // 改行文字で区切って配列に格納する
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    rec_count = lines.count;
    
 //   NSLog(@"lines count: %ld", rec_count);    // 行数
    
    for (NSString *row in lines) {
        // コンマで区切って配列に格納する
        NSArray *items = [row componentsSeparatedByString:@","];
        
        // NSLog(@"item count %lu", (unsigned long)[items count]);  //debug
        
        if( CLMS <= [items count] ){
            
            NSArray *ar = [NSArray arrayWithObjects:[items objectAtIndex:SYUBETU], // 試験種別
                           [items objectAtIndex:JISSIKAI],                         // 実施回
                           [items objectAtIndex:KESSAIBI],                         // 決済日
                           [items objectAtIndex:NINZU],                         // 当日申込人数
                           [items objectAtIndex:RUININZU],nil];                    // 当日迄累計人数
            
            [ gData addObject:ar ] ;
        }
        
    }

    
    NSString *Ztext = [sharedData getDataForKey:@"前年実施回データ"];
    Z_gData = [[NSMutableArray array] init];
    
    // 改行文字で区切って配列に格納する
    lines = [Ztext componentsSeparatedByString:@"\n"];
    Z_rec_count = lines.count;
    
  //  NSLog(@"Z_lines count: %ld", (long)Z_rec_count);    // 行数
    
    for (NSString *row in lines) {
        // コンマで区切って配列に格納する
        NSArray *items = [row componentsSeparatedByString:@","];
        
        // NSLog(@"item count %lu", (unsigned long)[items count]);  //debug
        
        if( CLMS <= [items count] ){
            
            NSArray *ar = [NSArray arrayWithObjects:[items objectAtIndex:SYUBETU], // 試験種別
                           [items objectAtIndex:JISSIKAI],                         // 実施回
                           [items objectAtIndex:KESSAIBI],                         // 決済日
                           [items objectAtIndex:NINZU],                         // 当日申込人数
                           [items objectAtIndex:RUININZU],nil];                    // 当日迄累計人数
            
            [ Z_gData addObject:ar ] ;
        }
        
    }
    
    max_rec_count = rec_count;
    if(rec_count < Z_rec_count){
        max_rec_count = Z_rec_count;   // 大きい方をX軸の個数とする
    }
    
    [self max_valSet];         // 軸の値設定の為の最大値取得
    
    [self gValueSetting];  // グラフデータの設定
    
    if ([self Z_gValueSetting] == YES){    // 前年実施回のグラフデータの設定
        [self generateGraph];   // 指定した実施回のグラフ作成
        [self Z_generateGraph]; // 前年実施回のグラフ作成
    } else {
        [self generateGraph];   // 指定した実施回のグラフ作成
    }
    

 }


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Plot Data Source Methods

// プロットするためのレコード数を返す(通常はX軸の数を返す)
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    // 棒グラフの場合
    if ( [plot isKindOfClass:[CPTBarPlot class]] ) {
        return [self.dataForBar count];
    } // 折れ線グラフの場合
    else if ( [plot isKindOfClass:[CPTScatterPlot class]] ) {
        if ([plot.identifier isEqual:IDENTIFIER_SCATTER_PLOT]) {
            return [self.dataForScatter count];
        } else if ([plot.identifier isEqual:IDENTIFIER_Z_SCATTER_PLOT]) {
            return [self.Z_dataForScatter count];
        }
    }
    return 0;
}

// プロットするデータを返す(X軸とY軸を返す)
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = nil;
    
    // 棒グラフの場合
    if ( [plot isKindOfClass:[CPTBarPlot class]] ) {
        if ([plot.identifier isEqual:IDENTIFIER_BAR_PLOT]) {
            switch ( fieldEnum ) {
                    //X軸のラベル
                case CPTBarPlotFieldBarLocation:
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
                    break;
                    //棒の高さを指定(Y軸)
                case CPTBarPlotFieldBarTip:
                    num = [self.dataForBar objectAtIndex:index];
                    break;
            }
        }
    } // 折れ線グラフの場合
    else if ( [plot isKindOfClass:[CPTScatterPlot class]] ) {
        if ([plot.identifier isEqual:IDENTIFIER_SCATTER_PLOT]) {
            switch (fieldEnum) {
                case CPTScatterPlotFieldX:  // X軸の値
                    num = [[self.dataForScatter objectAtIndex:index] valueForKey:@"x"];
                    break;
                case CPTScatterPlotFieldY:  // Y軸の値
                    num = [[self.dataForScatter objectAtIndex:index] valueForKey:@"y"];
                    break;
            }
        } else if ([plot.identifier isEqual:IDENTIFIER_Z_SCATTER_PLOT]) {
            switch (fieldEnum) {
                case CPTScatterPlotFieldX:  // X軸の値
                    num = [[self.Z_dataForScatter objectAtIndex:index] valueForKey:@"x"];
                    break;
                case CPTScatterPlotFieldY:  // Y軸の値
                    num = [[self.Z_dataForScatter objectAtIndex:index] valueForKey:@"y"];
                    break;
            }
        }
    }
    return num;
}

- (void)onTapBkButton:(id)sender {
    
    //　戻るボタン
    
    [sharedData setData:@"BarAndScatterViewController" forKey:@"遷移元"];

    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)onTapDoneButton:(id)sender {
    
    //　戻るボタン
    for (UIView *view in [self.view subviews]) {
        if ([view isKindOfClass:[UIView class]]){
            if (view.tag == 1){
                view.hidden = YES;
            }
        }
    }
    UIColor *myColor = [UIColor colorWithRed:(255.0 / 255.0) green:(255.0 / 255.0) blue:(255.0 / 255.0) alpha: 1.0];
    [self.view setBackgroundColor:myColor  ];
    
    UIButton* cfButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [cfButton addTarget:self
                 action:@selector(onTapUchiwakeButton:)
       forControlEvents:UIControlEventTouchUpInside];
    cfButton.frame = CGRectMake(10, 10, 60, 30);
    [cfButton setTitle:@"内訳" forState:UIControlStateNormal];
    UIBarButtonItem* cfButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cfButton];
    
    UIButton* lgButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [lgButton addTarget:self
                 action:@selector(onTapDetailButton:)
       forControlEvents:UIControlEventTouchUpInside];
    lgButton.frame = CGRectMake(10, 10, 60, 30);
    [lgButton setTitle:@"詳細" forState:UIControlStateNormal];
    UIBarButtonItem* lgButtonItem = [[UIBarButtonItem alloc] initWithCustomView:lgButton];
    
    // 可変間隔のスペーサーを作成する
    UIBarButtonItem * flexibleSpacer = [ [ UIBarButtonItem alloc ]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil
                                        action:nil ];
    
    stack_toolbar.items = [ NSArray arrayWithObjects:
                     lgButtonItem,
                     flexibleSpacer,
                     cfButtonItem,
                     nil ];
    
    [ self.view addSubview:stack_toolbar ];

    
    
}

-(void)onTapUchiwakeButton:(id)sender{
    
    [sharedData setData:@"BarAndScatterViewController" forKey:@"遷移元"];
    
    [self performSegueWithIdentifier:@"goKessaiViewController" sender:self];

    
}
- (void)onTapDetailButton:(id)sender {
    
    //　詳細ボタン
    
 
   for (UIView *view in [self.view subviews]) {
        if ([view isKindOfClass:[UIView class]]){
           if (view.tag == 1){
                view.hidden = NO ;
                UIColor *myColor = [UIColor colorWithRed:(248.0 / 255.0) green:(248.0 / 255.0) blue:(255.0 / 255.0) alpha: 0.78];
                [self.view setBackgroundColor:myColor  ];
                view.hidden = NO ;
                myColor = [UIColor colorWithRed:(255.0 / 255.0) green:(255.0 / 255.0) blue:(255.0 / 255.0) alpha: 1.0];
                [view setBackgroundColor:myColor  ];

                
                _uketukekikanOfSubview.text = [NSString stringWithFormat:@"%@(%d日間)",[sharedData getDataForKey:@"受付期間"], kaisiBetweenSimekiribi];
                _ruikeiOfSubview.text = [NSString stringWithFormat:@"%d人",saisin_ry];
                _mokuhyouOfSubview.text = [NSString stringWithFormat:@"%ld人",(long)mokuhyouNinzu
                                           ];
                _keikarituOfSubview.text = [NSString stringWithFormat:@"経過日数%d日(%ld％)",kaisibiBetweenToday,(long)keikaritu
                                            ];
                _ZuketukekikanOfSubview.text = [NSString stringWithFormat:@"%@(%d日間)",z_uketukekikan, kaisiBetweenSimekiribiZen];
                _Z_todayOfSubview.text= Z_today;
                _ZruikeiOfSubview.text = [NSString stringWithFormat:@"%d人",zennen_ry];
                if(mokuhyouNinzu > 0) {
                    NSString *mg1 = [NSString stringWithFormat:@"%3.0f％",round(saisin_ry*100/mokuhyouNinzu)];
                    _tassieiOfSubview.text = mg1;
                } else {
                    _tassieiOfSubview.text = @"--";
                }
                if(zennen_ry > 0) {
                    NSString *mg1 = [NSString stringWithFormat:@"%3.0f％",round(saisin_ry*100/zennen_ry)];
                    _zennenhiOfSubview.text =mg1;
                } else {
                    _zennenhiOfSubview.text = @"--";
                }
                stack_view = view;
                [self.view addSubview:view];
            }
       }
    }
    
    
    UIButton* cfButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [cfButton addTarget:self
                 action:@selector(onTapUchiwakeButton:)
       forControlEvents:UIControlEventTouchUpInside];
    cfButton.frame = CGRectMake(10, 10, 60, 30);
    [cfButton setTitle:@"内訳" forState:UIControlStateNormal];
    UIBarButtonItem* cfButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cfButton];
    
    UIButton* lgButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [lgButton addTarget:self
                 action:@selector(onTapDoneButton:)
       forControlEvents:UIControlEventTouchUpInside];
    lgButton.frame = CGRectMake(10, 10, 60, 30);
    [lgButton setTitle:@"Done" forState:UIControlStateNormal];
    UIBarButtonItem* lgButtonItem = [[UIBarButtonItem alloc] initWithCustomView:lgButton];

    
    // 可変間隔のスペーサーを作成する
    UIBarButtonItem * flexibleSpacer = [ [ UIBarButtonItem alloc ]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil
                                        action:nil ];
    
    stack_toolbar.items = [ NSArray arrayWithObjects:
                           lgButtonItem,
                           flexibleSpacer,
                           cfButtonItem,
                           nil ];
    
    [ self.view addSubview:stack_toolbar ];
    

    
    
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // ユーザがタッチした座標を取得
    CGPoint point = [((UITouch*)[touches anyObject])locationInView:self.view];
    
    // スタンプを表示するViewのサイズや大きさを調整
    stack_view.frame = CGRectMake(point.x - stack_view.frame.size.width/2 ,
                                             point.y - stack_view.frame.size.height/2,
                                             stack_view.frame.size.width,
                                             stack_view.frame.size.height);
    [self.view addSubview:stack_view];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // ユーザがドラッグした座標を取得
    CGPoint point = [((UITouch*)[touches anyObject])locationInView:stack_view];
    
    // ドラッグ中の座標を使って移動
    stack_view.transform = CGAffineTransformMakeTranslation(point.x - stack_view.center.x ,
                                                                       point.y - stack_view.center.y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // ユーザがドラッグを終了した座標を取得
    CGPoint point = [((UITouch*)[touches anyObject])locationInView:self.view];
    
    // 今回はstampUIImageViewをプロパティとして持っていたので、それを別のViewに移す
    // はじめに配列を用意して、そこへどんどんViewを追加していき、スタンプが貼り付けられるViewでは常に一番新しいViewだけを今までの処理で使うのも良いかもしれない
    // 配列を用いた方が最後にすべて重ねあわせて一枚の画像にする際にもforで回せるため便利かもしれない
    UIView *touchEndView = [[UIView alloc] init];
    touchEndView = stack_view;
    touchEndView.frame = stack_view.frame;
    [self.view addSubview:stack_view];
    
    // いらなくなったViewをリムーブ
  //  [stack_view removeFromSuperview];
}
-(void)generateGraph
{
    
    // -----------------------------------------
    // グラフの基本的な設定
    // -----------------------------------------
    // ホスティングビューを生成
    //hostingView = [[CPTGraphHostingView alloc] initWithFrame:self.view.bounds];

    int width=self.view.frame.size.width;
    int height=self.view.frame.size.height - 44;
    hostingView=   [[CPTGraphHostingView alloc] initWithFrame:CGRectMake(0, 0, width,height)];

    //hostingView=   [[CPTGraphHostingView alloc] initWithFrame:CGRectMake(0, 0, 160, 160)];
    // 画面にホスティングビューを追加
    
    [self.view addSubview:hostingView];
    
    // グラフを生成
    graph = [[CPTXYGraph alloc] initWithFrame:hostingView.bounds];
  //  graph = [[CPTXYGraph alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    
    hostingView.hostedGraph = graph;
    
    // 共有データからデータを読み出し
    NSString* syubetu = [sharedData getDataForKey:@"試験種別"];
    NSString* jissikai = [sharedData getDataForKey:@"実施回"];
    NSDate* m_date = [sharedData getDataForKey:@"データ取得日時"]; // <-- NSDate *genDate = attr.fileCreationDate;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"MM/dd HH:mm";
    NSString *str = [df stringFromDate:m_date];
    NSString *mg = [NSString stringWithFormat:@"  %d人(%@取得)", (int)disp_ruininzu, str];
    NSString *lineOne  = [  syubetu stringByAppendingString:jissikai];
    lineOne  = [  lineOne stringByAppendingString:mg];  // LR188(2014/02/05取得)
    if(mokuhyouNinzu > 0) {
        NSString *mg1 = [NSString stringWithFormat:@"\n目標:%d人(達成%3.0f",(int)mokuhyouNinzu ,round(saisin_ry*100/mokuhyouNinzu)];
        lineOne  = [  lineOne stringByAppendingString:mg1];

        if(zennen_ry > 0) {
            NSString *mg1 = [NSString stringWithFormat:@"%3.0f",round(saisin_ry*100/zennen_ry)];
            mg = [NSString stringWithFormat:@",前年%@)", mg1];
            lineOne  = [  lineOne stringByAppendingString:mg];
        } else {
            lineOne  = [  lineOne stringByAppendingString:@")"];
        }
    }
    mg = [sharedData getDataForKey:@"実施日"];
    mg = [mg substringFromIndex:5];
    mg = [NSString stringWithFormat:@"\n実施日%@(受付%@)",mg,[sharedData getDataForKey:@"受付期間"]];
    lineOne  = [  lineOne stringByAppendingString:mg];
     // Graph title
    
    NSMutableAttributedString *graphTitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", lineOne]];


    graph.attributedTitle = graphTitle;
    graph.titleDisplacement        = CGPointMake(10.0, -30.0);
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;

    //戻るボタンの作成
    
    UIButton* bkButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [bkButton addTarget:self
                 action:@selector(onTapBkButton:)
       forControlEvents:UIControlEventTouchUpInside];
    bkButton.frame = CGRectMake(0, 23, 50, 30);
    [bkButton setTitle:@"戻る" forState:UIControlStateNormal];
    [self.view addSubview:bkButton];
  
    [ self.view addSubview:stack_toolbar ];

    // グラフのボーダー設定
    graph.plotAreaFrame.borderLineStyle = nil;
    graph.plotAreaFrame.cornerRadius    = 0.0f;
    graph.plotAreaFrame.masksToBorder   = NO;
    
    // パディング
    graph.paddingLeft   = 0.0f;
    graph.paddingRight  = 0.0f;
    graph.paddingTop    = 0.0f;
    graph.paddingBottom = 0.0f;
    graph.plotAreaFrame.paddingLeft   = 60.0f;
    graph.plotAreaFrame.paddingTop    = 60.0f;
    graph.plotAreaFrame.paddingRight  = 50.0f;
    graph.plotAreaFrame.paddingBottom = 60.0f;
    
    
    // -----------------------------------------
    // プロットスペース(グラフを記載するスペース)
    // -----------------------------------------
    //デフォルトのプロット間隔の設定。棒グラフを表示させる。
    CPTXYPlotSpace *defaultPlotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
  
    //X軸はデータの個数
    defaultPlotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0)
        length:CPTDecimalFromInt(max_rec_count)];


    //Y軸は当日申込人数の最小値から最大値を設定
    defaultPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(com_y_max + YB_INTVL )];
    
    //[graph addPlotSpace:defaultPlotSpace];
    
    // 折れ線グラフ用のプロットスペース
	CPTXYPlotSpace *scatterPlotSpace = [[CPTXYPlotSpace alloc] init];

    //X軸はデータの個数
	scatterPlotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(0) length:CPTDecimalFromUnsignedInteger(max_rec_count)];

    //Y軸は累計人数
	scatterPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(com_ry_max + YS_INTVL )];
 
    // グラフに折れ線グラフ用のプロットスペースを設定する
	[graph addPlotSpace:scatterPlotSpace];
    
    
    // -----------------------------------------
    // スタイルの宣言(あとからグラフのメモリやグラフ自体に設定する)
    // -----------------------------------------
    // テキストスタイル
    CPTMutableTextStyle *textStyle = [CPTTextStyle textStyle];
    textStyle.color                = [CPTColor colorWithComponentRed:0.447f green:0.443f blue:0.443f alpha:1.0f];
    textStyle.fontSize             = 11.0f;
    textStyle.textAlignment        = CPTTextAlignmentCenter;
    
    // ラインスタイル
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineColor            = [CPTColor colorWithComponentRed:0.788f green:0.792f blue:0.792f alpha:1.0f];
    lineStyle.lineWidth            = 2.0f;
    
    // 折れ線グラフ用のラインスタイル
    CPTMutableLineStyle *lineStyleForScatter = [CPTMutableLineStyle lineStyle];
    lineStyleForScatter.lineColor  = [CPTColor colorWithComponentRed:0.780f green:0.50f blue:0.531f alpha:0.50f];
    lineStyleForScatter.lineWidth  = 3.0f;  // original=2.0
 //   lineStyleForScatter.dashPattern =  nil;
    
    // -----------------------------------------
    // X軸とY軸のメモリ・ラベルなどの設定
    // -----------------------------------------
    // X軸のメモリ・ラベルなどの設定
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.axisLineStyle               = lineStyle;      // X軸の線にラインスタイルを適用
    x.majorTickLineStyle          = lineStyle;      // X軸の大きいメモリにラインスタイルを適用
    x.minorTickLineStyle          = lineStyle;      // X軸の小さいメモリにラインスタイルを適用
    x.majorIntervalLength         = CPTDecimalFromString(@"2"); // X軸ラベルの表示間隔
    x.orthogonalCoordinateDecimal = CPTDecimalFromInt(0.0); // X軸のY位置
 //   x.title                       = @"共通のX軸";    // X軸のタイトル
    x.titleTextStyle = textStyle;                   // X軸のテキストスタイルの設定
    x.titleLocation               = CPTDecimalFromFloat(5.0f);
    x.titleOffset                 = 30.0f;
    x.minorTickLength = 5.0f;                   // X軸のメモリの長さ ラベルを設定しているため無効ぽい
    x.majorTickLength = 9.0f;                   // X軸のメモリの長さ ラベルを設定しているため無効ぽい
 //   timeFormatter.referenceDate = x_min_date;
   // x.labelFormatter            = timeFormatter;
    
    x.labelTextStyle = textStyle;
    
    [self arbitraryLabels];  // X軸に日付を設定
    
    // Y軸のメモリ・ラベルなどの設定
    CPTXYAxis *y = axisSet.yAxis;
    y.axisLineStyle               = lineStyle;      // Y軸の線にラインスタイルを適用
    y.majorTickLineStyle          = lineStyle;      // Y軸の大きいメモリにラインスタイルを適用
    y.minorTickLineStyle          = lineStyle;      // Y軸の小さいメモリにラインスタイルを適用
    y.majorTickLength = 9.0f;                   // Y軸の大きいメモリの長さ
    y.minorTickLength = 5.0f;                   // Y軸の小さいメモリの長さ
    y.majorIntervalLength         = CPTDecimalFromFloat(YB_INTVL);  // Y軸ラベルの表示間隔  1-->1000
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0.0f);  // Y軸のX位置
    y.title                       = @"当日";   // Y軸のタイトル
    y.titleTextStyle = textStyle;                   // Y軸のテキストスタイルの設定
    y.titleRotation = M_PI * 2;
    y.titleLocation               = CPTDecimalFromFloat(0.0f);
    y.titleOffset                 = 30.0f;  //30
    lineStyle.lineWidth = 0.5f;
    y.majorGridLineStyle = lineStyle;
    y.labelTextStyle = textStyle;
    
	// 折れ線グラフ用のY軸の設定
    CPTXYAxis *scatterY = [[CPTXYAxis alloc] init];
    scatterY.plotSpace = scatterPlotSpace;      // 折れ線グラフ用のプロットスペースを設定
	scatterY.coordinate = CPTCoordinateY;       // 軸をY軸に設定
    scatterY.labelOffset = -55.0f;              // ラベルの表示位置をオフセット値で設定  -60
    scatterY.axisLineStyle               = lineStyleForScatter;      // Y軸の線にラインスタイルを適用
    scatterY.majorTickLineStyle          = lineStyleForScatter;      // Y軸の大きいメモリにラインスタイルを適用
    scatterY.minorTickLineStyle          = lineStyleForScatter;      // Y軸の小さいメモリにラインスタイルを適用
    scatterY.majorTickLength = 9.0f;                   // Y軸の大きいメモリの長さ
    scatterY.minorTickLength = 5.0f;                   // Y軸の小さいメモリの長さ
//    scatterY.majorIntervalLength         = CPTDecimalFromFloat(500.0f);  // Y軸ラベルの表示間隔
    scatterY.majorIntervalLength         = CPTDecimalFromFloat(YS_INTVL);  // Y軸ラベルの表示間隔
    scatterY.orthogonalCoordinateDecimal = CPTDecimalFromInt(max_rec_count);  // Y軸のX位置
    scatterY.title                       = @"累計";   // 折れ線グラフ用のY軸のタイトル
    scatterY.titleTextStyle = textStyle;                       // 折れ線グラフ用のY軸のテキストスタイルの設定
    scatterY.titleRotation = M_PI * 2;
    scatterY.titleLocation               = CPTDecimalFromFloat(0.0f);
    scatterY.titleOffset                 = -25.0f;    //
    
    // Axis配列をGraphに登録
	graph.axisSet.axes = [NSArray arrayWithObjects:x, y, scatterY, nil];
    
    
    // -----------------------------------------
    // 棒グラフの作成と設定
    // -----------------------------------------
    // 棒グラフの作成
    // horizontalBars:BOOL => YESの場合、横棒グラフ。NOの場合、縦棒グラフ。
    CPTBarPlot *barPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor colorWithComponentRed:1.0f green:1.0f blue:0.88f alpha:1.0f] horizontalBars:NO];
    barPlot.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.573f green:0.82f blue:0.831f alpha:0.50f]]; // バーの色を設定。上記のカラーが上塗りされる。
//     barPlot.fill = [CPTFill fillWithColor:[CPTColor blueColor]]; // バーの色を設定。上記のカラーが上塗りされる。
 
    barPlot.identifier = IDENTIFIER_BAR_PLOT;           // 棒グラフの識別子を設定
    barPlot.lineStyle = lineStyle;                      // ラインスタイルを設定
    barPlot.barBasesVary = NO;
    barPlot.baseValue  = CPTDecimalFromString(@"0");    // グラフのベースの値を設定
    barPlot.dataSource = self;                          // データソースを設定
    barPlot.delegate = self;
    barPlot.barWidth = CPTDecimalFromFloat(0.3f);       // 各棒の幅を設定
    barPlot.barOffset  = CPTDecimalFromFloat(0.2f);     // 各棒の横軸からのオフセット値を設定
    [graph addPlot:barPlot toPlotSpace:defaultPlotSpace];   // 棒グラフ用プロットスペースに棒グラフを追加
    
    // -----------------------------------------
    // 折れ線グラフの作成と設定
    // -----------------------------------------
    // 折れ線グラフのインスタンスを生成
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] init];
    scatterPlot.identifier      = IDENTIFIER_SCATTER_PLOT;      // 折れ線グラフを識別するために識別子を設定
    scatterPlot.dataSource      = self;                         // 折れ線グラフのデータソースを設定
    scatterPlot.dataLineStyle = lineStyleForScatter;            // スタイルを設定
    
    [graph addPlot:scatterPlot toPlotSpace:scatterPlotSpace];   // 折れ線グラフ用プロットスペースに折れ線グラフを追加
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
    
   // return YES;
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
    int width=self.view.frame.size.width;
    int height=self.view.frame.size.height - 32;
    
    hostingView.frame = CGRectMake(0, 0, width,height);
    


   
}
- (void) arbitraryLabels{       // 決済日をX軸に設定する
    
    // 日付表示の数が20以上なら2日ごとに表示する
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    NSMutableArray *labels = [NSMutableArray arrayWithCapacity:rec_count];
    CPTMutableTextStyle *textStyle = [CPTTextStyle textStyle];


    x.labelTextStyle = textStyle;

    
    NSDate *inputDate = [[NSDate alloc]init];
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
    [inputDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
    inputDateFormatter.dateFormat =  DATEFORMAT;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
    df.dateFormat  = @"MM/dd";
    
    NSArray* langs = [NSLocale preferredLanguages];
    NSString* lang = [langs objectAtIndex:0];
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] ;
    
    NSString *sw = [sharedData getDataForKey:@"前年日付表示"];
    if(([sw isEqualToString:@"ON"])
        && (Z_rec_count > 0)
        && (Z_rec_count > rec_count) ){
        
        int idx = 0;
        
        for( NSMutableArray *v in Z_gData ){  //前年日付表示
            if((Z_rec_count > 20) && (idx % 2)){
                ++idx;
                continue;
            }
            NSArray *w = v;
            NSString *inputDateStr = (NSString *)[w objectAtIndex:KESSAIBI];  // 決済日
            inputDate = [inputDateFormatter dateFromString:inputDateStr];
            NSString *str = [df stringFromDate:inputDate];
            
            NSDateComponents *comp = [calendar components:NSWeekdayCalendarUnit fromDate:inputDate];
            NSInteger weekday = comp.weekday;
            NSString* strS = [self getWeekDay:lang weekday:weekday isShort:true];
            str=[NSString stringWithFormat:@"%@(%@)",str,strS];

            textStyle.color                = [CPTColor colorWithComponentRed:0.447f green:0.443f blue:0.443f alpha:1.0f];
            x.labelTextStyle = textStyle;
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:str
                                                           textStyle:axisSet.xAxis.labelTextStyle];
            label.tickLocation = CPTDecimalFromInt(idx); // ラベルを追加するレコードの位置
            label.offset = 5.0f; // 軸からラベルまでの距離
            label.rotation = M_PI * 0.45 ;    // 斜めに立てて表示する
            
            [labels addObject:label];
            
            ++idx;
            
        }

    } else {
        int idx = 0;
        
        for(NSMutableArray *v in gData ){  //当年日付表示
            if((rec_count > 20) && (idx % 2)){
                ++idx;
                continue;
            }

            NSArray *w = v;
            NSString *inputDateStr = (NSString *)[w objectAtIndex:KESSAIBI];  // 決済日
            inputDate = [inputDateFormatter dateFromString:inputDateStr];
            NSString *str = [df stringFromDate:inputDate];
            
            NSDateComponents *comp = [calendar components:NSWeekdayCalendarUnit fromDate:inputDate];
            NSInteger weekday = comp.weekday;
            NSString* strS = [self getWeekDay:lang weekday:weekday isShort:true];
            str=[NSString stringWithFormat:@"%@(%@)",str,strS];
            
            textStyle.color                = [CPTColor colorWithComponentRed:0.780f green:0.50f blue:0.531f alpha:1.0f];
            x.labelTextStyle = textStyle;
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:str
                                                       textStyle:axisSet.xAxis.labelTextStyle];
            label.tickLocation = CPTDecimalFromInt(idx); // ラベルを追加するレコードの位置
            label.offset = 5.0f; // 軸からラベルまでの距離
            label.rotation = M_PI * 0.45 ;    // 斜めに立てて表示する
            [labels addObject:label];
        
            ++idx;
        }
    }
    
    
    // X軸に設定
    
    axisSet.xAxis.axisLabels = [NSSet setWithArray:labels];
    
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyNone; // これ重要
    
}
-(NSString*) getWeekDay:(NSString*)lang weekday:(int)weekday isShort:(Boolean)isShort {
    NSString* rc;
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setLocale:[[NSLocale alloc] initWithLocaleIdentifier:lang]];
    
    if (isShort) {
        rc = [[fmt shortWeekdaySymbols] objectAtIndex:weekday - 1];
    } else {
        rc = [[fmt weekdaySymbols] objectAtIndex:weekday - 1];
    }
    
    return rc;
}

-(void)Z_generateGraph
{
    
    // 前年実施回のデータからグラフを作成しオーバレイする
    
    // 棒グラフは不要
    
    // 折れ線グラフ用のプロットスペース
	CPTXYPlotSpace *Z_scatterPlotSpace = [[CPTXYPlotSpace alloc] init];
    
    //X軸はデータの個数
	Z_scatterPlotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(0) length:CPTDecimalFromUnsignedInteger(max_rec_count)];
    
    //Y軸は累計人数
	Z_scatterPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(com_ry_max + YS_INTVL )];
    
    // グラフに折れ線グラフ用のプロットスペースを設定する
	[graph addPlotSpace:Z_scatterPlotSpace];
    
    // 折れ線グラフ用のラインスタイル
    CPTMutableLineStyle *Z_lineStyleForScatter = [CPTMutableLineStyle lineStyle];
//    Z_lineStyleForScatter.lineColor  = [CPTColor  colorWithComponentRed:0.780f green:0.50f blue:0.531f alpha:0.50f];
 
    Z_lineStyleForScatter.lineColor  = [CPTColor  colorWithComponentRed:0.50f green:0.50f blue:0.50f alpha:0.50f];
    Z_lineStyleForScatter.lineWidth  = 3.0f;
    Z_lineStyleForScatter.dashPattern =  @[@5.0f, @5.0f]; // [実線のピクセル数, 実線間のピクセル数]
    

    // -----------------------------------------
    // 折れ線グラフの作成と設定
    // -----------------------------------------
    // 折れ線グラフのインスタンスを生成
    CPTScatterPlot *Z_scatterPlot = [[CPTScatterPlot alloc] init];
    Z_scatterPlot.identifier      = IDENTIFIER_Z_SCATTER_PLOT;      // 前年実施回の折れ線グラフを識別するために識別子を設定
    Z_scatterPlot.dataSource      = self;                         // 折れ線グラフのデータソースを設定
    Z_scatterPlot.dataLineStyle = Z_lineStyleForScatter;            // スタイルを設定
    [graph addPlot:Z_scatterPlot toPlotSpace:Z_scatterPlotSpace];   // 折れ線グラフ用プロットスペースに折れ線グラフを追加
}


-(void)max_valSet{
    
    // 軸の値設定のための最大値等の取得
    
    x_min_date = [[NSDate alloc] initWithTimeIntervalSinceNow: -100000.0];
    x_max_date = [[NSDate alloc] initWithTimeIntervalSince1970: 0.0];
    NSDate *inputDate = [[NSDate alloc]init];
    NSDate *outputDate = [[NSDate alloc]init];
    
    NSInteger y_min = (long)999999999;
    NSInteger y_max = (long)-1;
    NSInteger ry_min = (long)999999999;
    NSInteger ry_max = (long)0;
    
    
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
    [inputDateFormatter setDateFormat:DATEFORMAT];
    [inputDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc] init];
    NSString *outputDateFormatterStr = @"yyyy/mm/dd(EEE)";
    [outputDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
    [outputDateFormatter setDateFormat:outputDateFormatterStr];
    
    for( NSMutableArray *v in gData){
        NSArray *w = v;
        
        NSString *inputDateStr = (NSString *)[w objectAtIndex:KESSAIBI];   // 決済日
        NSString *ninzuStr = (NSString *)[w objectAtIndex:NINZU];          // 当日申込人数
        NSString *ruininzuStr = (NSString *)[w objectAtIndex:RUININZU];    // 累計申込人数
        NSInteger ninzu = ninzuStr.integerValue;
        NSInteger ruininzu = ruininzuStr.integerValue;
        
        inputDate = [inputDateFormatter dateFromString:inputDateStr];
        outputDate = [outputDateFormatter dateFromString:inputDateStr];
        
        x_min_date = [x_min_date earlierDate:inputDate];
        x_max_date = [x_max_date laterDate:inputDate];
        
        if(ry_min > ruininzu){
            ry_min = ruininzu;
        }
        if(ry_max < ruininzu){
            ry_max = ruininzu;
        }
        if(y_min > ninzu){
            y_min = ninzu;
        }
        if(y_max < ninzu){
            y_max = ninzu;
        }
        
    }
    
    disp_ruininzu = ry_max;   // 表示用当日まで累計人数
    com_ry_max = ry_max;
    com_ry_min = ry_min;
    com_y_max = y_max;
    com_y_min = y_min;
    
    saisin_ry = (integer_t) ry_max ;
    
    y_min = (long)999999999;
    y_max = (long)-1;
    ry_min = (long)999999999;
    ry_max = (long)0;
    
    for( NSMutableArray *v in Z_gData ){
        NSArray *w = v;
        NSString *inputDateStr = (NSString *)[w objectAtIndex:KESSAIBI];   // 決済日
        NSString *ninzuStr = (NSString *)[w objectAtIndex:NINZU];          // 当日申込人数
        NSString *ruininzuStr = (NSString *)[w objectAtIndex:RUININZU];    // 累計申込人数
        NSInteger ninzu = ninzuStr.integerValue;
        NSInteger ruininzu = ruininzuStr.integerValue;
        
        inputDate = [inputDateFormatter dateFromString:inputDateStr];
        outputDate = [outputDateFormatter dateFromString:inputDateStr];
        
        x_min_date = [x_min_date earlierDate:inputDate];
        x_max_date = [x_max_date laterDate:inputDate];
        
        if(ry_min > ruininzu){
            ry_min = ruininzu;
        }
        if(ry_max < ruininzu){
            ry_max = ruininzu;
        }
        if(y_min > ninzu){
            y_min = ninzu;
        }
        if(y_max < ninzu){
            y_max = ninzu;
        }
        
    }
    
    if(com_ry_max < ry_max){
        com_ry_max = ry_max;
    }
    if(com_ry_min > ry_min){
        com_ry_min = ry_min;
    }

    // 累計人数のY軸の最大値を目標人数とcom_ry_maxの大きい方にする
    
    NSString* mokuhyouninzuStr = [sharedData getDataForKey:@"目標人数"];
    mokuhyouNinzu = [mokuhyouninzuStr intValue];
    if(com_ry_max < mokuhyouNinzu){
            com_ry_max = mokuhyouNinzu;
    }

    
    // 棒グラフY軸インターバルの設定
    
    NSInteger iw = floor(com_y_max / (tickCountForBar - 1));
    if(iw < 10){
        roundUnit = 2;
    } else  if (iw < 100){
        roundUnit = 10;
    } else if (iw < 1000){
        roundUnit = 100;
    } else {
        roundUnit = 1000;
    }
    YB_INTVL = floor(iw / roundUnit) * roundUnit;
  //  NSLog(@"%f",YB_INTVL);
    
    // 折れ線グラフY軸インターバルの設定
    
    iw = floor(com_ry_max / (tickCountForScatter - 1));
    if(iw < 100){
        roundUnit = 10;
    } else if (iw < 1000){
        roundUnit = 100;
    } else {
        roundUnit = 1000;
    }
    YS_INTVL = floor(iw / roundUnit) * roundUnit;
}
-(void)gValueSetting{     // 指定した実施回のグラフデータ値の設定
    
     NSInteger i=0;
    for( NSMutableArray *v in gData){
        NSArray *w = v;
        NSString *ninzuStr = (NSString *)[w objectAtIndex:NINZU];          // 当日申込人数
        NSString *ruininzuStr = (NSString *)[w objectAtIndex:RUININZU];    // 累計申込人数
        NSInteger ninzu = ninzuStr.integerValue;
        NSInteger ruininzu = ruininzuStr.integerValue;
        
        NSNumber *x = [NSNumber numberWithInteger:i++];
        NSNumber *y = [NSNumber numberWithInteger:ninzu];       //　当日申込人数
        NSNumber *ry = [NSNumber numberWithInteger :ruininzu];  //　累計申込人数
        // 折れ線グラフデータ
        [self.dataForScatter addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", ry, @"y", nil]];
        // 棒グラフデータ
        [self.dataForBar addObject:y];
        
    }
    [self.dataForBar addObject:[NSMutableArray arrayWithObjects: nil ]];

    
}

-(BOOL)Z_gValueSetting{     // 前年実施回のグラフデータ値の設定
    
    NSInteger i=0;
    zennen_ry=0;
    NSString *kaisiStr;
    NSString *simekiriStr;
    NSString *kaisiStrZen;
    NSString *simekiriStrZen;
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
    [inputDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
    inputDateFormatter.dateFormat =  DATEFORMAT;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
    df.dateFormat  = @"yyyy/MM/dd";
    
    // 受付開始日から当日までの日数と受付期間日数の比率を求める
    // これを受付開始経過日数比率とする。
    // 前年の受付期間日数×受付開始経過日数比率をZ_idxとする。
    // (Z_idx)の値を前年比の分母とする
    
    NSString* syubetu = [sharedData getDataForKey:@"試験種別"];
    NSString* jissikai = [sharedData getDataForKey:@"実施回"];
    NSString* zennen;
    FMDatabase* db = [self _getDB:DBNAME];
    NSString *sql = @"select kaisibi, simekiribi, zennenjissikai from AdminInfo where syubetu = ? and jissikai = ?";
    FMResultSet* results=[db executeQuery:sql,syubetu, jissikai];
    if ([results next]){
        kaisiStr = [results stringForColumnIndex:0];
        simekiriStr = [results stringForColumnIndex:1];
        zennen = [results stringForColumnIndex:2];
    } else {
      
        NSLog(@"ありえないエラー　　result FALSE");
        return NO;
    }
    sql = @"select kaisibi, simekiribi from AdminInfo where syubetu = ? and jissikai = ?";
    results=[db executeQuery:sql,syubetu, zennen];
    if ([results next]){
        kaisiStrZen = [results stringForColumnIndex:0];
        simekiriStrZen = [results stringForColumnIndex:1];
    } else {
        
        NSLog(@"ありえる　　result FALSE");
        return NO;
    }
    
    NSString *from=[kaisiStrZen substringWithRange:NSMakeRange(5,5)];
    NSString *to=[simekiriStrZen substringWithRange:NSMakeRange(5,5)];
    from =  [from stringByAppendingString:@"〜"];
    z_uketukekikan =  [from stringByAppendingString:to];
    
    NSDate *kaisiDate = [inputDateFormatter dateFromString:kaisiStr];
    NSDate *simekiriDate = [inputDateFormatter dateFromString:simekiriStr];
    NSDate *kaisiDateZen = [inputDateFormatter dateFromString:kaisiStrZen];
    NSDate *simekiriDateZen = [inputDateFormatter dateFromString:simekiriStrZen];
    
    NSDate *today = [NSDate date ];

    NSDate *fromDate;
    NSDate *toDate;
    fromDate = kaisiDate;
    toDate = today;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comp = [calendar components:NSDayCalendarUnit fromDate:fromDate toDate:toDate options:0];
    kaisibiBetweenToday = comp.day + 1;
    
    fromDate = kaisiDate;
    toDate = simekiriDate;
    comp = [calendar components:NSDayCalendarUnit fromDate:fromDate toDate:toDate options:0];
    kaisiBetweenSimekiribi = comp.day + 1;
    
    fromDate = kaisiDateZen;
    toDate = simekiriDateZen;
    comp = [calendar components:NSDayCalendarUnit fromDate:fromDate toDate:toDate options:0];
    kaisiBetweenSimekiribiZen = comp.day + 1;

    int zennenIndex = 0;
 
    if (kaisibiBetweenToday >= kaisiBetweenSimekiribi ){
    
        zennenIndex = Z_rec_count - 1;
        keikaritu = 100;
  
    } else {
        keikaritu = (int)kaisibiBetweenToday * 100 / (int)kaisiBetweenSimekiribi;
        zennenIndex = keikaritu * (int)kaisiBetweenSimekiribiZen / 100;

    }

   
    
    for( NSMutableArray *v in Z_gData ){
        NSArray *w = v;

        NSString *ruininzuStr = (NSString *)[w objectAtIndex:RUININZU];    // 累計申込人数
        NSInteger ruininzu = ruininzuStr.integerValue;
        
         
        NSNumber *x = [NSNumber numberWithInteger:i++];
        
        NSNumber *ry = [NSNumber numberWithInteger :ruininzu];  //　累計申込人数
        // 折れ線グラフデータ
        [self.Z_dataForScatter addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", ry, @"y", nil]];
        
//        if (Z_rec_count < rec_count){
//            if ( i == (Z_rec_count - 1) ){
//                zennen_ry = [ry intValue];
//            }
//        }
//        else {
//            if ( i  == (rec_count - 1)){
//                zennen_ry = [ry intValue];
//            }
//
//        }
    
        if( i == (zennenIndex) ){
                zennen_ry = [ry intValue];
                Z_today = (NSString *)[w objectAtIndex:KESSAIBI];
        }
    
 
        
//        NSLog(@"前年実績=%d",zennen_ry);
//        NSLog(@"r1=%f",r1);
        
        
    }
    if( i > 0 ){
        return YES;
    } else {
        return NO;
    }
    
}

- (IBAction)onTapBtnOfSubview:(id)sender {
    
    for (UIView *view in [self.view subviews]) {
        if ([view isKindOfClass:[UIView class]]){
            if (view.tag == 1){
                view.hidden = YES ;
                _uketukekikanOfSubview.text = @"";
                _ruikeiOfSubview.text = @"";
                _mokuhyouOfSubview.text = @"";
                _keikarituOfSubview.text = @"";
                _ZuketukekikanOfSubview.text =@"";
                _ZruikeiOfSubview.text = @"";
                _tassieiOfSubview.text = @"";
                _zennenhiOfSubview.text =@"";
                
            }
        }
    }
    

}

// ツールバーの位置とサイズを調整する
- ( void )layoutToolbar:( UIInterfaceOrientation )orientation
{
	// ツールバーの高さを計算する
	CGSize parentSize = self.view.bounds.size;
	int newHeight = 44; // 標準の高さ
	
	// iPhone(非iPad)かつデバイスが横向きの場合は高さを32にする
	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
	   ( orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight ) )
	{
		newHeight = 32;
	}
	
	// 画面の最下部にツールバーを配置する
    int width=self.view.frame.size.width;
    int height=self.view.frame.size.height - newHeight;
    
    hostingView.frame = CGRectMake(0, 0, width,height);

	stack_toolbar.frame = CGRectMake( 0, parentSize.height - newHeight, parentSize.width, newHeight );
}

- ( void )willAnimateRotationToInterfaceOrientation:( UIInterfaceOrientation )toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[ super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration ];
	
	// デバイスの回転アニメーションが発生するタイミングで、ツールバーの位置とサイズを調整する
	[ self layoutToolbar:toInterfaceOrientation ];
}


@end
