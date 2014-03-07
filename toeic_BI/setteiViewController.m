//
//  setteiViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/02/01.
//  Copyright (c) 2014年 hirata. All rights reserved.
//
//
//  試験管理情報をダウンロードしてデバイスに書き出す
//　　サーバとの通信に失敗した場合でも、前回ダウンロードしたデータを利用する
//  次の画面では、デバイスに書かれた試験管理情報を読んで処理する
//
//  2014/2/9追加
//
//    当日日付から、申込受付中の試験実施回を特定する
//    当該実施回のグラフを表示する


#import "setteiViewController.h"
#import "shareData.h"
#import "STrow.h"



#define DEVICE      @"Main_iPhone"
#define URL     @"http://192.168.10.101:8080/prototype_sd"
//#define PATH    @"/prototype_sd/dlconf.php?name="
#define PATH    @"/dlconf.php?name="

#define TIMEOUTINTERVAL 5.0
#define CONF_NAM    @"TOEIC_TEST"
#define CONF_FILE   @"APP_CONF"
#define DBNAME      @"TOEIC.DB"
#define CONF_CLMS   7
#define SYUBETU             0
#define JISSIKAI            1
#define JISSIBI             2
#define MOKUHYOUNINZU       3
#define ZENNENJISSIKAI      4
#define KAISIBI             5
#define SIMEKIRIBI          6
#define BTN_INTVAL          50
#define SUPER_USER          @"iPhone1205"



@interface setteiViewController ()

@property (readwrite, nonatomic, weak) IBOutlet UIButton* goButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *rows;



@end


@implementation setteiViewController

NSString *path = PATH;
NSString *ourl;

NSString *setteiData;
NSMutableArray *syjissikai;

UIToolbar * stack_toolbar;

// 共有データ置き場へのポインタ
shareData* sharedData;

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

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.title = @"TOEIC 受付中の試験";

    syjissikai = [NSMutableArray array ];    
    
}
- (void)cellsSet
{
    
    STrow *aRow;
    
    NSInteger i;
    _rows = [NSMutableArray arrayWithCapacity:[syjissikai count]];
    
    
//    NSLog(@"%lu",(unsigned long)[syjissikai count]);
    
    if( [syjissikai count] <=0 ){   // 受付中の試験がない
        
        _rows = [NSMutableArray arrayWithCapacity:1];

        aRow = [[STrow alloc] init];
        aRow.title =  @"受付中の試験はありません";
        aRow.syubetu= @"xxx";
        aRow.jissikai=@"xxx";
        [_rows addObject:aRow];
        
    } else {
        for (i=0; i<[syjissikai count]; i++) {
        
            NSString *title = [NSString stringWithFormat:@"%@%@ %@",
                           [[syjissikai objectAtIndex:i] valueForKey:@"種別"],
                           [[syjissikai objectAtIndex:i] valueForKey:@"実施回"],
                           [[syjissikai objectAtIndex:i] valueForKey:@"実施日"]
                           ];
        
            aRow = [[STrow alloc] init];
            aRow.title =  title;
            aRow.syubetu= [[syjissikai objectAtIndex:i] valueForKey:@"種別"];
            aRow.jissikai= [[syjissikai objectAtIndex:i] valueForKey:@"実施回"];
            [_rows addObject:aRow];
        }
    }
    
    
    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];
    
    [_tableView reloadData];


}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //       NSLog(@"initWithNiBName");
        // 共有データインスタンスを取得
        sharedData = [shareData instance];
    }
    return self;
}


