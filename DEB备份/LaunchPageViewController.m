//
//  ShoppingCartViewController.m
//  DEB备份
//
//  Created by 隔壁老王 on 2023/4/23.
//

#import "ViewController.h"
#import "LaunchPageViewController.h"
#import <Foundation/Foundation.h>


@implementation LaunchPageViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"嗯！一些信息而已";
    // 初始化数据
    self.data = @[
        @{@"groupTitle": @"理论上支持所有支持巨魔的越狱",
          @"items": @[@"已安装的插件列表，仅显示用户自行安装的插件和部分越狱自带插件", @"已备份的插件，可以跳转到Filza查看.deb文件", @"Fugu安装已备份的插件需要禁止注入本app"],
          @"itemsx": @[@"", @"",@"使用Choicy插件可以禁止注入"]
        },
        @{@"groupTitle": @"作者信息",
          @"items": @[@"推特",  @"Discord"],
          @"itemsx": @[@"https://twitter.com/bswbw" ,@"https://discord.gg/mezMfshK"]
        },
        //        @{@"groupTitle": @"", @"items": @[@"一键删除所有备份",@"一键安装所有备份"]},
        @{@"groupTitle": @"", @"items": @[@"有根DEB转无根（依赖ldid和dpkg插件）"]},
        @{@"groupTitle": @"你是什么越狱？", @"items": @[@""]},
        @{@"groupTitle": @"上方选择越狱再进入程序", @"items": @[@"进入程序 -> (加载全部已装插件)",@"进入程序 -> (过滤系统已装插件)"]}
    ];
    //    [self.navigationController.navigationBar setHidden:YES]; // 是否显示导航栏
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}




#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *groupData = self.data[section];
    NSArray *items = groupData[@"items"];
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    NSDictionary *groupData = self.data[indexPath.section];
    NSArray *items = groupData[@"items"];
    NSArray *itemsx = groupData[@"itemsx"];
    
    if(indexPath.section==3){
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Fugu/多巴胺", @"Xina", @"有根越狱"]];
        segmentedControl.frame = CGRectMake(10, 10, cell.contentView.bounds.size.width - 20, 30);
        segmentedControl.selectedSegmentIndex = 0;
        [segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:segmentedControl];
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        [segmentedControl.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor].active = YES;
        [segmentedControl.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor].active = YES;
        
        [segmentedControl.widthAnchor constraintEqualToConstant:cell.contentView.frame.size.width].active = YES;
        [self segmentedControlValueChanged:segmentedControl];
    }else{
        cell.textLabel.text = items[indexPath.row];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cell.detailTextLabel.text = itemsx[indexPath.row];
        cell.detailTextLabel.numberOfLines = 0; // 设置为多行显示
        cell.detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            [cell setSeparatorInset:UIEdgeInsetsZero];
        }
        if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
            [cell setPreservesSuperviewLayoutMargins:NO];
        }
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
        if(indexPath.section&&indexPath.section!=3){
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
}


