//
//  firstViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/01/29.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import "firstViewController.h"
//#import "BarAndScatterViewController.h"
//#import "setteiViewController.h"
#import "shareData.h"

//#define URL @"http://10.10.69.110/dl.php?name="
#define URL @"http://192.168.10.101:8080/prototype_sd"
//#define PATH    @"/prototype_sd/dl.php?name="
#define PATH    @"/dl.php?name="

#define CLMS 5
#define CONF_CLMS   7
#define Time_start @"2010-01-01 23:59:59 +0900"
#define SYUBETU     0
#define JISSIKAI    1
#define KESSAIBI    2
#define NINZU       3
#define RUININZU    4
#define JISSIBI             2
#define MOKUHYOUNINZU       3
#define ZENNENJISSIKAI      4
#define KAISIBI             5
#define SIMEKIRIBI          6
#define DATEFORMAT  @"yyyy/mm/dd"
#define YB_INTVL    5000.0
#define YS_INTVL    10000.0
#define DEVICE      @"Main_iPhone"
#define TIMEOUTINTERVAL 5.0
#define CONF_NAM    @"TOEIC_TEST"
#define DBNAME      @"TOEIC.DB"
#define CONF_FILE   @"APP_CONF"




@implementation firstViewController {
//    BarAndScatterViewController *secondController;


NSMutableData *receivedData;
NSInteger rec_count;
NSString *setteiData;
NSDate *fileDlDate;
NSString *simekiribii;
NSString *url;
NSString *path;
UIToolbar * stack_toolbar;
    
    
}
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // 共有データインスタンスを取得
        sharedData = [shareData instance];
    }
    return self;
}

- (void)onTapGraphButton:(id)sender {

 //   NSLog(@"グラフボタン押した");
    [self callGraph];
    
}


- (IBAction)btnTapped:(id)sender {   //グラフボタンおした
    
    [self callGraph];
    
}

-(void)callGraph{
    //NSLog(@"syubetu = %@",_syubetuTextField.text);

    if ([_syubetuTextField.text isEqualToString: @"" ]){
        
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"試験種別を選択して下さい"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        
        return;
        
    }

    if ([_jissikaiTextField.text isEqualToString: @"" ]){
        
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"実施回を入力して下さい"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        
        return;
        
        
    }
    
    // デバイスからデータを読み込んでグラフ画面に遷移
    
    [self FileDownloadAndCallGraph];
    
 }

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // ナビゲーションバー表示
    url =[sharedData getDataForKey:@"サーバURL"];
    
    [ super viewWillAppear:animated ];
	
	// ViewControllerが表示されるタイミングで、ツールバーの位置とサイズを調整する
	[ self layoutToolbar:self.interfaceOrientation ];


}

-(void)viewDidAppear:(BOOL)animated{
    
//    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
//    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
//    {
//        //Do your textField animation here
//        [stack_toolbar removeFromSuperview];
//        [self.view addSubview:stack_toolbar];
//        
//    }
    
 //   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkRotation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    // 初期画面から遷移してきたときは、ダウンロードしてグラフ表示を自動実行する
    // Sharedataから表示すべき実施回を受け取りテキストフィールドに引き継がれてコールされる
    //
    
    NSString* sourceView =[sharedData getDataForKey:@"遷移元"];
    if([sourceView isEqualToString:@"setteiViewController"]){
        
        [self FileDownloadAndCallGraph];
    }

    
}