-(void)viewWillAppear:(BOOL)animated{
    
    [ super viewWillAppear:animated ];
	
	// ViewControllerが表示されるタイミングで、ツールバーの位置とサイズを調整する
	[ self layoutToolbar:self.interfaceOrientation ];
    

    [self.navigationController setNavigationBarHidden:NO animated:YES]; // ナビゲーションバー表示
 
    [self getNewestJissikai];   // 直近の実施回を求める
    
    [self cellsSet];                // テーブルセルに試験回情報表示
    
    FMDatabase* db = [self _getDB:DBNAME];
    NSString*   sql = @"select count(*) from AdminInfo;";
    FMResultSet *results = [db executeQuery:sql];
    if ([db hadError]) {
        
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        
        [self setteiFileDownload]; // 設定ファイルダウンロード
    }
    if([results next]){
        
        if( [results intForColumnIndex:0] == 0){
            
            [self setteiFileDownload]; // 設定ファイルダウンロード
            
        }
        
        
    }
}
    

-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // ナビゲーションバー非表示
}

-(void)viewDidAppear:(BOOL)animated{
    
    
    
    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];

    
}

- (NSString *)confRead
{
    NSString * url;
    NSString *fnam = CONF_FILE;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fnam];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:dbPath];
    if (!fileHandle) {
        // ファイルがいない
        
        url =[sharedData getDataForKey:@"サーバURL"];
        if ([url length]==0){
            url=URL;
        }
        
    } else{
        
        NSData *data = [fileHandle readDataToEndOfFile];        // ファイル読み込み
        // ファイルを閉じる
        [fileHandle closeFile];
        
        // NSDataをNSStringに変換する。
        url = [[NSString alloc] initWithBytes:data.bytes
                                       length:data.length
                                     encoding:NSUTF8StringEncoding];
    }
    
//    NSLog(@"URL=%@",url);
    
    return url;
}



- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    //ツールバー
    UIToolbar * toolBar = [ [ UIToolbar alloc ] initWithFrame:CGRectMake( 0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44 ) ];
    [ self.view addSubview:toolBar ];
    
    // ボタンを作成する
    
    UIButton* cfButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [cfButton addTarget:self
                 action:@selector(onTapConfigButton:)
       forControlEvents:UIControlEventTouchUpInside];
    cfButton.frame = CGRectMake(10, 10, 60, 30);
    [cfButton setTitle:@"設定" forState:UIControlStateNormal];
    UIBarButtonItem* cfButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cfButton];
    
    UIButton* lgButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [lgButton addTarget:self
                 action:@selector(onTapLogButton:)
       forControlEvents:UIControlEventTouchUpInside];
    lgButton.frame = CGRectMake(10, 10, 60, 30);
    [lgButton setTitle:@"ログ" forState:UIControlStateNormal];
    UIBarButtonItem* lgButtonItem = [[UIBarButtonItem alloc] initWithCustomView:lgButton];
    
    // 可変間隔のスペーサーを作成する
    UIBarButtonItem * flexibleSpacer = [ [ UIBarButtonItem alloc ]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil
                                        action:nil ];
    
    
    UIDevice *dev = [UIDevice currentDevice];
    NSString* devName = dev.name;

    if ([devName isEqualToString:SUPER_USER] ){
        toolBar.items = [ NSArray arrayWithObjects:
                         lgButtonItem,
                         flexibleSpacer,
                         cfButtonItem,
                         nil ];
    } else {
    
        toolBar.items = [ NSArray arrayWithObjects:
                     flexibleSpacer,
                     cfButtonItem,
                     nil ];
    }
    
    stack_toolbar = toolBar;
    
///-------------------------------------------------
    
    sharedData = [shareData instance];
    
    [sharedData setData:[NSDate date] forKey:@"当日日付"];
    [sharedData removeDataForKey:@"遷移元"];

    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    FMDatabase* db = [self _getDB:DBNAME];
    NSString*   sql = @"select count(*) from AdminInfo;";
    FMResultSet *results = [db executeQuery:sql];
    if ([db hadError]) {
        
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        
        [self setteiFileDownload]; // 設定ファイルダウンロード
    }
    if([results next]){
        
        if( [results intForColumnIndex:0] == 0){
            
            [self setteiFileDownload]; // 設定ファイルダウンロード
            
        }
        
        
    }

    
}
-(void)onTapLogButton:(id)sender{
    
    [sharedData setData:@"setteiViewController" forKey:@"遷移元"];
    
    [self performSegueWithIdentifier:@"goLog" sender:self];

    
}

