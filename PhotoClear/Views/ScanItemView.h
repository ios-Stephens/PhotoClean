//
//  ScanItemView.h
//  Installer
//
//  Created by 陈鑫 on 17/3/21.
//  Copyright © 2017年 www.xyzs.com. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,ScanItemType){
    ScanItemStatusTypeSimilarPhoto,                 //相似照片检测
    ScanItemStatusTypeScreenshot,              //截图检测
    ScanItemStatusTypePhotoSlimming ,                   //照片瘦身
    ScanItemStatusTypeVideoSlimming                 //视频瘦身
};

//检测状态
typedef NS_ENUM(NSUInteger,ScanItemStatus){
    ScanItemStatusNone,                 //还没开始检测
    ScanItemStatusWorking,              //正在检测中
    ScanItemStatusOver                    //检查完成
};

typedef void (^ActionBlock)();

@interface ScanItemView : UIView

- (instancetype)initWithFrame:(CGRect)frame imageName:(NSString *)imageName;

@property (nonatomic, assign) ScanItemStatus status;

@property (nonatomic, assign) ScanItemType type;

- (void)showBottomLine:(BOOL)showed;
//扫描状态  扫描项  扫描结果的照片或视频数量  扫描可节约内存
- (void)updateItemByStatus:(ScanItemStatus)status type:(ScanItemType)type num:(NSInteger)num memory:(NSInteger)memory;

- (void)setItemCilcked:(ActionBlock)action;

@end
