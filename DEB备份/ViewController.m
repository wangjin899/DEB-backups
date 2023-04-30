//
//  ViewController.m
//  DEB备份
//
//  Created by 隔壁老王 on 2023/4/23.
//

#import <spawn.h>
#import "ViewController.h"

extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);
extern int posix_spawnattr_setenv(const posix_spawnattr_t* , char**, uid_t);
@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

//@property (nonatomic) bool open;
@property (nonatomic, strong) NSArray *myData;
@property (nonatomic, strong) NSArray *myDatax;
@property (nonatomic, strong) UITableView *tableView;

@end
ViewController*vc;
static bool type,openall;
@implementation ViewController


NSString *jbpath,*cmdpath;int jbtype;


static NSString* spawnRoot(NSArray* argss){
    NSMutableArray*args = argss.mutableCopy;
    if(![args[0] containsString:@"/var/"]){
        args[0] = [cmdpath stringByAppendingString:argss[0]];
    }
    NSMutableString *output = [NSMutableString string]; // 用于保存输出的字符串
    char **argv = (char **)malloc((args.count + 1) * sizeof(char*));
    for (NSUInteger i = 0; i < args.count; i++){
        argv[i] = strdup([args[i] UTF8String]);
    }
    argv[args.count] = NULL;
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr); // 初始化 spawn 属性结构体
    
    posix_spawnattr_set_persona_np(&attr, 99, 1); // 设置用户身份以 root 运行
    posix_spawnattr_set_persona_uid_np(&attr, 0); // 设置用户 ID 为 0
    posix_spawnattr_set_persona_gid_np(&attr, 0); // 设置用户组 ID 为 0
    
    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action); // 初始化 spawn 文件操作结构体
    
    // 创建管道以捕获 stdout 和 stderr 输出
    int stdoutPipe[2];
    pipe(stdoutPipe);
    
    // 设置文件操作以将 stdout 和 stderr 重定向到管道
    posix_spawn_file_actions_adddup2(&action, stdoutPipe[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&action, stdoutPipe[0]);
    
    pid_t task_pid; // 进程 ID
    int status = -200; // 用于保存子进程的退出状态码
    const char *path[] = {"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/jb/usr/bin:/var/jb/bin", NULL}; // 设置环境变量
    
    int spawnError = posix_spawn(&task_pid, argv[0], &action, &attr, (char* const*)argv, (char**)path); // 使用 spawn 函数启动子进程
    
    posix_spawnattr_destroy(&attr); // 销毁 spawn 属性结构体
    for (NSUInteger i = 0; i < args.count; i++){ // 释放分配的内存
        free(argv[i]);
    }
    free(argv);
    
    if(spawnError != 0){ // 如果启动子进程失败，打印错误信息并返回错误码
        NSLog(@"posix_spawn error %d\n", spawnError);
        return output;
    }
    
    close(stdoutPipe[1]); // 关闭管道的写端和错误端
    char buffer[4096]; // 用于保存读取的输出
    
    // 从管道读取 stdout 输出并将其打印到控制台
    ssize_t bytesRead;
    while ((bytesRead = read(stdoutPipe[0], buffer, sizeof(buffer))) > 0) { // 循环读取输出
        NSString *outt = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
        [output appendString:outt];// 将输出保存到字符串中
    }
    
    if (waitpid(task_pid, &status, 0) != -1) {
        NSLog(@"Child status %d", WEXITSTATUS(status));
    } else {
        perror("waitpid");
        return output;
    }
    NSLog(@"%@", output);
    return output;//WEXITSTATUS(status);//打印输出结果
}

