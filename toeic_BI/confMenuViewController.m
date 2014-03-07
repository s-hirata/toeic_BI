//
//  confMenuViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/02/19.
//  Copyright (c) 2014年 hirata. All rights reserved.
//
//
#import "confMenuViewController.h"
#import "shareData.h"


#import "STMenuRow.h"

#define DBNAME      @"TOEIC.DB"
#define URL     @"http://192.168.10.101:8080/prototype_sd"
#define PATH    @"/device.php?"

#define TIMEOUTINTERVAL 5.0
#define CONF_NAM    @"TOEIC_TEST"
#define CONF_FILE   @"APP_CONF"


@interface confMenuViewController ()

@property (strong, nonatomic) NSMutableArray *rows;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation confMenuViewController

shareData* sharedData;
NSString *CNpath = PATH;
NSString *CNurl;


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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"各種設定";
    
    _rows = [NSMutableArray arrayWithCapacity:10];
    
    STMenuRow *menuRow;

    menuRow = [[STMenuRow alloc] init];
    menuRow.title = @"試験マスター";
    menuRow.viewControllerClass = @"goAdminInfoViewController";
    [_rows addObject:menuRow];

    menuRow = [[STMenuRow alloc] init];
    menuRow.title = @"システム設定";
    menuRow.viewControllerClass = @"goSystemSetteiViewController";
    [_rows addObject:menuRow];

    menuRow = [[STMenuRow alloc] init];
    menuRow.title = @"地域の選択";
    menuRow.viewControllerClass = @"gotestAreaViewController";
    [_rows addObject:menuRow];
 
    menuRow = [[STMenuRow alloc] init];
    menuRow.title = @"プロフィール登録";
    menuRow.viewControllerClass = @"goProfileViewController";
    [_rows addObject:menuRow];


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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    STMenuRow *row = [_rows objectAtIndex:indexPath.row];
    
    cell.textLabel.text = row.title;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    STMenuRow *row = [_rows objectAtIndex:indexPath.row];
    
    if ([row.viewControllerClass isEqualToString:@"goAdminInfoViewController"]){
        
        if([self accessCheck]){
            
            [sharedData removeDataForKey:@"遷移元"];
            [sharedData setData:@"confMenuViewController" forKey:@"遷移元"];

            [self performSegueWithIdentifier:row.viewControllerClass sender:self];
        } else {
            ////////
            UIAlertView *alertView
            = [[UIAlertView alloc] initWithTitle:nil
                                         message:@"「プロフィール登録」をして下さい。"
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil];
            [alertView show];
            [sharedData removeDataForKey:@"遷移元"];
            [sharedData setData:@"confMenuViewController" forKey:@"遷移元"];
            
            [self performSegueWithIdentifier:@"goProfileViewController" sender:self];

            
        }

    }
    else{
        [sharedData removeDataForKey:@"遷移元"];
        [sharedData setData:@"confMenuViewController" forKey:@"遷移元"];
        
        [self performSegueWithIdentifier:row.viewControllerClass sender:self];

    }
}

-(BOOL)accessCheck{

    FMDatabase* db = [self _getDB:DBNAME];
    NSString*   sql = @"CREATE TABLE IF NOT EXISTS device (devname TEXT, devtype TEXT, syokuinid TEXT, syokui TEXT , mode TEST ,PRIMARY KEY (devname));";
    [db executeUpdate:sql];
    
    sql = @"select count(*) from device;";
    FMResultSet* results=[db executeQuery:sql];
    if ([results next]){
        if( [results intForColumnIndex:0] > 0){
            
        } else {
            return FALSE;
        }
    } else {
        return FALSE;
    }
    
    
    [db close];
    return TRUE;
}

-(void)deviceMasterCreate{
    
    NSUUID *vendorUUID = [UIDevice currentDevice].identifierForVendor;
    UIDevice *dev = [UIDevice currentDevice];
    NSString* devName = dev.name;
    NSString *deviceType = [UIDevice currentDevice].model;
    

    CNurl=[self confRead];
    NSString *str = [ CNurl stringByAppendingString: @"/device.php?"];
    str = [str stringByAppendingString: [NSString stringWithFormat:@"cmd=DEL&action=device&udid=%@",devName]];
    NSURL *wurl = [NSURL URLWithString:str];
    NSURLRequest  *request = [[NSURLRequest alloc] initWithURL:wurl cachePolicy:NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval:TIMEOUTINTERVAL];
    
    // リクエストを送信する。
    
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    FMDatabase* db = [self _getDB:DBNAME];
    NSString *syokuinid;
    NSString *sql = @"delete from device;";
    [db executeUpdate:sql];
    
    sql = @"select * from riyousya;";
    FMResultSet* results=[db executeQuery:sql];
    if([results next]){
        syokuinid=[results stringForColumnIndex:0];
    }
    sql = @"insert into device(udid, devname, devtype, syokuinid) values(?,?,?,?)";
    
    [db executeUpdate:sql,devName,devName,deviceType,syokuinid];
    str = [ CNurl stringByAppendingString: @"/device.php?"];
    str = [str stringByAppendingString: [NSString stringWithFormat:@"cmd=INS&action=device&udid=%@&devname=%@&devtype=%@&syokuinid=%@",devName,devName,deviceType,syokuinid]];
    wurl = [NSURL URLWithString:str];
    request = [[NSURLRequest alloc] initWithURL:wurl cachePolicy:NSURLRequestUseProtocolCachePolicy
                                timeoutInterval:TIMEOUTINTERVAL];
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    [db close];
    
    
}
- (NSString*)confRead
{
    NSString *fnam = CONF_FILE;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fnam];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:dbPath];
    if (!fileHandle) {
        // ファイルがいない
        
        CNurl =[sharedData getDataForKey:@"サーバURL"];
        if([CNurl length]==0){
            CNurl=URL;
        }
        
    } else{
        
        NSData *data = [fileHandle readDataToEndOfFile];        // ファイル読み込み
        // ファイルを閉じる
        [fileHandle closeFile];
        
        // NSDataをNSStringに変換する。
        CNurl = [[NSString alloc] initWithBytes:data.bytes
                                       length:data.length
                                     encoding:NSUTF8StringEncoding];
    }
    
    // NSLog(@"URL=%@",url);
    
    return CNurl;
    
}



@end