-(void)onTapConfigButton:(id)sender{
    
    [sharedData setData:@"firstViewController" forKey:@"遷移元"];
    
    [self performSegueWithIdentifier:@"showConfig" sender:self];
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setteiFileDownload { // 試験設定ファイルのダウンロード
    
    [self startAnimation];  // くるくる　スタート
    
    NSString * url;
    url=[self confRead];
    [sharedData setData:url forKey:@"サーバURL"];

    
    // 同期通信
    // 送信するリクエストを作成する。

    
    UIDevice *dev = [UIDevice currentDevice];
    NSString* devName = dev.name;
    NSString *str = [ url stringByAppendingString:@"/sqlite.php?"];
    NSString *fnam = [NSString stringWithFormat:@"name=%@&cmd=%@",devName , @"DL"];

    str = [ str stringByAppendingString: fnam];
    NSURL *wurl = [NSURL URLWithString:str];
    NSURLRequest  *request = [[NSURLRequest alloc] initWithURL:wurl cachePolicy:NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval:TIMEOUTINTERVAL];
    
    // リクエストを送信する。
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) {
        // エラー処理を行う。
        
        [self stopAnimation];  // くるくる　止める
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"サーバに接続出来ません"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        return;
        
    } else {
   
        [self stopAnimation];  // くるくる　止める
        
        if(data.length == 0){       // データなし
            UIAlertView *alertView
            = [[UIAlertView alloc] initWithTitle:nil
                                         message:@"試験管理情報のデータがありません"
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil];
            [alertView show];
            
            return;
        }
  
        [self tableinsert:data];        // データベースにインポート
        
        NSString *text
            = [[NSString alloc] initWithBytes:data.bytes
                                       length:data.length
                                     encoding:NSUTF8StringEncoding];
            
        // 共有データに設定データをセット
        [sharedData setData:text forKey:@"設定データ"];
        
        [sharedData removeDataForKey:@"種別"];
        [sharedData removeDataForKey:@"実施回"];
        
        
        [self getNewestJissikai];       // 直近の実施回を求める
            
        [self cellsSet];                // テーブルセルに試験回情報表示
        
    }
    
 }


-(void) tableinsert:(NSData *)data{   // 試験管理情報をsqlitetableにインサートする
//
  
    FMDatabase* db = [self _getDB:DBNAME];
    
    NSString*   sql = @"CREATE TABLE IF NOT EXISTS AdminInfo (syubetu TEXT, jissikai TEXT, jissibi TEXT , mokuhyouninzu INTEGER , zennenjissikai TEXT , kaisibi TEXT , simekiribi TEXT , PRIMARY KEY (syubetu , jissikai));";
    [db executeUpdate:sql];
    
    sql = @"delete from AdminInfo;";
    [db executeUpdate:sql];
    
    sql = @"insert into AdminInfo(syubetu , jissikai , jissibi , mokuhyouninzu , zennenjissikai , kaisibi , simekiribi) values(?,?,?,?,?,?,?)";
    
    NSString *text
    = [[NSString alloc] initWithBytes:data.bytes
                               length:data.length
                             encoding:NSUTF8StringEncoding];
    
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    
    for (NSString *row in lines) {
        
        NSArray *items = [row componentsSeparatedByString:@","];
        
        if( CONF_CLMS <= [items count] ){
            
            [db executeUpdate:sql, [[items objectAtIndex:SYUBETU] stringByTrimmingCharactersInSet:
                                            [NSCharacterSet whitespaceCharacterSet]],
                                    [[items objectAtIndex:JISSIKAI] stringByTrimmingCharactersInSet:
                                            [NSCharacterSet whitespaceCharacterSet]],
                                    [[items objectAtIndex:JISSIBI] stringByTrimmingCharactersInSet:
                                            [NSCharacterSet whitespaceCharacterSet]],
                                    [[items objectAtIndex:MOKUHYOUNINZU] stringByTrimmingCharactersInSet:
                                            [NSCharacterSet whitespaceCharacterSet]],
                                    [[items objectAtIndex:ZENNENJISSIKAI] stringByTrimmingCharactersInSet:
                                            [NSCharacterSet whitespaceCharacterSet]],
                                    [[items objectAtIndex:KAISIBI] stringByTrimmingCharactersInSet:
                                            [NSCharacterSet whitespaceCharacterSet]],
                                    [[items objectAtIndex:SIMEKIRIBI] stringByTrimmingCharactersInSet:
                                      [NSCharacterSet whitespaceCharacterSet]] ] ;
        }
    }
    [db close];

}