- (void)获取已安装{
    NSString *p = [jbpath stringByAppendingFormat:@"/Library/dpkg/status"];
    NSString *packageInfo = [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil];
    NSArray *packages = [packageInfo componentsSeparatedByString:@"\n\n"];
    NSMutableArray*arr = [NSMutableArray array];
    for (NSString *pkg in packages) {
        NSArray *lines = [pkg componentsSeparatedByString:@"\n"];
        NSMutableDictionary *packageDict = [NSMutableDictionary dictionary];
        for (NSString *line in lines) {
            NSArray *parts = [line componentsSeparatedByString:@": "];
            if (parts.count == 2) {
                NSString *key = parts[0];
                NSString *value = parts[1];
                [packageDict setObject:value forKey:key];
            }
        }
        if([packageDict[@"Name"] length]){
            [arr addObject:packageDict];
        }else{
            if(packageDict[@"Package"]&&openall){
                [packageDict setObject:packageDict[@"Package"] forKey:@"Name"];
                [arr addObject:packageDict];
            }
        }
    }
    self.myData = arr;
}
- (void)获取已备份{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = @"/var/mobile/Documents/DebBackup";
    BOOL isDirectory = NO;
    if([fileManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
        NSMutableArray*arr = [NSMutableArray array];
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
        for (NSString *fileName in enumerator) {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            if ([fileName.pathExtension isEqual:@"deb"]) {
                NSMutableDictionary*Info = read_control_info(filePath.UTF8String);
                [Info setObject:filePath forKey:@"Path"];
                [arr addObject:Info];
            }
        }
        self.myData = arr;
    }else{
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)openAll:(bool)op{
    openall = op;
    [vc 获取已安装];
    [vc.tableView reloadData];
}
- (void)selectedSegmentIndexxxxx:(NSString *)Index xxxxx:(NSString *)cmd{
    jbpath = Index;
    cmdpath = cmd;
    NSLog(@"%@",jbpath);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    vc = self;
    //    self.title = @"已安装";
    self.navigationItem.title = @"已安装的插件";
    dispatch_async(dispatch_get_main_queue(), ^{
        LaunchPageViewController *viewController = [[LaunchPageViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        [self presentViewController:navController animated:YES completion:nil];
    });
    
    Class PSAppDataUsagePolicyCache = NSClassFromString(@"PSAppDataUsagePolicyCache");
    id cacheInstance = [PSAppDataUsagePolicyCache valueForKey:@"sharedInstance"];
    SEL selector = NSSelectorFromString(@"setUsagePoliciesForBundle:cellular:wifi:");
    ((bool(*)(id, SEL, NSString *, BOOL, BOOL))objc_msgSend)(cacheInstance, selector,NSBundle.mainBundle.bundleIdentifier, true, true);
    
    //    jbpath = @"";
    //    jbtype = JB_Root;
    //    NSFileManager *fileManager = [NSFileManager defaultManager];
    //    if([fileManager fileExistsAtPath:@"/var/jb/Library/dpkg/status"]){
    //        jbtype = JB_FUGU;//fugu
    //        jbpath = @"/var/jb";
    //    }
    //    if([fileManager fileExistsAtPath:@"/var/LIY/dpkg/status"]){
    //        jbtype = JB_Xina;//xina
    //        jbpath = @"/var";
    //    }
    
    //    NSMutableDictionary*Info = read_control_info("/var/mobile/Documents/kGame.ios15.fugu_1.0.0-2_iphoneos-arm64.deb");
    //    NSLog(@"%@",Info);
    //    Info = read_control_info("/var/mobile/Documents/TouchflowX_1.0.6.deb");
    //    NSLog(@"%@",Info);
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self 获取已安装];
        [self.navigationController.navigationBar setHidden:1]; // 显示导航栏
        [self.navigationController.navigationBar.topItem setTitle:@"已安装的插件"]; // 设置导航栏标题
        
        self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedSectionHeaderHeight = 300.0;
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
        [self.view addSubview:self.tableView];
        
        self.bottomMenu = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 70, CGRectGetWidth(self.view.bounds), 70)];
        self.bottomMenu.backgroundColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
        [self.view addSubview:self.bottomMenu];
        
        self.buttonArray = @[].mutableCopy;
        CGFloat buttonWidth = CGRectGetWidth(self.view.bounds) / 2.0;
        NSArray *buttonTitles = @[@"已安装插件", @"已备份插件"];
        UIColor *selectedColor = [UIColor grayColor];
        for (int i = 0; i < buttonTitles.count; i++) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(buttonWidth * i, 0, buttonWidth, 70)];
            [button setTitle:buttonTitles[i] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(bottomMenuButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            button.tag = i;
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(button.frame.size.width , 10, 1, 70)];
            separator.backgroundColor = [UIColor darkGrayColor];
            [self.bottomMenu addSubview:separator];
            [self.bottomMenu addSubview:button];
            [self.buttonArray addObject:button];
            [button setBackgroundImage:[self imageWithColor:selectedColor] forState:UIControlStateSelected];
        }
    });
}
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)bottomMenuButtonClicked:(UIButton *)sender {
    for (UIButton *button in self.buttonArray) {
        if(button.tag != sender.tag){
            button.selected = NO;
        }else{
            button.selected = YES;
        }
    }
    if(!sender.tag){
        [self 获取已安装];
        [self.tableView reloadData];
        type = false;
    }else{
        type = true;
        [self 获取已备份];
        [self.tableView reloadData];
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.myData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    if(type==false){
        NSDictionary*js = self.myData[indexPath.row];
        cell.textLabel.text = js[@"Name"];
        //        cell.detailTextLabel.text = self.myData[indexPath.row][@"Package"];
        cell.detailTextLabel.text = [js[@"Version"] stringByAppendingFormat:@" | %@\n%@",js[@"Architecture"],js[@"Package"]];
    }else{
        NSDictionary*js = self.myData[indexPath.row];
        NSString*name = js[@"Name"];
        cell.textLabel.text = name ? name : js[@"Package"];
        cell.detailTextLabel.text = [js[@"Version"] stringByAppendingFormat:@" | %@\n%@",js[@"Architecture"],js[@"Package"]];
    }
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = @"";
    if(type==TRUE)title = @"已备份的插件，点击操作";
    if(type==TRUE && self.myData.count==0)title = @"没有备份插件数据";
    if(type==false && self.myData.count==0)title = @"你可能不在越狱状态或权限不足\n要用巨魔安装此程序";
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.numberOfLines = 0;
    headerLabel.preferredMaxLayoutWidth = tableView.bounds.size.width;
    
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.text = title;
    headerLabel.numberOfLines = 0;
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    return headerLabel;
}
- (CGFloat)textHeight:(NSString *)text {
    CGSize size = CGSizeMake(self.view.frame.size.width, CGFLOAT_MAX);
    CGRect rect = [text boundingRectWithSize:size
                                     options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                     context:nil];
    return ceil(rect.size.height);
}
- (void)handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.textView setHidden:YES];
    }
}
- (void)setTextViewframe{
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat screenwidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat tablewidth = self.tableView.frame.size.width;
    CGFloat screenheight = [UIScreen mainScreen].bounds.size.height;
    CGFloat textHeight = [self textHeight:self.textView.text];
    if(textHeight<screenheight){
        self.textView.frame = CGRectMake(0, screenheight/2-textHeight/2,screenwidth,textHeight+20);
    }else{
        self.textView.frame = CGRectMake(0, navBarHeight,screenwidth,screenheight-navBarHeight);
    }
    NSRange range = NSMakeRange(self.textView.text.length - 1, 1);
    [self.textView scrollRangeToVisible:range];
}
- (void)ShowtextView:(NSString*)text{
    if(!self.textView){
        self.textView = [[UITextView alloc] init];
        self.textView.editable = NO;
        self.textView.scrollEnabled = YES;
        self.textView.backgroundColor = [UIColor orangeColor];
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        self.textView.font = [UIFont systemFontOfSize:14.0];
        [self.textView addGestureRecognizer:doubleTapGesture];
        [self.view addSubview:self.textView];
    }
    [self.textView setHidden:NO];
    self.textView.text = text;
    [self setTextViewframe];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(type==false){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.myData[indexPath.row][@"Name"] message:self.myData[indexPath.row][@"Package"] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"备份此插件" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.myData[indexPath.row][@"Name"] message:self.myData[indexPath.row][@"Package"] preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"备份当前插件" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提醒" message:@"如果插件较大\n本App可能会卡一会儿" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定备份" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
                    NSMutableString*text = [NSMutableString alloc].init;
                    [self ShowtextView:text];
                    NSArray*arr = [self 打包:indexPath.row];
                    [text appendFormat:@"备份日志(双击隐藏)：\n插件名字：%@\n文件路径：%@",arr[0],arr[1]];
                    [self.textView setText:text];
                    [self setTextViewframe];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
                [self.view.window.rootViewController presentViewController:alert animated:true completion:nil];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
            [self.view.window.rootViewController presentViewController:alert animated:true completion:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"插件详情" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            NSDictionary *dictionary = self.myData[indexPath.row];
            NSString *resultString = @"";
            for (NSString *key in dictionary) {
                id value = [dictionary objectForKey:key];
                resultString = [resultString stringByAppendingFormat:@"%@: %@\n", key, value];
            }
            [self ShowtextView:[@"插件信息(双击隐藏)：\n" stringByAppendingString:resultString]];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"一键备份所有插件" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提醒" message:@"备份所有插件会很耗时\n本App可能会卡一会儿" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定备份" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
                [self BackupAll];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
            [self.view.window.rootViewController presentViewController:alert animated:true completion:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
        [self.view.window.rootViewController presentViewController:alert animated:true completion:nil];
    }else{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.myData[indexPath.row][@"Name"] message:self.myData[indexPath.row][@"Package"] preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"跳转Filza" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            NSString *filePath = self.myData[indexPath.row][@"Path"];
            NSCharacterSet *CharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
            NSString *encodedURLString = [filePath stringByAddingPercentEncodingWithAllowedCharacters:CharacterSet];
            NSURL *filzaURL = [NSURL URLWithString:[@"filza://view" stringByAppendingString:encodedURLString]];
            [[UIApplication sharedApplication] openURL:filzaURL options:@{} completionHandler:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"deb详情" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            NSDictionary *dictionary = self.myData[indexPath.row];
            NSString *resultString = @"";
            for (NSString *key in dictionary) {
                id value = [dictionary objectForKey:key];
                resultString = [resultString stringByAppendingFormat:@"%@: %@\n", key, value];
            }
            [self ShowtextView:[@"插件信息(双击隐藏)：\n" stringByAppendingString:resultString]];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"删除备份" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除" message:self.myData[indexPath.row][@"Name"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
                [fileManager removeItemAtPath:self.myData[indexPath.row][@"Path"] error:nil];
                [self 获取已备份];
                [self.tableView reloadData];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
            [self.view.window.rootViewController presentViewController:alert animated:true completion:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"安装此插件" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.myData[indexPath.row][@"Name"] message:@"插件可能会有依赖\n确保越狱商店已安装所需依赖" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"继续安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
                NSString * filePath = self.myData[indexPath.row][@"Path"];
                NSString *cmdout = spawnRoot(@[@"dpkg",@"-i",filePath]);
                [self ShowtextView:[@"安装日志(双击隐藏)：\n" stringByAppendingString:cmdout]];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
            [self.view.window.rootViewController presentViewController:alert animated:true completion:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"安装所有备份" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"插件可能会有依赖\n确保越狱商店已安装所需依赖" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
                [self 安装所有];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
            [self.view.window.rootViewController presentViewController:alert animated:true completion:nil];
        }]];
        
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
        [self.view.window.rootViewController presentViewController:alert animated:true completion:nil];
    }
}
- (void)BackupAll{
    NSMutableString*text = [NSMutableString alloc].init;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for(int i=0;i<self.myData.count;i++){
            NSArray*arr=[self 打包:i];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self ShowtextView:text];
                [text appendFormat:@"备份日志(双击隐藏)：\n插件名字：%@\n文件路径：%@\n\n",arr[0],arr[1]];
                [self.textView setText:text];
                [self setTextViewframe];
            });
        }
    });
}

