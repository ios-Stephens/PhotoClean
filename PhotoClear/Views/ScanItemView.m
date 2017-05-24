//
//  ScanItemView.m
//  Installer
//
//  Created by 陈鑫 on 17/3/21.
//  Copyright © 2017年 www.xyzs.com. All rights reserved.
//

#import "ScanItemView.h"

@interface ScanItemView ()

@property (nonatomic, copy) ActionBlock actionBlock;

@property (nonatomic, strong) NSString *imageName;          //检测前的imageName

@property (nonatomic, strong) UIImageView *imageView;           //icon

@property (nonatomic, strong) UILabel *topLabel;            //正在检测时上方的文字

@property (nonatomic, strong) UILabel *bottomLabel;         //正在检测时下方的文字

@property (nonatomic, strong) UILabel *statusLabel;                //检测状态文字  正在检测  等待检测  可节省等

@property (nonatomic,strong) UIButton *rightBtn;

@property (nonatomic, strong) UILabel *memoryLabel;

@property (nonatomic, strong) UIView *bottomLineView;

@property (nonatomic, assign) NSInteger num;     //扫描结束时扫描出来的项目的个数

@end

@implementation ScanItemView

- (instancetype)initWithFrame:(CGRect)frame imageName:(NSString *)imageName{
    if(self = [super initWithFrame:frame]){
        _imageName = imageName;
        [self initItem];
    }
    return self;
}

- (void)initItem{
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goScanItemDetail)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tap];
    
    [self addSubview:self.imageView];
    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(38);
        make.left.mas_equalTo(self).mas_offset(20);
        make.centerY.mas_equalTo(self);
    }];
    
    [self addSubview:self.topLabel];
    [_topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(_imageView.mas_right).mas_offset(15);
        make.width.mas_equalTo(150);
        make.top.mas_equalTo(self).mas_offset(33);
    }];
    [self addSubview:self.bottomLabel];
    [_bottomLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(_imageView.mas_right).mas_offset(15);
        make.width.mas_equalTo(150);
        make.top.mas_equalTo(self.mas_top).mas_offset(45);
    }];
    
    
    [self addSubview:self.statusLabel];
    [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self).mas_offset(-30);
        make.centerY.mas_equalTo(self);
    }];
    
    
    [self addSubview:self.memoryLabel];
    [_memoryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(_statusLabel.mas_right);
        make.centerY.mas_equalTo(self);
        make.width.mas_equalTo(54);
    }];
    
    [self addSubview:self.rightBtn];
    [_rightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self);
        make.left.mas_equalTo(_memoryLabel.mas_right).mas_offset(5);
        make.right.mas_equalTo(self.mas_right).mas_offset(-20);
    }];
    
    _bottomLineView = [[UIView alloc] init];
    _bottomLineView.backgroundColor = Color_D01;
    [self addSubview:_bottomLineView];
    [_bottomLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self);
        make.height.mas_equalTo(1/TTMainScale);
        make.bottom.mas_equalTo(self.mas_bottom).mas_offset(-1/TTMainScale);
    }];
}

#pragma mark - getter/setter

- (UIImageView *)imageView{
    if(!_imageView){
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_imageName]];
    }
    return _imageView;
}

- (UILabel *)statusLabel{
    if(!_statusLabel){
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = Font_FS03;
        _statusLabel.textColor = Color_FC05;
        _statusLabel.textAlignment = NSTextAlignmentRight;
    }
    return _statusLabel;
}

- (UILabel *)topLabel{
    if(!_topLabel){
        _topLabel = [[UILabel alloc] init];
        _topLabel.font = Font_FS05;
        _topLabel.textColor = Color_FC05;
        _topLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _topLabel;
}

- (UILabel *)bottomLabel{
    if(!_bottomLabel){
        _bottomLabel = [[UILabel alloc] init];
        _bottomLabel.font = Font_FS03;
        _bottomLabel.textColor = Color_FC05;
        _bottomLabel.textAlignment = NSTextAlignmentLeft;
        _bottomLabel.hidden = YES;
    }
    return _bottomLabel;
}

- (UILabel *)memoryLabel{
    if(!_memoryLabel){
        _memoryLabel = [[UILabel alloc] init];
        _memoryLabel.font = Font_FS03;
        _memoryLabel.textColor = Color_FC09;
        _memoryLabel.textAlignment = NSTextAlignmentCenter;
        _memoryLabel.hidden = YES;
    }
    return _memoryLabel;
}

- (UIButton *)rightBtn{
    if(!_rightBtn){
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBtn setImage:[UIImage imageNamed:@"about_us_more"] forState:UIControlStateNormal];
//        [_rightBtn addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
        _rightBtn.hidden = YES;
    }
    return _rightBtn;
}

