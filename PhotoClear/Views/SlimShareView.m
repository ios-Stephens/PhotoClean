//
//  SlimShareView.m
//  Installer
//
//  Created by xuanpf on 17/3/22.
//  Copyright © 2017年 www.xyzs.com. All rights reserved.
//

#import "SlimShareView.h"

@interface SlimShareView ()

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) UILabel *shareLabel;

@end

@implementation SlimShareView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI{
    self.shareLabel = [UILabel new];
    self.shareLabel.text = @"分享清理结果";
    self.shareLabel.frame = CGRectMake(20, 18, 100, 12);
    self.shareLabel.font = TTSystemFont(12);
    self.shareLabel.textColor = Color_FC05;
    [self.shareLabel sizeToFit];
    [self addSubview:self.shareLabel];
    
    self.titles = [NSArray arrayWithObjects:NSLocalizedString(@"新浪微博",nil),
                   NSLocalizedString(@"朋友圈",nil),
                   NSLocalizedString(@"微信好友", nil),
                   NSLocalizedString(@"QQ空间", nil),
                   NSLocalizedString(@"QQ好友", nil),nil];
    
    self.images = [NSArray arrayWithObjects:@"slim_share_weibo",
                   @"slim_share_wxtimeline",
                   @"slim_share_wechat",
                   @"slim_share_qzone",
                   @"slim_share_qq", nil];
    
    CGFloat gap = (TTScreenWidth-88)/4;
    for (int i = 0; i < 5; i++) {
        UIButton *button = [self shareButtonWithImage:self.images[i] title:self.titles[i]];
        [self addSubview:button];
        button.tag = 1000+i;
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(44.f);
            make.width.height.mas_equalTo(50.f);
            make.centerX.equalTo(self).offset((i-2)*gap);
        }];
        [button addTarget:self action:@selector(touchBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (UIButton *)shareButtonWithImage:(NSString *)image title:(NSString *)title{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:image]];
    [btn addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.equalTo(btn);
    }];
    
    UILabel *titleLabel = [UILabel new];
    [btn addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(imageView.mas_bottom).offset(7.5f);
        make.left.right.equalTo(btn);
        make.height.mas_equalTo(11.f);
    }];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = title;
    titleLabel.font = TTSystemFont(11);
    return btn;
}

- (void)touchBtn:(UIButton *)sender{
    if ([self.delegate respondsToSelector:@selector(slimShareWithType:)]) {
        [self.delegate slimShareWithType:(SlimShareType)(sender.tag - 1000)];
    }
}

@end
