//
//  ViewController.h
//  DEB备份
//
//  Created by 隔壁老王 on 2023/4/23.
//

#import <dlfcn.h>
#import <UIKit/UIKit.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#import <objc/message.h>
#include <dirent.h>
#include <sys/stat.h>
#include "archive.h"
#include "archive_entry.h"
//#include "lzma.h"
#include "zstd.h"


#import "LaunchPageViewController.h"

enum JBType{
    JB_Root = 1,
    JB_Xina = 1,
    JB_FUGU = 2,
};
typedef struct {
    NSString*str;
    NSArray *arr;
    NSUInteger count;
}GETYL;
@interface ViewController : UIViewController 

//@property (nonatomic) int jbtype;
@property (nonatomic, strong) UITextView*textView;
@property (nonatomic, strong) UIView *bottomMenu;
//@property (nonatomic, strong) NSString *jbpath;
@property (nonatomic, strong) NSMutableArray *buttonArray;
- (void)DeleteAll;
- (void)InstallAll;
- (NSString*)spawnRoot:(NSArray*)cmd;
- (NSMutableDictionary*)read_control_info:(const char*)debpath;
- (void)openAll:(bool)op;
- (UIWindow*)getview;
- (void)selectedSegmentIndexxxxx:(NSString *)Index xxxxx:(NSString *)cmd;
@end





