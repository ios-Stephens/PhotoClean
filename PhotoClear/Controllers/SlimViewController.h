//
//  SlimViewController.h
//  Installer
//
//  Created by xuanpf on 17/3/16.
//  Copyright © 2017年 www.xyzs.com. All rights reserved.
//

#import "BasicViewController.h"

typedef NS_ENUM(NSUInteger, SlimType) {
    SlimTypePhoto,//照片瘦身
    SlimTypeVideo,//视频瘦身
};

@interface SlimViewController : BasicViewController

- (instancetype)initWithType:(SlimType)type;

@end