- (void)安装所有{
    NSMutableString*text = [NSMutableString alloc].init;
    [self ShowtextView:text];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for(int i=0;i<self.myData.count;i++){
            NSString * filePath = self.myData[i][@"Path"];
            NSString *cmdout = spawnRoot(@[@"dpkg",@"-i",filePath]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [text appendFormat:@"安装日志(双击隐藏)：%@\n%@\n",self.myData[i][@"Name"],cmdout];
                [self.textView setText:text];
                [self setTextViewframe];
            });
        }
    });
}
- (NSArray*)打包:(NSInteger)index{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString*name = self.myData[index][@"Name"];
    NSString*Version = self.myData[index][@"Version"];
    NSString*Package = self.myData[index][@"Package"];
    NSString *path = @"/var/mobile/Documents/DebBackup";
    BOOL isDirectory = NO;
    if(![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    path = [path stringByAppendingPathComponent:Package];
    NSString *DEBIAN = [path stringByAppendingPathComponent:@"/DEBIAN"];
    [fileManager removeItemAtPath:path error:nil];
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:DEBIAN withIntermediateDirectories:YES attributes:nil error:nil];
    NSDictionary*js = self.myData[index];
    NSMutableString*control = [NSMutableString new];
    for (NSString *key in js) {
        NSString * value = js[key];
        if (![key isEqual:@"Status"])[control appendFormat:@"%@: %@\n",key, value];
    }
    [control writeToFile:[DEBIAN stringByAppendingPathComponent:@"/control"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *directoryPath = [jbpath stringByAppendingFormat:@"/Library/dpkg/info"];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    NSString *fileName;
    while (fileName = [enumerator nextObject]) {
        NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (!isDirectory) {
            if ([fileName containsString:Package]) {
                if (![fileName containsString:@"list"] && ![fileName containsString:@"md5sums"]) {
                    spawnRoot(@[@"chmod",@"755",filePath]);
                    //                    spawnRoot(@[cmd,@"755",filePath]);
                    [fileManager copyItemAtPath:filePath toPath:[DEBIAN stringByAppendingPathComponent:fileName.pathExtension] error:nil];
                }
                if ([fileName.pathExtension isEqual:@"list"]) {
                    NSString *listTxt = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
                    NSArray *cmdarrx = [listTxt componentsSeparatedByString:@"\n"];
                    for (NSString *key in cmdarrx) {
                        if(key.length && ![key isEqual:@"/."]){
                            NSString *kkey = key;
                            if(![key containsString:@"/var"])kkey=[jbpath stringByAppendingString:key];
                            if ([fileManager fileExistsAtPath:kkey isDirectory:&isDirectory] && isDirectory) {
                                [fileManager createDirectoryAtPath:[path stringByAppendingPathComponent:key] withIntermediateDirectories:YES attributes:nil error:nil];
                            }else if(key.length){
                                [fileManager copyItemAtPath:kkey toPath:[path stringByAppendingPathComponent:key] error:nil];
                                
                            }
                        }
                    }
                }
            }
        }
    }
    NSString *debname = [NSString stringWithFormat:@"%@.%@.deb",name,Version];
    debname = [debname stringByReplacingOccurrencesOfString:@"\\s" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, debname.length)];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"()"];
    NSString *debFileName = [[debname componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    NSString *debFilepath = [[path stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@",debFileName];
    spawnRoot(@[@"dpkg-deb",@"-b",path,debFilepath]);
    if([fileManager fileExistsAtPath:debFilepath]){
        [fileManager removeItemAtPath:path error:nil];
    }
    NSArray*ccc = @[name,debFilepath];
    return ccc;
}

- (void)InstallAll{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = @"/var/mobile/Documents/DebBackup";
    BOOL isDirectory = NO;
    if([fileManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
        for (NSString *fileName in enumerator) {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            if ([fileName.pathExtension isEqual:@"deb"]) {
                spawnRoot(@[@"dpkg",@"-i",filePath]);
            }
        }
    }
}


- (UIWindow*)getview{
    return vc.view.window;
}
- (void)DeleteAll{
    NSString *path = @"/var/mobile/Documents/DebBackup";
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    NSString *fileName = nil;
    while (fileName = [enumerator nextObject]) {
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        if ([fileName.pathExtension isEqual:@"deb"]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

void *wifiManager = NULL;
void *(*WiFiManagerClientCreate)(CFAllocatorRef allocator, int flags);
CFPropertyListRef (*WiFiManagerClientCopyProperty)(void *manager, CFStringRef property);
void (*WiFiManagerClientSetProperty)(void *manager, CFStringRef property, CFPropertyListRef value);

static void loadWifiManager(void)
{
    static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        void *wifiHandle = dlopen("/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi", RTLD_NOW);
        WiFiManagerClientCreate =  dlsym(wifiHandle, "WiFiManagerClientCreate");
        WiFiManagerClientCopyProperty = dlsym(wifiHandle, "WiFiManagerClientCopyProperty");
        WiFiManagerClientSetProperty = dlsym(wifiHandle, "WiFiManagerClientSetProperty");
        wifiManager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
    });
}

static bool wifiIsEnabled(void)
{
    loadWifiManager();
    CFBooleanRef isEnabled = WiFiManagerClientCopyProperty(wifiManager, CFSTR("AllowEnable"));
    bool isEnabledBool = CFBooleanGetValue(isEnabled);
    CFRelease(isEnabled);
    return isEnabledBool;
}

static void setWifiEnabled(bool enabled)
{
    loadWifiManager();
    WiFiManagerClientSetProperty(wifiManager, CFSTR("AllowEnable"), enabled ? kCFBooleanTrue : kCFBooleanFalse);
}


static NSMutableDictionary* read_control_info(const char *debFile) {
    NSMutableDictionary *control = [[NSMutableDictionary alloc] init];
    struct archive *a;
    struct archive_entry *entry;
    int ret;
    a = archive_read_new();
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);
    ret = archive_read_open_filename(a, debFile, 10240);
    if (ret != ARCHIVE_OK) {
        return control;
    }
    
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        const char *name = archive_entry_pathname(entry);
        if (strlen(name) == 0 || name[0] == '\n') {
            return control;
        }
        
        if (strstr(name, "control.tar.xz")||strstr(name, "control.tar.gz")) {
            size_t control_size = archive_entry_size(entry);
            char *control_buffer = malloc(control_size);
            size_t total_read = 0;
            while (total_read < control_size) {
                const void *buf;
                size_t bytes_left;
                off_t offset;
                int r = archive_read_data_block(a, &buf, &bytes_left, &offset);
                if (r == ARCHIVE_EOF) {
                    break;
                }
                if (r != ARCHIVE_OK) {
                    free(control_buffer);
                    return control;
                }
                memcpy(control_buffer + total_read, buf, bytes_left);
                total_read += bytes_left;
            }
            archive_read_close(a);
            archive_read_free(a);
            struct archive *inner_archive = archive_read_new();
            archive_read_support_format_all(inner_archive);
            archive_read_support_filter_all(inner_archive);
            ret = archive_read_open_memory(inner_archive, control_buffer, control_size);
            free(control_buffer);
            if (ret != ARCHIVE_OK) {
                archive_read_free(inner_archive);
                return control;
            }
            struct archive_entry *inner_entry;
            while (archive_read_next_header(inner_archive, &inner_entry) == ARCHIVE_OK) {
                const char *inner_name = archive_entry_pathname(inner_entry);
                if (!strcmp(inner_name, "./control") || !strcmp(inner_name, "control")) {
                    char buf[1024];
                    size_t nread;
                    while ((nread = archive_read_data(inner_archive, buf, sizeof(buf))) > 0) {
                        NSString *string = [[NSString alloc] initWithBytes:buf length:nread encoding:NSUTF8StringEncoding];
                        if (string) {
                            NSMutableDictionary *info = parse_control_info_line(string);
                            [control addEntriesFromDictionary:info];
                        }
                    }
                    break;
                }
            }
            archive_read_close(inner_archive);
            archive_read_free(inner_archive);
            return control;
        }else if (strstr(name, "control.tar.")){
            NSString *string = spawnRoot(@[@"dpkg-deb",@"-I",[NSString stringWithFormat:@"%s",debFile]]);
            if (string) {
                NSMutableDictionary *info = parse_control_info_line(string);
                archive_read_close(a);
                archive_read_free(a);
                return info;
            }
        }
    }
    archive_read_close(a);
    archive_read_free(a);
    return control;
}


static NSMutableDictionary*parse_control_info_line(NSString *line) {
    NSArray *lines = [line componentsSeparatedByString:@"\n"];
    NSMutableDictionary *packageDict = [NSMutableDictionary dictionary];
    for (NSString *line in lines) {
        NSArray *parts = [line componentsSeparatedByString:@": "];
        if (parts.count == 2) {
            NSString *key = parts[0];
            NSString *value = parts[1];
            NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
            key = [key stringByTrimmingCharactersInSet:set];
            value = [value stringByTrimmingCharactersInSet:set];
            [packageDict setObject:value forKey:key];
        }
    }
    return packageDict;
}

@end
