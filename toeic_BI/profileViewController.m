//
//  profileViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/03/03.
//  Copyright (c) 2014年 hirata. All rights reserved.
//
// デバイス利用者の登録
// devName,devType,syokuinid,syokui,mode

#import "profileViewController.h"
#import "shareData.h"


#define URL     @"http://192.168.10.101:8080/prototype_sd"
//#define PATH    @"/prototype_sd/dlconf.php?name="
#define PATH    @"/device.php?"

#define TIMEOUTINTERVAL 5.0
#define CONF_NAM    @"TOEIC_TEST"
#define CONF_FILE   @"APP_CONF"
#define DBNAME      @"TOEIC.DB"


@interface profileViewController ()
@property (weak, nonatomic) IBOutlet UITextField *syokuininTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *syokuiTextField;
- (IBAction)shouldEditingBegin:(id)sender;

@end

@implementation profileViewController

UIToolbar * PRstack_toolbar;

NSString *PRpath = PATH;

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
        // Custom initialization
    }
    return self;
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
	PRstack_toolbar.frame = CGRectMake( 0, parentSize.height - newHeight, parentSize.width, newHeight );
}

- ( void )willAnimateRotationToInterfaceOrientation:( UIInterfaceOrientation )toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[ super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration ];
	
	// デバイスの回転アニメーションが発生するタイミングで、ツールバーの位置とサイズを調整する
	[ self layoutToolbar:toInterfaceOrientation ];
}

-(void)viewWillAppear:(BOOL)animated{

[ super viewWillAppear:animated ];

// ViewControllerが表示されるタイミングで、ツールバーの位置とサイズを調整する
[ self layoutToolbar:self.interfaceOrientation ];


[self.navigationController setNavigationBarHidden:NO animated:YES]; // ナビゲーションバー表示
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
                 action:@selector(onTapButton:)
       forControlEvents:UIControlEventTouchUpInside];
    cfButton.frame = CGRectMake(10, 10, 60, 30);
    [cfButton setTitle:@"更新" forState:UIControlStateNormal];
    UIBarButtonItem* cfButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cfButton];
    
    // 可変間隔のスペーサーを作成する
    UIBarButtonItem * flexibleSpacer = [ [ UIBarButtonItem alloc ]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                        target:nil
                                        action:nil ];
    
    
    UIDevice *dev = [UIDevice currentDevice];
    NSString* devName = dev.name;
    
    toolBar.items = [ NSArray arrayWithObjects:
                         flexibleSpacer,
                         cfButtonItem,
                         nil ];
    
    PRstack_toolbar = toolBar;
    
    FMDatabase* db = [self _getDB:DBNAME];
    NSString*   sql = @"select syokuinid,syokui from device;";
    FMResultSet* results=[db executeQuery:sql];
    if ([results next]){
        _syokuininTextField.text = [results stringForColumnIndex:0];
        _syokuiTextField.text = [results stringForColumnIndex:1];
    }
            

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


-(void)onTapButton:(id)sender{
    NSString * url;
    url=[self confRead];
    NSString* mode;
    UIDevice *dev = [UIDevice currentDevice];
    NSString* devName = dev.name;
    NSString *deviceType = [UIDevice currentDevice].model;
    

    
    if( ([_syokuiTextField.text isEqualToString:@"Director"]) ||
        ([_syokuiTextField.text isEqualToString:@"GM"]) ||
        ([_syokuiTextField.text isEqualToString:@"UM"])){
        
        mode = @"Server";
        
    } else {
        mode = @"Local";
    }

    FMDatabase* db = [self _getDB:DBNAME];
    NSString*   sql = @"CREATE TABLE IF NOT EXISTS device (devname TEXT, devtype TEXT, syokuinid TEXT, syokui TEXT , mode TEST ,PRIMARY KEY (devname));";
    [db executeUpdate:sql];
    sql = @"delete from device;";
    [db executeUpdate:sql];
    sql = @"insert into device(devname,devtype,syokuinid,syokui, mode) values(?,?,?,?,?)";
    [db executeUpdate:sql,devName, deviceType,  _syokuininTextField.text,_syokuiTextField.text,mode];

    
    NSString* str = [ url stringByAppendingString: @"/device.php?"];
    str = [str stringByAppendingString: [NSString stringWithFormat:@"cmd=UPD&action=device&devname=%@&devtype=%@&syokuinid=%@&syokui=%@&adminMasterMode=%@",devName, deviceType,  _syokuininTextField.text,_syokuiTextField.text,mode]];
    NSURL *wurl = [NSURL URLWithString:str];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:wurl cachePolicy:NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval:TIMEOUTINTERVAL];
    NSError *error;
    NSURLResponse *response;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    

    
    [db close];

    
   
    
    UIAlertView *alertView
    = [[UIAlertView alloc] initWithTitle:nil
                                 message:@"登録しました"
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil];
    [alertView show];
    
}
- (IBAction)shouldEditingBegin:(id)sender {
  
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"職位" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Director", @"GM",@"UM",@"TL",@"ATL",@"Staff" ,nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        [actionSheet showInView:self.view];
    
    [ self.view endEditing: YES ];
        
    
}
-(void)actionSheet:(UIActionSheet*)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            // １番目のボタンが押されたときの処理を記述する
            _syokuiTextField.text = @"Director";
            break;
        case 1:
            // ２番目のボタンが押されたときの処理を記述する
            _syokuiTextField.text = @"GM";
            
            break;
        case 2:
            // ３番目のボタンが押されたときの処理を記述する
            _syokuiTextField.text = @"UM";
            
            break;
        case 3:
            // ３番目のボタンが押されたときの処理を記述する
            _syokuiTextField.text = @"TL";
            
            break;
        case 4:
            // ３番目のボタンが押されたときの処理を記述する
            _syokuiTextField.text = @"ATL";
            
            break;
        case 5:
            // 4番目のボタンが押されたときの処理を記述する
            _syokuiTextField.text = @"Staff";
            
            break;
        default:
              break;
    }
    
}


- (IBAction)onBkgTapped:(id)sender {
      [ self.view endEditing: YES ];
    
}
@end