-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // ナビゲーションバー非表示
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    url =[sharedData getDataForKey:@"サーバURL"];
    path = PATH;
    
    _syubetuTextField.text = @"";
    _jissikaiTextField.text = @"";
    _zennenjissikaiTextField.text = @"";
    _mokuhyouninzuTextField.text = @"";
    _jissibiTextField.text = @"";
    _mokuhyouninzuTextField.text = @"";
    _mosikomiKikanTextField.text =@"";
    _syubetuTextField.delegate = self;
    _jissikaiTextField.delegate = self;
    
    [sharedData removeDataForKey:@"実施日"];
    [sharedData removeDataForKey:@"目標人数"];
    [sharedData removeDataForKey:@"前年実施回"];
    [sharedData removeDataForKey:@"前年実施回データ"];
    [sharedData removeDataForKey:@"開始日"];
    [sharedData removeDataForKey:@"締切日"];
    [sharedData setData:@"OFF" forKey:@"前年日付表示"];
    
    // 共有データからデータを読み出し
    _syubetuTextField.text = [sharedData getDataForKey:@"試験種別"];
    _jissikaiTextField.text = [sharedData getDataForKey:@"実施回"];
    
    //ツールバー
    UIToolbar * toolBar = [ [ UIToolbar alloc ] initWithFrame:CGRectMake( 0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44 ) ];
    [ self.view addSubview:toolBar ];
    
    // ボタンを作成する
  
    UIButton* gfButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [gfButton addTarget:self
                 action:@selector(onTapGraphButton:)
       forControlEvents:UIControlEventTouchUpInside];
    gfButton.frame = CGRectMake(10, 10, 60, 30);
    [gfButton setTitle:@"グラフ" forState:UIControlStateNormal];
    UIBarButtonItem* gfButtonItem = [[UIBarButtonItem alloc] initWithCustomView:gfButton];
 
    
      // 固定間隔のスペーサーを作成する
    UIBarButtonItem * fixedSpacer = [ [ UIBarButtonItem alloc ]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                     target:nil
                                     action:nil ];
    
    fixedSpacer.width = 16;
    
    // 可変間隔のスペーサーを作成する
    UIBarButtonItem * flexibleSpacer = [ [ UIBarButtonItem alloc ]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil
                                        action:nil ];
 
    toolBar.items = [ NSArray arrayWithObjects:
                     flexibleSpacer,
                     gfButtonItem,
         
                     nil ];
    
    stack_toolbar = toolBar;
    
    [self stopAnimation];  // くるくる　止める
 
     setteiData =[sharedData getDataForKey:@"設定データ"];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)bkgTapped:(id)sender {
    
    [self.view endEditing:YES];     //　画面タッチでキーボード引っ込める
    
}



- (IBAction)didEndOfjissikaiTextField:(id)sender {
    
    // 実施回テキストフィールドの入力完了時の処理

    if([self confExistCheck] == FALSE){
        
        simekiribii = @"指定なし";
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"試験管理情報が未登録の為、指定出来ません。"
                                    delegate:self
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        
        return;

    }
    
   
}
- (BOOL)confExistCheck {
    
    // 実施回テキストフィールドの入力完了時の処理
    
    
    NSString *sql = @"SELECT jissibi, mokuhyouninzu , zennenjissikai, kaisibi , simekiribi FROM AdminInfo where syubetu= ? and jissikai = ? ;";
    
    FMDatabase* db = [self _getDB:DBNAME];

    
    FMResultSet*    results = [db executeQuery:sql, _syubetuTextField.text, _jissikaiTextField.text ];
    
    [results next];
    
    _jissibiTextField.text = [results stringForColumnIndex:0];
    _mokuhyouninzuTextField.text = [results stringForColumnIndex:1];
    _zennenjissikaiTextField.text = [results stringForColumnIndex:2];
    
    NSString *from =[[results stringForColumnIndex:3] stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceCharacterSet]];
    from=[from substringWithRange:NSMakeRange(5,5)];
    NSString *to =[[results stringForColumnIndex:4]stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceCharacterSet]];
    to=[to substringWithRange:NSMakeRange(5,5)];
    from =  [from stringByAppendingString:@"〜"];
    _mosikomiKikanTextField.text =  [from stringByAppendingString:to];
    
    
    [db close];

    return TRUE;

}


