//
//  ImagePickerBrowserSectionHeader.m
//  Installer
//
//  Created by liuyp on 2016/10/20.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import "PhotoPickerBrowserSectionHeader.h"

@interface PhotoPickerBrowserSectionHeader ()
{
    UILabel *_titleLable;
    
    UIButton *_delBtn;
    
}


@end


@implementation PhotoPickerBrowserSectionHeader

-(instancetype) initWithFrame:(CGRect)frame{
   
    if (self=[super initWithFrame:frame]) {
        [self initWithLayerOut];
    }
    return self;
}


-(void) setTitle:(NSString*) title{

    _titleLable.text = title;
}

-(void) initWithLayerOut{

   
    _titleLable = [[UILabel alloc] init];
    _titleLable.font = Font_FS06;
    _titleLable.textColor = Color_FC01;
    [self addSubview:_titleLable];
    
    [_titleLable mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.bottom.equalTo(self);
        make.left.equalTo(self.mas_left).with.offset(15);
        make.width.mas_equalTo(200);
        
    }];

    _delBtn = [[UIButton alloc] init];
    [_delBtn setTitle:NSLocalizedString(@"删除所选",nil) forState:UIControlStateNormal];
    [_delBtn setTitleColor:Color_FC08 forState:UIControlStateNormal];
    [_delBtn setTitleColor:Color_FC05 forState:UIControlStateDisabled];
    _delBtn.titleLabel.font = Font_FS03;
    _delBtn.titleLabel.textAlignment=NSTextAlignmentRight;
    [_delBtn addTarget:self action:@selector(delButtinAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_delBtn];
    [_delBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.right.equalTo(self.mas_right).with.offset(-15);
        //make.width.mas_equalTo(200);
        
    }];
    

}

-(void) setDelEnable:(BOOL) isDelEnable{
   
    _delBtn.enabled=isDelEnable;
   
}

-(void) delButtinAction{

    if (self.delegate&&[self.delegate respondsToSelector:@selector(delButtonDidClicked:)]) {
        [self.delegate delButtonDidClicked:self];
    }
}

-(void) delBtnHidden{
    _delBtn.hidden = YES;
}

@end
