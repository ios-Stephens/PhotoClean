//
//  SlimShareView.h
//  Installer
//
//  Created by xuanpf on 17/3/22.
//  Copyright © 2017年 www.xyzs.com. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SlimShareType) {
    SlimShareTypeWeibo,
    SlimShareTypeWXTimeLine,
    SlimShareTypeWeChat,
    SlimShareTypeQzone,
    SlimShareTypeQQ,
};

@protocol SlimShareViewDelegate <NSObject>

- (void)slimShareWithType:(SlimShareType)type;

@end

@interface SlimShareView : UIView

@property (nonatomic, weak) id<SlimShareViewDelegate> delegate;

@end