// アラートのボタンが押された時に呼ばれるデリゲート　　データ取得済みだけど再取得しますか?
-(void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            //１番目のボタンが押されたときの処理を記述する  いいえ
            // 何もしない。必要ならグラフボタン押してもらう
            break;
        case 1:
            //２番目のボタンが押されたときの処理を記述する    はい
            // データをダウンロード取得してからグラフに遷移する
        
            [self FileDownloadAndCallGraph];

            break;
    }
    
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{   //試験種別入力時にアクションシート表示
    
    if(textField.tag==1)// tag will be integer
    {
     //   NSLog(@"ACTION SHEET WILL DISPLAY");
        [textField setUserInteractionEnabled:YES];
        [textField resignFirstResponder];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"試験種別" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"LR試験", @"SW試験",@"Bridge試験" ,nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        [actionSheet showInView:self.view];
        
        
        return NO;
    } else {
    
        return YES;
    }
    
}

-(void)actionSheet:(UIActionSheet*)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            // １番目のボタンが押されたときの処理を記述する
            _syubetuTextField.text = @"LR";
            break;
        case 1:
            // ２番目のボタンが押されたときの処理を記述する
            _syubetuTextField.text = @"SW";

            break;
        case 2:
            // ３番目のボタンが押されたときの処理を記述する
            _syubetuTextField.text = @"BR";

            break;
        default:
            _syubetuTextField.text = @" ";
            break;
    }
    
}

- (void)FileDownloadAndCallGraph {
    
    // 送信したいURLを作成し、Requestを作成します。
    
    if([self confExistCheck] == FALSE){
        
        simekiribii = @"指定なし";
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"試験管理情報が未登録の為、指定出来ません。"
                                    delegate:self
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        
        return;
        
    }
    
    //    NSString * url;
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
    
    // NSLog(@"url=%@",url);
    
    NSString *area=@"";
    FMDatabase* db = [self _getDB:DBNAME];
    NSString*   sql = @"select no from testarea where selected = '1';";
    FMResultSet* results=[db executeQuery:sql];
    while( [results next] ){
        
        if([area length] > 0){
            area = [ area stringByAppendingString:@","];
        }
        area = [ area stringByAppendingString:[results stringForColumnIndex:0]];
        
    }
    if([area length]==0){
        area=@"all";
    }
 //   NSLog(@"area=%@",area);
    
    [db close];

    
    
    fnam = [ _syubetuTextField.text stringByAppendingString:_jissikaiTextField.text];
    
    NSString *str = [ url stringByAppendingString: path];
    str = [ str stringByAppendingString: fnam];
    str = [ str stringByAppendingString:[NSString stringWithFormat:@"&area=%@",area]]; //地域指定


    NSURL *wurl = [NSURL URLWithString:str];
    NSURLRequest  *request = [[NSURLRequest alloc] initWithURL:wurl cachePolicy:NSURLRequestUseProtocolCachePolicy
        timeoutInterval:TIMEOUTINTERVAL];

    
    // NSURLConnectionのインスタンスを作成したら、すぐに
    // 指定したURLへリクエストを送信し始めます。
    // delegate指定すると、サーバーからデータを受信したり、
    // エラーが発生したりするとメソッドが呼び出される。
    NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    // 作成に失敗する場合には、リクエストが送信されないので
    // チェックする
    if (!aConnection) {
        NSLog(@"connection error.");
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"サーバに接続できませんでした"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        return;

    }

     [self startAnimation];  // くるくる　スタート
    
}
// データ受信時に１回だけ呼び出される。
// 受信データを格納する変数を初期化する。
- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *)response {
    
    // receiveDataはフィールド変数
    receivedData = [[NSMutableData alloc] init] ;
}

// データ受信したら何度も呼び出されるメソッド。
// 受信したデータをreceivedDataに追加する
- (void) connection:(NSURLConnection *) connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
    
 //
    
    
}

