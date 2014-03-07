//
//  adminInfoViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/02/19.
//  Copyright (c) 2014年 hirata. All rights reserved.
//
//  2014-03-03
//  試験マスターの更新先のデフォルトをデバイスのデータベースとする。
//  更新権限ありの人だけサーバも更新するようにする。
//

#import "adminInfoViewController.h"
#import "shareData.h"
#import "ADrow.h"
#define URL     @"http://192.168.10.101:8080/prototype_sd"
#define PATH    @"/sqlite.php?"
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


@interface adminInfoViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *rows;

@end

@implementation adminInfoViewController

NSMutableData *ADreceivedData;
NSMutableArray *ADsyjissikai;


shareData* sharedData;
NSString *ADpath = PATH;
NSString *ADourl;


NSString *ADsetteiData;


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
    
    self.title = @"試験マスター";
    
    [self cellsSet];                // テーブルセルに試験回情報表示
    
    
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


- (void)cellsSet
{
    
    ADrow *aRow;
    
    _rows = [NSMutableArray arrayWithCapacity:[ADsyjissikai count]];
    
    
    FMDatabase* db = [self _getDB:DBNAME];
    
    NSString *sql = @"SELECT * FROM AdminInfo order by syubetu,jissikai;";
    FMResultSet*    results = [db executeQuery:sql];
    while( [results next] ){
        
        NSString *title = [ NSString stringWithFormat:@"%@%@ %@",
                           [results stringForColumnIndex:0],
                           [results stringForColumnIndex:1],
                           [results stringForColumnIndex:2]  ];
        aRow = [[ADrow alloc] init];
        aRow.title =  title;
        aRow.syubetu = (NSString*) [results stringForColumnIndex:0];
        aRow.jissikai =(NSString*)  [results stringForColumnIndex:1];
        aRow.jissibi =  (NSString*) [results stringForColumnIndex:2];
        aRow.mokuhyouninzu = [NSString stringWithFormat:@"%d",  [results intForColumnIndex:3]];
        aRow.zennenjissikai =(NSString*)   [results stringForColumnIndex:4];
        aRow.kaisibi = (NSString*) [results stringForColumnIndex:5];
        aRow.simekiribi = (NSString*)  [results stringForColumnIndex:6];
        [_rows addObject:aRow];

    }
    
    [db close];
    
    [_tableView reloadData];


}


- (void)viewWillAppear:(BOOL)animated
{
    
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // ナビゲーションバー表示

    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];

}


-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // ナビゲーションバー非表示
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(didTapEditButton)];
    
    //ツールバー
    UIToolbar * toolBar = [ [ UIToolbar alloc ] initWithFrame:CGRectMake( 0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44 ) ];
    [ self.view addSubview:toolBar ];
    
    // ボタンを作成する
    
    UIButton* cfButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [cfButton addTarget:self
                 action:@selector(onTapDlButton:)
       forControlEvents:UIControlEventTouchUpInside];
    cfButton.frame = CGRectMake(10, 10, 120, 30);
    [cfButton setTitle:@"サーバからロード" forState:UIControlStateNormal];
    UIBarButtonItem* cfButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cfButton];
    
    // 可変間隔のスペーサーを作成する
    UIBarButtonItem * flexibleSpacer = [ [ UIBarButtonItem alloc ]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil
                                        action:nil ];
    
    toolBar.items = [ NSArray arrayWithObjects:
                     flexibleSpacer,
                     cfButtonItem,
                     nil ];
    
    

}

-(void)onTapDlButton:(id)sender{        // 初期ロード
    
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

    [self startAnimation];  // くるくる　スタート
    
    // 同期通信
    // 送信するリクエストを作成する。
    UIDevice *dev = [UIDevice currentDevice];
    NSString* devName = dev.name;

    NSString *str = [ url stringByAppendingString:@"/sqlite.php?"];
    fnam = [NSString stringWithFormat:@"name=%@&cmd=%@",devName ,@"DL"];
    
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
    }
    UIAlertView *alertView
    = [[UIAlertView alloc] initWithTitle:nil
                                 message:@"試験管理情報のロードが完了しました"
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil];
    [alertView show];
    
    [self cellsSet];
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
    
-(void)viewDidAppear:(BOOL)animated{
  
    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];
        
    [self cellsSet];
    
}


