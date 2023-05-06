//
//  main.m
//  DEB备份
//
//  Created by 隔壁老王 on 2023/4/23.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"



int main(int argc, char * argv[]) {
    setuid(0);
    setgid(0);
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