- (void) startAnimation
{
    //   [self.activityIndicator startAnimating];
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = YES;
}


/* show the user that loading activity has stopped */

- (void) stopAnimation
{
    //    [self.activityIndicator stopAnimating];
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = NO;
}


- (BOOL)getNewestJissikai{
    
    // 受付期間中の実施回を戻す
    
    syjissikai = [NSMutableArray array];   // ex:[LR,188],[BR,50]
    
    BOOL bl=FALSE;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyy/MM/dd";
    NSDate * wday = [sharedData getDataForKey:@"当日日付"];
    NSString *todayStr = [df stringFromDate:wday];
        
    NSString *sql = @"SELECT * FROM AdminInfo where kaisibi <= ? and jissibi > ? ;";
    FMDatabase* db = [self _getDB:DBNAME];
    FMResultSet*    results = [db executeQuery:sql, todayStr, todayStr];
    while( [results next] ){
            [syjissikai addObject:[NSMutableDictionary
                                   dictionaryWithObjectsAndKeys:[results stringForColumnIndex:0], @"種別",
                                   [results stringForColumnIndex:1], @"実施回",
                                   [results stringForColumnIndex:2], @"実施日", nil]];
     
            
            bl = TRUE;
    
    }

     [db close];
    
    return bl;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return _rows.count;

    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"CellID";
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    
    STrow *aRow = [_rows objectAtIndex:indexPath.row];
    NSString *title = aRow.title;
    cell.textLabel.text = title;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_rows removeObjectAtIndex:indexPath.row];
        [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (destinationIndexPath.row < _rows.count) {
        NSString *title = [_rows objectAtIndex:sourceIndexPath.row];
        [_rows removeObjectAtIndex:sourceIndexPath.row];
        [_rows insertObject:title atIndex:destinationIndexPath.row];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    STrow *aRow = (STrow*)[_rows objectAtIndex:indexPath.row];
    
    [sharedData setData:aRow.syubetu forKey:@"試験種別"];
    [sharedData setData:aRow.jissikai forKey:@"実施回"];
    
    NSString * url;
    url=[self confRead];
    [sharedData setData:url forKey:@"サーバURL"];
    
    UIDevice *dev = [UIDevice currentDevice];
    NSString *devName = dev.name;
    NSString *str = [ url stringByAppendingString:@"/sqlite.php?"];
    NSString *fnam2 = [NSString stringWithFormat:@"name=%@&cmd=%@&p1=%@&p2=%@" ,devName, @"GRAPH", aRow.syubetu
                       ,aRow.jissikai
                       ];
    str = [ str stringByAppendingString: fnam2];
    NSURL *wurl = [NSURL URLWithString:str];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:wurl cachePolicy:NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval:TIMEOUTINTERVAL];
    
    // リクエストを送信する。
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    

    
    [sharedData setData:@"setteiViewController" forKey:@"遷移元"];
    
    [self performSegueWithIdentifier:@"showFirstViewController" sender:self];
    
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
	stack_toolbar.frame = CGRectMake( 0, parentSize.height - newHeight, parentSize.width, newHeight );
}

- ( void )willAnimateRotationToInterfaceOrientation:( UIInterfaceOrientation )toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[ super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration ];
	
	// デバイスの回転アニメーションが発生するタイミングで、ツールバーの位置とサイズを調整する
	[ self layoutToolbar:toInterfaceOrientation ];
}


@end