- (void)didTapEditButton
{
//    [_tableView setEditing:!_tableView.editing animated:YES];
//    if (_tableView.editing) {
//        self.navigationItem.rightBarButtonItem.title = @"Cancel";
//    } else {
//        self.navigationItem.rightBarButtonItem.title = @"Edit";
//    }
    
    [sharedData removeDataForKey:@"選択セル値集合"];
    
    [sharedData removeDataForKey:@"遷移元"];
    [sharedData setData:@"adminInfoViewController+新規" forKey:@"遷移元"];
    
    [self performSegueWithIdentifier:@"goAdminDetail" sender:self];

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
    
    ADrow *aRow = [_rows objectAtIndex:indexPath.row];
    NSString *title = aRow.title;
    cell.textLabel.text = title;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        ADrow *aRow = (ADrow*)[_rows objectAtIndex:indexPath.row];
        
        [_rows removeObjectAtIndex:indexPath.row];
        [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        
 //      NSLog(@"%ld,%@,%@",(long)indexPath.row,aRow.syubetu,aRow.jissikai);
        
        FMDatabase* db = [self _getDB:DBNAME];

        NSString *sql;
        
        if ([self sendToServer:aRow] == TRUE){
        
            sql = @"delete from AdminInfo where syubetu=? and jissikai=?;";
            [db executeUpdate:sql, aRow.syubetu, aRow.jissikai] ;
        
            if ([db hadError]) {
            
                NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                NSString *mg=[NSString stringWithFormat:@"データ削除が失敗しました"];
                UIAlertView *alertView
                = [[UIAlertView alloc] initWithTitle:nil
                                             message:mg
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
                [alertView show];

            } else {
                
                NSString *mg=[NSString stringWithFormat:@"%@%@を削除しました", aRow.syubetu, aRow.jissikai];
                UIAlertView *alertView
                = [[UIAlertView alloc] initWithTitle:nil
                                             message:mg
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
                [alertView show];
                
            }
        } else {
            NSString *mg=[NSString stringWithFormat:@"サーバ更新に失敗しました"];
            UIAlertView *alertView
                = [[UIAlertView alloc] initWithTitle:nil
                                             message:mg
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
            [alertView show];
                
        }
        
        [db close];
        
        [self cellsSet];
        
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
    ADrow *aRow = (ADrow*)[_rows objectAtIndex:indexPath.row];
    
    [sharedData setData:(ADrow*)aRow forKey:@"選択セル値集合"];
    
    
    [sharedData removeDataForKey:@"遷移元"];
    [sharedData setData:@"adminInfoViewController+編集" forKey:@"遷移元"];
    
    [self performSegueWithIdentifier:@"goAdminDetail" sender:self];
}

-(BOOL)sendToServer:(ADrow *)aRow{
    
    FMDatabase* db = [self _getDB:DBNAME];
    
    NSString *sql=@"select mode from device;";
    FMResultSet* results=[db executeQuery:sql];
    if ([results next]){
        if ([[results stringForColumnIndex:0] isEqual:@"Local"]){
            return TRUE;
        }
    }

    UIDevice *dev = [UIDevice currentDevice];
    NSString* devName = dev.name;

    NSString * wurl;
    wurl=[self confRead:wurl];
    [sharedData setData:wurl forKey:@"サーバURL"];
    
    NSString *fnam = [NSString stringWithFormat:@"name=%@&cmd=%@&p1=%@&p2=%@",devName,@"DEL", aRow.syubetu, aRow.jissikai];
                       
    NSString *str = [ wurl stringByAppendingString: PATH];
    str = [ str stringByAppendingString: fnam];
    NSURL *url = [NSURL URLWithString:str];
    NSURLRequest  *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy
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
        return FALSE;
        
    } else {
        
        return TRUE;
        
    }

}

- (NSString*)confRead:(NSString*)wurl{

    NSString *fnam = CONF_FILE;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fnam];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:dbPath];
    if (!fileHandle) {
        // ファイルがいない
        
        wurl =[sharedData getDataForKey:@"サーバURL"];
        if([wurl length] == 0){
            wurl=URL;
            
        }
        
    } else{
        
        NSData *data = [fileHandle readDataToEndOfFile];        // ファイル読み込み
        // ファイルを閉じる
        [fileHandle closeFile];
        
        // NSDataをNSStringに変換する。
        wurl = [[NSString alloc] initWithBytes:data.bytes
                                       length:data.length
                                     encoding:NSUTF8StringEncoding];
    }
    
    return wurl;
    
}
@end
