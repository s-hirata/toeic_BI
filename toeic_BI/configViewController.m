//
//  configViewController.m
//  
//
//  Created by hirata on 2014/02/06.
//
//

#import "configViewController.h"
#import "shareData.h"

#define CONF_FILE   @"APP_CONF"

@interface configViewController ()

@end

@implementation configViewController

NSString *url;

// 共有データ置き場へのポインタ
shareData* sharedData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        // 共有データインスタンスを取得
        sharedData = [shareData instance];

    }
    return self;
}
- (void)onTapBkButton:(id)sender {
    
    //　戻るボタン
    
    [sharedData setData:@"configViewController" forKey:@"遷移元"];

    [self.navigationController popViewControllerAnimated:YES];
    
}
-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // ナビゲーションバー表示
    
    [self confRead];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyy/MM/dd";
    NSDate * wday = [sharedData getDataForKey:@"当日日付"];
    NSString *todayStr = [df stringFromDate:wday];
    
    NSString *wlabel=@"只今の日付は、";
    wlabel = [wlabel stringByAppendingPathComponent:todayStr];
    _tempDateLabel.text=wlabel;
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // ナビゲーションバー非表示
}


- (void)confRead
{
    NSString *fnam = CONF_FILE;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fnam];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:dbPath];
    if (!fileHandle) {
        // ファイルがいない
        
        url =[sharedData getDataForKey:@"サーバURL"];
        
    } else{
        
        NSData *data = [fileHandle readDataToEndOfFile];        // ファイル読み込み
        // ファイルを閉じる
        [fileHandle closeFile];
        
        // NSDataをNSStringに変換する。
        url = [[NSString alloc] initWithBytes:data.bytes
                                       length:data.length
                                     encoding:NSUTF8StringEncoding];
    }
    
   // NSLog(@"URL=%@",url);
    
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self confRead];
    
    _urlTextField.hidden = YES;
    _urlLabel.hidden = YES;
    _workDayPicker.hidden = YES;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyy/MM/dd";
    NSDate * wday = [sharedData getDataForKey:@"当日日付"];
    NSString *todayStr = [df stringFromDate:wday];

    NSString *wlabel=_tempDateLabel.text;
    wlabel = [wlabel stringByAppendingPathComponent:todayStr];
    _tempDateLabel.text=wlabel;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)swChanged:(id)sender {
    UISwitch *sw = sender;
    if (sw.on) {
     //   NSLog(@"スイッチがONになりました．");
        _urlTextField.hidden = NO;
        _urlLabel.hidden = NO;
        url =[sharedData getDataForKey:@"サーバURL"];
        _urlTextField.text = url;

        
    } else {
       // NSLog(@"スイッチがOFFになりました．");
        
        if ([self fileWrite] == YES){
            
            // 共有データに設定データをセット
            url = _urlTextField.text;
            [sharedData setData:url forKey:@"サーバURL"];
            _urlTextField.hidden = YES;
            _urlLabel.hidden = YES;
            
            [sharedData setData:@"configViewController" forKey:@"遷移元"];

            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }
    
}
- (IBAction)bkgTapped:(id)sender {
    
    [self.view endEditing:YES];     //　画面タッチでキーボード引っ込める
    
}

- (BOOL) fileWrite {    // 変更したURLをデバイスに書き出す
    
    if([_urlTextField.text length ] == 0){
        return FALSE;
    }
    
    NSString *fnam = CONF_FILE;
    
    
    // 注意．
    // ファイルに書き込もうとしたときに該当のファイルが存在しないとエラーになるため
    // ファイルが存在しない場合は空のファイルを作成する
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fnam];
    
    NSString *text = _urlTextField.text;
    NSData *data = [NSData dataWithBytes:text.UTF8String
                                  length:text.length];
    
    
    // ファイルが存在しないか?
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {  // ファイルがいない
        //空のファイルを作成する
        BOOL result = [[NSFileManager defaultManager] createFileAtPath:dbPath contents:nil attributes:nil];
        //ファイル作成が失敗した場合
        if (!result) {
            NSLog(@"%@:settei-1:空ファイルの作成に失敗",dbPath);
            return NO;
        }
        // ファイルハンドルを作成する
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:dbPath];
        if (!fileHandle) {
            NSLog(@"%@:settei-2:ファイルハンドルの作成に失敗",dbPath);
            return NO;
        }
        
        // ファイルを閉じる
        [fileHandle closeFile];
        
    }
    
    // ファイルハンドルを作成する
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:dbPath];
    if (!fileHandle) {
        NSLog(@"%@:settei-3:ファイルハンドルの作成に失敗",dbPath);
        return NO;
    }
    
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:dbPath contents:data attributes:nil];
    //ファイル作成が失敗した場合
    if (!result) {
        NSLog(@"%@:settei-4:ファイルの作成に失敗",dbPath);
        return NO;
    }
    // ファイルを閉じる
    [fileHandle closeFile];
    
  //  NSLog(@"APP_CONF ファイル書きました");
    
    return YES;
}


- (IBAction)dateSwChanged:(id)sender {
    
    UISwitch *sw = sender;
    if (sw.on) {

        _workDayPicker.hidden = NO;
        
    } else {
        // NSLog(@"スイッチがOFFになりました．");
        
        [sharedData setData:_workDayPicker.date forKey:@"当日日付"];
     //   NSLog(@" date=%@",_workDayPicker.date);

        _workDayPicker.hidden = YES;
        
        [sharedData setData:@"configViewController" forKey:@"遷移元"];

        [self.navigationController popViewControllerAnimated:YES];
     
        }
        
    }


- (IBAction)datePickerChandeg:(id)sender {
    
    [sharedData setData:_workDayPicker.date forKey:@"当日日付"];
    //NSLog(@" date=%@",_workDayPicker.date);
}
@end