#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSDictionary *groupData = self.data[section];
    NSString *title = groupData[@"groupTitle"];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.text = title;
    
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    return headerLabel;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *groupData = self.data[indexPath.section];
    //    NSArray *items = groupData[@"items"];
    NSArray *itemsx = groupData[@"itemsx"];
    //    NSLog(@"Selected : %@", items[indexPath.row]);
    if(indexPath.section == 1){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itemsx[indexPath.row]] options:@{} completionHandler:nil];
    }
    
    if(indexPath.section == 2){
        [self RootToNoRoot];
    }
    
    if(indexPath.section == 4){
        if(indexPath.row==1){
            [[ViewController alloc] openAll:false];
            [self dismissViewControllerAnimated:YES completion:nil];
        }else{
            [[ViewController alloc] openAll:true];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}
- (void)RootToNoRoot{
    NSString *path = @"/var/mobile/Documents/RootedToRootless";
    BOOL isDirectory = NO;
    NSMutableArray*deb = NSMutableArray.alloc.init;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isDirectory) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }else{
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
        NSString *fileName = nil;
        while (fileName = [enumerator nextObject]) {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            if ([fileName.pathExtension isEqual:@"deb"]) {
                [deb addObject:filePath];
            }
        }
    }
    NSString*bt = deb.count ? @"转换成功不代表兼容可用\n转换仅是让有根插件能在无根越狱安装成功" : @"没有文件，请先把要转换的deb放到\n/var/mobile/Documents/RootedToRootless\n文件夹内";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:bt preferredStyle:UIAlertControllerStyleAlert];
    for(int i=0;i<deb.count;i++){
        NSMutableDictionary* dic = [[ViewController alloc]read_control_info:[deb[i] UTF8String]];
        [alert addAction:[UIAlertAction actionWithTitle:dic[@"Name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
            NSLog(@"%@", dic[@"Architecture"]);
            NSString*npath = [path stringByAppendingPathComponent:dic[@"Package"]];
            if([dic[@"Architecture"]isEqual:@"iphoneos-arm"]){
                [dic setObject:@"iphoneos-arm64" forKey:@"Architecture"];
                NSString*debian = [npath stringByAppendingPathComponent:@"DEBIAN"];
                [fileManager createDirectoryAtPath:debian withIntermediateDirectories:YES attributes:nil error:nil];
                NSString *e = [[ViewController alloc]spawnRoot:@[@"dpkg-deb",@"-e",deb[i],debian]];
                if(e){
                    NSString *ncontrol = [npath stringByAppendingPathComponent:@"control"];
                    NSString *control = [debian stringByAppendingPathComponent:@"control"];
                    [fileManager removeItemAtPath:control error:nil];
                    NSString *r = [[ViewController alloc]spawnRoot:@[@"rm",@"-rf",control]];
                    if(r){
                        [fileManager createDirectoryAtPath:npath withIntermediateDirectories:YES attributes:nil error:nil];
                        [fileManager createDirectoryAtPath:[npath stringByAppendingPathComponent:@"var"] withIntermediateDirectories:YES attributes:nil error:nil];
                        [fileManager createDirectoryAtPath:[npath stringByAppendingPathComponent:@"var/jb"] withIntermediateDirectories:YES attributes:nil error:nil];
                        NSString *x = [[ViewController alloc]spawnRoot:@[@"dpkg-deb",@"-x",deb[i],[npath stringByAppendingPathComponent:@"var/jb"]]];
                        if(x){
                            NSMutableString* newString = NSMutableString.alloc.init;
                            for (NSString *key in dic) {
                                if(![key containsString:@" "]){
                                    [newString appendFormat:@"%@: %@\n",key,[dic objectForKey:key]];
                                }
                            }
                            [newString appendFormat:@"\n"];
                            NSString*sign = [npath stringByAppendingPathComponent:@"/var/jb/Library"];
                            NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:sign];
                            NSString *fileName = nil;
                            while (fileName = [enumerator nextObject]) {
                                NSString *filePath = [sign stringByAppendingPathComponent:fileName];
                                [[ViewController alloc]spawnRoot:@[@"ldid",@"-S",filePath]];
                            }
                            NSString *string = [NSString stringWithString:newString];
                            [[ViewController alloc]spawnRoot:@[@"touch",ncontrol]];
                            if([string writeToFile:ncontrol atomically:YES encoding:NSUTF8StringEncoding error:nil]){
                                [[ViewController alloc]spawnRoot:@[@"mv",ncontrol,control]];
                                NSString *debFilepath = [path stringByAppendingFormat:@"/%@-rootless.deb",dic[@"Name"]];
                                [[ViewController alloc]spawnRoot:@[@"dpkg-deb",@"-b",npath,debFilepath]];
                                [[ViewController alloc]spawnRoot:@[@"rm",@"-rf",npath]];
                                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"转换完毕" message:debFilepath preferredStyle:UIAlertControllerStyleAlert];
                                [alert addAction:[UIAlertAction actionWithTitle:@"跳转Filza查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
                                    NSCharacterSet *CharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
                                    NSString *encodedURLString = [debFilepath stringByAddingPercentEncodingWithAllowedCharacters:CharacterSet];
                                    NSURL *filzaURL = [NSURL URLWithString:[@"filza://view" stringByAppendingString:encodedURLString]];
                                    [[UIApplication sharedApplication] openURL:filzaURL options:@{} completionHandler:nil];
                                }]];
                                [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
                                [self presentViewController:alert animated:true completion:nil];
                            }
                        }
                    }
                }
            }else if([dic[@"Architecture"]isEqual:@"iphoneos-arm64"]){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"此插件已是无根deb" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"跳转Filza查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actiona) {
                    NSCharacterSet *CharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
                    NSString *encodedURLString = [deb[i] stringByAddingPercentEncodingWithAllowedCharacters:CharacterSet];
                    NSURL *filzaURL = [NSURL URLWithString:[@"filza://view" stringByAppendingString:encodedURLString]];
                    [[UIApplication sharedApplication] openURL:filzaURL options:@{} completionHandler:nil];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:true completion:nil];
            }
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:true completion:nil];
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)sender {
    //    NSLog(@"Selected segment index: %ld", sender.selectedSegmentIndex);
    if(sender.selectedSegmentIndex == 0){
        [[[ViewController alloc]init]selectedSegmentIndexxxxx:@"/var/jb"xxxxx:@"/var/jb/usr/bin/" ];
    }
    if(sender.selectedSegmentIndex == 1){
        [[[ViewController alloc]init]selectedSegmentIndexxxxx:@"/var"xxxxx:@"/var/usr/bin/"];
    }
    if(sender.selectedSegmentIndex == 2){
        [[[ViewController alloc]init]selectedSegmentIndexxxxx:@""xxxxx:@"/usr/bin/"];
    }
}
@end