#pragma mark - private method
//- (void)btnClicked{
//    if(_actionBlock && _status == ScanItemStatusOver){
//        _actionBlock();
//    }
//}


#pragma mark - public method

- (void)updateItemByStatus:(ScanItemStatus)status type:(ScanItemType)type  num:(NSInteger)num memory:(NSInteger)memory {
    _status = status,_type = type,_num = num;
    if(status == ScanItemStatusWorking || status == ScanItemStatusOver){
        if(num > 0)     self.backgroundColor = TTWhiteColor;
        else{
             self.backgroundColor = Color_BG01;
        }
        _imageView.image = [UIImage imageNamed:[_imageName stringByReplacingOccurrencesOfString:@"disabled" withString:@"normal"]];
        _topLabel.textColor = Color_FC03;
    }else{
        //刷新时将状态重置
         _imageView.image = [UIImage imageNamed:[_imageName stringByReplacingOccurrencesOfString:@"normal" withString:@"disabled"]];   //重置icon状态
        self.backgroundColor = Color_BG01;
        _topLabel.textColor = Color_FC05;
        [_topLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self).mas_offset(33);
        }];
        
        _bottomLabel.hidden = YES;      //隐藏扫描结果
        
         _statusLabel.textColor = Color_FC05;
        [_statusLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self).mas_offset(-30);
        }];
        if(TT_IS_IOS8_AND_UP){
            _statusLabel.text = NSLocalizedString(@"等待检测",nil);
        }else{
            _statusLabel.text = NSLocalizedString(@"无法支持iOS8.0以下",nil);
        }
        
        _memoryLabel.hidden = YES;
        _rightBtn.hidden = YES;
    }
    
    if(status == ScanItemStatusWorking){
        _statusLabel.text = NSLocalizedString(@"正在检测",nil);
        _statusLabel.textColor = Color_FC06;
        _bottomLabel.hidden = YES;
    }else if(status == ScanItemStatusOver){
        [_topLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.mas_top).mas_offset(21);
        }];
        
        _bottomLabel.hidden = NO;
        if(type == ScanItemStatusTypeSimilarPhoto){
            _bottomLabel.text = [NSString stringWithFormat:NSLocalizedString(@"相似/连拍照片 %ld 张",nil),num];
        }else if(type == ScanItemStatusTypeScreenshot){
            _bottomLabel.text = [NSString stringWithFormat:NSLocalizedString(@"可清理照片 %ld 张",nil),num];
        }else if(type == ScanItemStatusTypePhotoSlimming){
            _bottomLabel.text = [NSString stringWithFormat:NSLocalizedString(@"可优化照片 %ld 张",nil),num];
        }else{
            _bottomLabel.text = [NSString stringWithFormat:NSLocalizedString(@"可优化视频 %ld 个",nil),num];
        }
        
        _statusLabel.text = NSLocalizedString(@"可省",nil);
        _statusLabel.textColor = Color_FC05;
        [_statusLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.mas_right).mas_offset(-86);
        }];
        
        _memoryLabel.hidden = NO;
        _memoryLabel.text = [Utility transformSpaceSize:memory];
        
        _rightBtn.hidden = NO;
    }
    
    
    
    if(type == ScanItemStatusTypeSimilarPhoto){
        _topLabel.text = NSLocalizedString(@"相似照片处理",nil);
    }else if(type == ScanItemStatusTypeScreenshot){
        _topLabel.text = NSLocalizedString(@"截屏图片清理",nil);
    }else if(type == ScanItemStatusTypePhotoSlimming){
        _topLabel.text = NSLocalizedString(@"照片瘦身",nil);
    }else{
        _topLabel.text = NSLocalizedString(@"视频瘦身",nil);
    }
}

- (void)showBottomLine:(BOOL)showed{
    if(showed == NO){
        _bottomLineView.hidden = YES;
    }
}

- (void)setItemCilcked:(ActionBlock)actionBlock{
    _actionBlock = actionBlock;
}

- (void)goScanItemDetail{
    if(!TT_IS_IOS8_AND_UP && _type != ScanItemStatusTypeSimilarPhoto)      return;
    if(_actionBlock && _status == ScanItemStatusOver && _num >0){
        _actionBlock();
    }
}
@end
