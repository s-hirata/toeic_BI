//
//  testAreaViewController.m
//  toeic_BI
//
//  Created by hirata on 2014/03/01.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import "testAreaViewController.h"
#import "shareData.h"
#import "LGrow.h"
#define URL     @"http://192.168.10.101:8080/prototype_sd"
#define PATH    @"/areadl.php?"
#define TIMEOUTINTERVAL 5.0
#define CONF_FILE   @"APP_CONF"
#define DBNAME      @"TOEIC.DB"



@interface testAreaViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *rows;



@end

@implementation testAreaViewController

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
    NSString *cell=[sharedData getDataForKey:@"地域の選択"];
    
    self.title = cell;
    
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
- (void)cellsSet
{
    
    LGrow *aRow;
    
    NSString * url;
    url=[self confRead];
    [sharedData setData:url forKey:@"サーバURL"];
    NSString *str = [ url stringByAppendingString: PATH];
    
    NSURL *wurl = [NSURL URLWithString:str];
    NSURLRequest  *request = [[NSURLRequest alloc] initWithURL:wurl cachePolicy:NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval:TIMEOUTINTERVAL];
    
    // リクエストを送信する。
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    [self tableinsert:data];        // データベースにインポート
    
    FMDatabase* db = [self _getDB:DBNAME];
    NSString *sql = @"select count(*) from testarea;";
    FMResultSet* results=[db executeQuery:sql];
    if ([results next]){
        
 //       NSLog(@"%d",[results intForColumnIndex:0]);
        _rows = [NSMutableArray arrayWithCapacity:[results intForColumnIndex:0]];
    } else {
        NSLog(@"result FALSE");
        return;
    }
    
    sql = @"select * from testarea;";
    results=[db executeQuery:sql];
    
    
    while( [results next] ){
        
        aRow = [[LGrow alloc] init];
        
        aRow.title =[NSString stringWithFormat:@"%@",[results stringForColumnIndex:1]];
        aRow.no =[NSString stringWithFormat:@"%@",
                    [results stringForColumnIndex:0] ];
        aRow.body =[NSString stringWithFormat:@"%@",
                    [results stringForColumnIndex:2] ];
        
  //                  NSLog(@"row----->%@:%@",aRow.title,aRow.body);
        
        [_rows addObject:aRow];
        
    }
    
    [db close];
    
    [_tableView reloadData];
    
    
}
-(void) tableinsert:(NSData *)data{   // test areaをsqlitetableにインサートする
    //
    
    FMDatabase* db = [self _getDB:DBNAME];
    
    NSString*   sql = @"CREATE TABLE IF NOT EXISTS testarea (no TEXT ,name TEXT , selected TEXT);";
    [db executeUpdate:sql];
    
    sql = @"select count(*) from testarea;";
    FMResultSet* results=[db executeQuery:sql];
    if ([results next]){
        if ([results intForColumnIndex:0] > 0){
            return;
        }
    }

    sql = @"delete from testarea;";
    [db executeUpdate:sql];
    
    sql = @"insert into testarea(no,name,selected ) values(?,?,?);";
    
    NSString *text
    = [[NSString alloc] initWithBytes:data.bytes
                               length:data.length
                             encoding:NSShiftJISStringEncoding];
    
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    
    for (NSString *row in lines) {
        
        NSArray *items = [row componentsSeparatedByString:@","];
        
        if( 2 == [items count] ){
            
                  //     NSLog(@"%@%@",[items objectAtIndex:0] ,
                  //           [items objectAtIndex:1]  );
            
            [db executeUpdate:sql, [items objectAtIndex:0] ,
             [items objectAtIndex:1], @"0"] ;
            
        }
    }
    [db close];
    
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
	// Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"CellID";
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
        //      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    
    LGrow *aRow = [_rows objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    cell.textLabel.text = aRow.title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UISwitch* sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    [sw addTarget:self action:@selector(cahngeSwitch:) forControlEvents:UIControlEventValueChanged];
    sw.tag = indexPath.row;
    cell.accessoryView = sw;
    if( [aRow.body isEqualToString:@"1"]){
        [sw setOn:YES];
    } else {
        [sw setOn:NO];
    }

    
    return cell;
}
- (void)cahngeSwitch:(UISwitch*)sender
{
    UISwitch *sw = (UISwitch *)sender;
    NSString* sql;
    FMDatabase* db = [self _getDB:DBNAME];
    LGrow *aRow = [_rows objectAtIndex:sw.tag];

    if(sw.on){
        sql = @"update testarea set selected = '1' where no=?;";
        aRow.body = @"1";
    } else {
        sql = @"update testarea set selected = '0' where no=?;";
        aRow.body = @"0";
    }
    [db executeUpdate:sql, aRow.no];

    [_rows replaceObjectAtIndex:sw.tag withObject:aRow];
 //   NSLog(@"update %ld %@",(long)sw.tag, aRow.title);
    
    [db close];
 
}
#pragma mark - UITableViewDelegate


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
    //    LGrow *aRow = (LGrow*)[_rows objectAtIndex:indexPath.row];
    //
    //    [sharedData setData:aRow.title forKey:@"選択セル"];
    //
    //
    //    [sharedData removeDataForKey:@"遷移元"];
    //    [sharedData setData:@"logViewController" forKey:@"遷移元"];
    //    
    //    [self performSegueWithIdentifier:@"goLogDatail" sender:self];
}



@end
