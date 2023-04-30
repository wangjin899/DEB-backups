//
//  ShoppingCartViewController.h
//  DEB备份
//
//  Created by 隔壁老王 on 2023/4/23.
//


#import <UIKit/UIKit.h>
#import "ViewController.h"
@interface LaunchPageViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) UIView *bottomMenu;
@property (nonatomic, strong) NSArray *myData;

@end
