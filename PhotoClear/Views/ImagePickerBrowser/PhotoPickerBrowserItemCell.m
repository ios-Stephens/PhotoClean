//
//  ImagePickerBrowserItemCellCollectionViewCell.m
//  PhoneManager
//
//  Created by Robin on 16/5/26.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import "PhotoPickerBrowserItemCell.h"

#define checkImage @"check"
#define unCheckImage @"unCheck"
@interface PhotoPickerBrowserItemCell ()
{
    UIImageView *bodyImageView;
    UIImageView *checkImageView;
}
@end

@implementation PhotoPickerBrowserItemCell

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
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTap:)];
        [bodyImageView addGestureRecognizer:tap];
        bodyImageView.userInteractionEnabled = YES;
        
        checkImageView = [[UIImageView alloc] init];
        [checkImageView setImage:[UIImage imageNamed:unCheckImage]];
        [self.contentView addSubview:checkImageView];
        [checkImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).with.offset(2);
            make.right.equalTo(self.contentView.mas_right).with.offset(-2);
            make.width.height.mas_equalTo(24);
            
        }];
        
        UITapGestureRecognizer *checkTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellCheckTap:)];
        [checkImageView addGestureRecognizer:checkTap];
        checkImageView.userInteractionEnabled = YES;
        
    }
    
    return self;
}


-(void) setImagePath:(NSString*) path{
   

}

-(void) setImageName:(NSString*) name{
    [checkImageView setImage:[UIImage imageNamed:name]];;
}

-(void) setImage:(UIImage*) image{
   
    bodyImageView.image = image;
}




-(void) setChecked:(BOOL)checked{
    _checked = checked;
    
    [checkImageView setImage:[UIImage imageNamed:_checked?checkImage:unCheckImage]];
}

-(void) cellTap:(UITapGestureRecognizer *) sender{
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(cellDidClicked:)]) {
        [self.delegate cellDidClicked:self];
    }
    
    
    

}

-(void) cellCheckTap:(UITapGestureRecognizer *) sender{
    
    self.checked = !self.checked;
    if (self.delegate&&[self.delegate respondsToSelector:@selector(cellDidChecked:)]) {
        [self.delegate cellDidChecked:self];
    }
    
}




@end
