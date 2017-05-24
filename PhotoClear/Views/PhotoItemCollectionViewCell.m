//
//  PhotoItemCollectionViewCell.m
//  Installer
//
//  Created by kingnet on 16/10/24.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import "PhotoItemCollectionViewCell.h"

#define checkImage @"check"
#define unCheckImage @"unCheck"

@interface PhotoItemCollectionViewCell ()
{
    UIImageView *bodyImageView;
    UIImageView *checkImageView;
    UIImageView *coverView;
}

@end

@implementation PhotoItemCollectionViewCell

-(instancetype) init{
    
    return [self initWithFrame:CGRectZero];
}

-(instancetype) initWithFrame:(CGRect)frame{
    
    if (self=[super initWithFrame:frame]) {
        
        bodyImageView = [[UIImageView alloc] init];
        bodyImageView.contentMode=UIViewContentModeScaleAspectFill;
        bodyImageView.layer.masksToBounds=YES;
        [self.contentView addSubview:bodyImageView];
        [bodyImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.right.equalTo(self.contentView);
            
        }];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellCheckTap:)];
        
        checkImageView = [[UIImageView alloc] init];
        [checkImageView setImage:[UIImage imageNamed:unCheckImage]];
        [self.contentView addSubview:checkImageView];
        [checkImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).with.offset(2);
            make.right.equalTo(self.contentView.mas_right).with.offset(-2);
            make.width.height.mas_equalTo(24);
            
        }];
        
        [checkImageView addGestureRecognizer:tap];
        checkImageView.userInteractionEnabled = YES;
        
        
        coverView = [[UIImageView alloc] init];
        coverView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.6];
        [self.contentView addSubview:coverView];
        [coverView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.right.equalTo(self.contentView);
        }];
        coverView.hidden = YES;
    }
    
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    bodyImageView.image = nil;
}

-(void) setImagePath:(NSString*) path{
    
    
}

-(void) setImageName:(NSString*) name{
    [checkImageView setImage:[UIImage imageNamed:name]];;
}

-(void) setImage:(UIImage*) image{
    
    bodyImageView.image = image;
}


-(void)setPhotoSelected:(BOOL)photoSelected {
    _photoSelected = photoSelected;
    if (photoSelected) {
        [checkImageView setImage:[UIImage imageNamed:checkImage]];
    } else {
        [checkImageView setImage:[UIImage imageNamed:unCheckImage]];
    }
}

- (void)setPhotoHighted:(BOOL)photoHighted {
    _photoHighted = photoHighted;
    if (photoHighted) {
        coverView.hidden = YES;
    } else {
        coverView.hidden = NO;
    }
}

-(void)cellCheckTap:(UITapGestureRecognizer *) sender{
    self.photoSelected = !self.photoSelected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellDidChecked:)]) {
        [self.delegate cellDidChecked:self];
    }
}

@end
