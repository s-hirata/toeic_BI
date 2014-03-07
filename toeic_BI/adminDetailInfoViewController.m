//
//  adminDetailInfoViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/02/20.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import "adminDetailInfoViewController.h"
#import "shareData.h"
#import "ADrow.h"
#define DBNAME      @"TOEIC.DB"
#define CONF_FILE   @"APP_CONF"
#define URL     @"http://192.168.10.101:8080/prototype_sd"
#define PATH    @"/sqlite.php?"
#define TIMEOUTINTERVAL 5.0

@interface adminDetailInfoViewController ()
@property (strong, nonatomic) NSMutableArray *rows;


@end

@implementation adminDetailInfoViewController

shareData* sharedData;
NSMutableArray *ADsyjissikai;
NSString *ADsetteiData;
int selectedTag = 0;

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
    
    ADrow *aRow=[sharedData getDataForKey:@"選択セル値集合"];
    self.title = [NSString stringWithFormat:@"%@%@",
                  aRow.syubetu, aRow.jissikai];
    
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
- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // ナビゲーションバー表示
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // ナビゲーションバー非表示
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    _syubetuTextField.delegate = self;
    _jissibiTextField.delegate = self;
    _kaisibiTextField.delegate = self;
    _simekiriTextField.delegate = self;
    
    _myButton.hidden=YES;
    _myDatepicker.hidden=YES;
    _childView.hidden = YES;
    
    UIButton* cfButton = [UIButton buttonWithType:UIButtonTypeRoundedRect  ] ;
    [cfButton addTarget:self
                 action:@selector(onTapupdate:)
       forControlEvents:UIControlEventTouchUpInside];
    cfButton.frame = CGRectMake(10, 10, 60, 30);
    
    NSString *from=[sharedData getDataForKey:@"遷移元"];
    if( [from isEqualToString:@"adminInfoViewController+新規"]){
        self.title = @"新規追加";
        [cfButton setTitle:@"追加" forState:UIControlStateNormal];
    } else {
    
        [cfButton setTitle:@"更新" forState:UIControlStateNormal];
        ADrow *aRow=[sharedData getDataForKey:@"選択セル値集合"];
        self.title = [NSString stringWithFormat:@"%@%@",
                      aRow.syubetu, aRow.jissikai];
    
        _syubetuTextField.text = aRow.syubetu;
        _jissikaiTextField.text = aRow.jissikai;
        _jissibiTextField.text = aRow.jissibi;
        _mokuhyouTextField.text = aRow.mokuhyouninzu;
        _zennenTextField.text = aRow.zennenjissikai;
        _kaisibiTextField.text = aRow.kaisibi;
        _simekiriTextField.text = aRow.simekiribi;
    }
    
    //ツールバー
    UIToolbar * toolBar = [ [ UIToolbar alloc ] initWithFrame:CGRectMake( 0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44 ) ];
    [ self.view addSubview:toolBar ];
    
    // ボタンを作成する
    
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

- (IBAction)onTapupdate:(id)sender {

    
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
    
    FMDatabase* db = [self _getDB:DBNAME];
    
    NSString *sql;
    
    sql = @"delete from AdminInfo where syubetu=? and jissikai=?;";
    [db executeUpdate:sql, _syubetuTextField.text, _jissikaiTextField.text ];
    
    sql = @"insert into AdminInfo(syubetu , jissikai , jissibi , mokuhyouninzu , zennenjissikai , kaisibi , simekiribi) values(?,?,?,?,?,?,?)";
    [db executeUpdate:sql, _syubetuTextField.text, _jissikaiTextField.text, _jissibiTextField.text ,  _mokuhyouTextField.text, _zennenTextField.text , _kaisibiTextField.text , _simekiriTextField.text ];
    
    if ([db hadError]) {
        
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"データの更新に失敗しました"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
    } else{
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"データを更新しました"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        
    }
    
    
    sql=@"select mode from device;";
    FMResultSet* results=[db executeQuery:sql];
    if ([results next]){
        if ([[results stringForColumnIndex:0] isEqual:@"Local"]){
            return;
        }
    }

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
    
//    [self startAnimation];  // くるくる　スタート
    
    // 同期通信
    // 送信するリクエストを作成する。
    
    UIDevice *dev = [UIDevice currentDevice];
    NSString* devName = dev.name;
    
    NSString *str = [ url stringByAppendingString:@"/sqlite.php?"];
    fnam = [NSString stringWithFormat:@"name=%@&cmd=%@&p1=%@&p2=%@&p3=%@&p4=%@&p5=%@&p6=%@&p7=%@",devName, @"UPD",
           _syubetuTextField.text, _jissikaiTextField.text, _jissibiTextField.text ,  _mokuhyouTextField.text, _zennenTextField.text , _kaisibiTextField.text , _simekiriTextField.text ];
    
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
        
//        [self stopAnimation];  // くるくる　止める
        UIAlertView *alertView
        = [[UIAlertView alloc] initWithTitle:nil
                                     message:@"サーバに接続出来ません"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        [alertView show];
        return;
        
    }
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{   //試験種別入力時にアクションシート表示
    
    
    selectedTag = textField.tag;
    

    if(textField.tag==1){       // tag will be integer
        //   NSLog(@"ACTION SHEET WILL DISPLAY");
        
        _myButton.hidden=YES;
        _childView.hidden=YES;
        _myDatepicker.hidden=YES;
        
        [textField setUserInteractionEnabled:YES];
        [textField resignFirstResponder];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"試験種別" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"LR試験", @"SW試験",@"Bridge試験" ,nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        [actionSheet showInView:self.view];
        
    } else if (textField.tag > 1){
        
        _myButton.hidden=NO;
        _childView.hidden=NO;
        _myDatepicker.hidden=NO;
        
        [[self view]endEditing:YES];
        
    }
        
    if(textField.tag == 0){
        
        _myButton.hidden=YES;
        _childView.hidden=YES;
        _myDatepicker.hidden=YES;
        
        return YES;
    } else {
        return NO;
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)bkgTapped:(id)sender {
 
    [self.view endEditing:YES];     //　画面タッチでキーボード引っ込める
    
}
- (IBAction)dateChanged:(id)sender {
}

- (IBAction)doneTapped:(id)sender {
    
    _myButton.hidden=YES;
    _myDatepicker.hidden=YES;
    _childView.hidden = YES;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyy/MM/dd";
    NSString *dayStr = [df stringFromDate:_myDatepicker.date];
    
    if(selectedTag == 2){
        _jissibiTextField.text = dayStr;
    } else if (selectedTag ==3){
        _kaisibiTextField.text = dayStr;
    } else if (selectedTag ==4){
        _simekiriTextField.text = dayStr;
    }


}
@end
