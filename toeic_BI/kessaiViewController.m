//
//  kessaiViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/03/05.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import "kessaiViewController.h"
#import "shareData.h"
#import "PayRow.h"
#define DBNAME      @"TOEIC.DB"
#define CONF_FILE   @"APP_CONF"
#define URL     @"http://192.168.10.101:8080/prototype_sd"
#define PATH    @"/sqlite.php?"
#define TIMEOUTINTERVAL 5.0


@interface kessaiViewController ()
@property (strong, nonatomic) NSMutableArray *rows;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation kessaiViewController

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
        
        //       NSLog(@"initWithNiBName");
        // 共有データインスタンスを取得
        sharedData = [shareData instance];
        
    }
    
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSString * url;
    NSString *fnam = CONF_FILE;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fnam];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:dbPath];
    if (!fileHandle) {
        // ファイルがいない
        
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
    
//   [self startAnimation];  // くるくる　スタート
    
    // 同期通信
    // 送信するリクエストを作成する。
    NSString* syubetu = [sharedData getDataForKey:@"試験種別"];
    NSString* jissikai = [sharedData getDataForKey:@"実施回"];
    NSString* nm=[syubetu stringByAppendingString:jissikai];
    
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
    
    NSString *str = [ url stringByAppendingString:@"/dl_pay.php?"];
    fnam = [NSString stringWithFormat:@"name=%@&cmd=%@",nm ,@"DL"];
    
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
    NSString *text
    = [[NSString alloc] initWithBytes:data.bytes
                               length:data.length
                             encoding:NSShiftJISStringEncoding];
    
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    
    _rows = [NSMutableArray arrayWithCapacity:30];
    PayRow *aRow;

    // 数値を3桁ごとカンマ区切り形式で文字列に変換する

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setGroupingSeparator:@","];
    [formatter setGroupingSize:3];
    
    int ninzukei=0;
    int amountkei=0;
    for (NSString *row in lines) {
        
        NSArray *items = [row componentsSeparatedByString:@","];
        
        if( 4<= [items count] ){
            
            NSString *ninzuStr = (NSString *)[items objectAtIndex:2];    // 累計申込人数
            NSInteger ninzu = ninzuStr.integerValue;
            
            NSString *amountStr = (NSString *)[items objectAtIndex:3];    // 累計入金額
            NSInteger amount = amountStr.integerValue;
            
            ninzukei = ninzukei + ninzu;
            amountkei = amountkei + amount;


 
            NSNumber *n = [[NSNumber alloc] initWithInteger:ninzu];
            NSNumber *m = [[NSNumber alloc] initWithInteger:amount];
            // 数値を3桁感幕切りの文字列に整形する
            NSString *numberStr =[formatter stringFromNumber:n];
            NSString *mountStr = [formatter stringFromNumber:m];
            
            aRow = [[PayRow alloc] init];
            if([[items objectAtIndex:1] isEqualToString:@"999"]){
                aRow.title = [items objectAtIndex:0];
            } else {
                NSString *ms =[NSString stringWithFormat:@"%@　%@",[items objectAtIndex:0],[items objectAtIndex:1]];
                aRow.title=ms;
            }
            aRow.ninzu=numberStr;
            aRow.amount=mountStr;
            [_rows addObject:aRow];

        }
    }
 
    aRow = [[PayRow alloc] init];
    aRow.title=@"合計";
    NSNumber *n = [[NSNumber alloc] initWithInteger:ninzukei];
    NSNumber *m = [[NSNumber alloc] initWithInteger:amountkei];
    // 数値を3桁感幕切りの文字列に整形する
    NSString *numberStr =[formatter stringFromNumber:n];
    NSString *mountStr = [formatter stringFromNumber:m];
    aRow.ninzu=numberStr;
    aRow.amount=mountStr;
    [_rows addObject:aRow];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    

}

- (void)viewWillAppear:(BOOL)animated
{
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // ナビゲーションバー表示
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // ナビゲーションバー非表示
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle  reuseIdentifier:cellIdentifier];
 //       cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    PayRow *aRow = [_rows objectAtIndex:indexPath.row];

    cell.textLabel.font =
    　　[UIFont systemFontOfSize:[UIFont systemFontSize]];
    cell.detailTextLabel.font =
    　　[UIFont systemFontOfSize:[UIFont systemFontSize]];
    NSString*ms =[NSString stringWithFormat:@"%@",aRow.title];
    cell.textLabel.text = ms;
    ms =[NSString stringWithFormat:@"%@人　　%@円",aRow.ninzu,aRow.amount];
//    cell.detailTextLabel.textAlignment = UITextAlignmentRight;
//    [cell.detailTextLabel setTextAlignment:UITextAlignmentRight];
//    [cell.detailTextLabel alignmentRectForFrame:<#(CGRect)#>
    cell.detailTextLabel.text = ms;
//    UILabel *label=[[UILabel alloc] init];
//    label.text = ms;
//    [cell.accessoryView addSubview:label];
//    UILabel *label = [[UILabel alloc] init];
//    label.text = ms;
//    [cell.contentView addSubview:label];
//


    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    

    //    STMenuRow *row = [_rows objectAtIndex:indexPath.row];
//    
//    if ([row.viewControllerClass isEqualToString:@"goAdminInfoViewController"]){
//        
//        if([self accessCheck]){
//            
//            [sharedData removeDataForKey:@"遷移元"];
//            [sharedData setData:@"confMenuViewController" forKey:@"遷移元"];
//            
//            [self performSegueWithIdentifier:row.viewControllerClass sender:self];
//        } else {
//            ////////
//            UIAlertView *alertView
//            = [[UIAlertView alloc] initWithTitle:nil
//                                         message:@"初期画面の「設定ボタン」から「プロフィール登録」をして下さい。"
//                                        delegate:nil
//                               cancelButtonTitle:@"OK"
//                               otherButtonTitles:nil];
//            [alertView show];
//            [sharedData removeDataForKey:@"遷移元"];
//            [sharedData setData:@"confMenuViewController" forKey:@"遷移元"];
//            
//            [self performSegueWithIdentifier:@"goProfileViewController" sender:self];
//            
//            
//        }
//        
//    }
//    else{
//        [sharedData removeDataForKey:@"遷移元"];
//        [sharedData setData:@"confMenuViewController" forKey:@"遷移元"];
//        
//        [self performSegueWithIdentifier:row.viewControllerClass sender:self];
//        
//    }
}


@end