// データ受信が終わったら呼び出されるメソッド。
- (void) connectionDidFinishLoading:(NSURLConnection *)connection {

    // 受信データをファイルに書き出す
    
    [self stopAnimation];  // くるくる　止める
    
    if(receivedData.length == 0){       // データなし
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"データがありません"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    
    // NSDataをNSStringに変換する。
    NSString *text
    = [[NSString alloc] initWithBytes:receivedData.bytes
                               length:receivedData.length
                             encoding:NSUTF8StringEncoding];
    
  //  NSLog(@"DL DATE=%@",text);
    
    // 共有データにメッセージをセットして遷移
    NSString *sy = _syubetuTextField.text;
    NSString *jk = _jissikaiTextField.text;
    [sharedData setData:sy forKey:@"試験種別"];
    [sharedData setData:jk forKey:@"実施回"];
    NSString *jd = _jissibiTextField.text;
    NSString *uk = _mosikomiKikanTextField.text;
   
    [sharedData setData:jd forKey:@"実施日"];
    [sharedData setData:uk forKey:@"受付期間"];
    [sharedData setData:text forKey:@"ダウンロードデータ"];
    [sharedData setData:[NSDate date] forKey:@"データ取得日時"];
//    [sharedData setData:simekiribii forKey:@"締切日"];
    
    [sharedData setData:[NSNumber numberWithInt:[_mokuhyouninzuTextField.text intValue]] forKey:@"目標人数"];

    
    [self zennenfileReadAndsetDatastore];  //前年実施回データ読み込み
    
    // グラフ画面には、zennfileReadAndsetDataStoreの先で行う。ダウンロード処理があるから。

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // エラー情報を表示する。
    // objectForKeyで指定するKeyがポイント
    
    [self stopAnimation];  // くるくる　止める
    
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    UIAlertView *alertView
    = [[UIAlertView alloc] initWithTitle:nil
                                 message:@"サーバとの接続に失敗しました"
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil];
    [alertView show];
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

-(void)zennenfileReadAndsetDatastore{
    
 
    if ([_zennenjissikaiTextField.text length ] ==0 ){  // 前年実施回が指定されていない時は
     
        [sharedData removeDataForKey:@"前年実施回データ"];  //　残っている前年データを削除して
        return;                                            // 戻る
    }

    [sharedData removeDataForKey:@"前年実施回データ"];

    [self zennennFileDownload]; //前年ファイルをダウンロード
        
 }

-(void)zennennFileDownload{     // 前年ファイルのダウンロード
    
 
    receivedData = [[NSMutableData alloc] init] ;
    
    [self startAnimation];  // くるくる　スタート

    //    NSString * url;
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
    
    // NSLog(@"url=%@",url);
    

    // 同期通信
    // 送信するリクエストを作成する。
    NSString *area=@"";
    FMDatabase* db = [self _getDB:DBNAME];
    NSString*   sql = @"select no from testarea where selected = '1';";
    FMResultSet* results=[db executeQuery:sql];
    while( [results next] ){
        
        if([area length] > 0){
            area = [ area stringByAppendingString:@","];
        }
        area = [ area stringByAppendingString:[results stringForColumnIndex:0]];
        
    }
    if([area length]==0){
        area=@"all";
    }
    NSLog(@"area=%@",area);
    
    [db close];

    fnam = [ _syubetuTextField.text stringByAppendingString:_zennenjissikaiTextField.text];
    NSString *str = [ url stringByAppendingString: path];
    str = [ str stringByAppendingString: fnam];
    str = [ str stringByAppendingString:[NSString stringWithFormat:@"&area=%@",area]]; //地域指定

    
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
                                     message:@"前年実施回のデータ取得に失敗しました"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        return;
        
    } else {
        if(data.length == 0){       // データなし
            UIAlertView *alertView
            = [[UIAlertView alloc] initWithTitle:nil
                                         message:@"前年実施回のデータがありません"
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil];
            [alertView show];
            
            [self stopAnimation];  // くるくる　止める
            
            return;
        }
        [receivedData appendData:data];
        
        NSString *text
        = [[NSString alloc] initWithBytes:receivedData.bytes
                                   length:receivedData.length
                                 encoding:NSUTF8StringEncoding];
        
        // 共有データにメッセージをセット
        [sharedData setData:text forKey:@"前年実施回データ"];
        
        // 受信データをファイルに書き出す
        
        [self stopAnimation];  // くるくる　止める
        
        
        [sharedData setData:@"firstViewController" forKey:@"遷移元"];
        
        [self performSegueWithIdentifier:@"showGraph" sender:self];
        
      
    }
   
    
}

@end


