//
//  AppDelegate.m
//  DEB备份
//
//  Created by 隔壁老王 on 2023/4/23.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 创建窗口
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    ViewController *vc = [[ViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = navController;
    // 显示窗口
    [self.window makeKeyAndVisible];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];

    return YES;
}


@end
