//
//  PhotoItemView.h
//  Installer
//
//  Created by kingnet on 16/10/21.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoAsset.h"

@class PhotoItemView;

@protocol PhotoItemViewDelegate <NSObject>


- (void)photoItemDidChecked:(PhotoItemView *)photoItem;

@end


@interface PhotoItemView : UIView

@property (nonatomic, strong) PhotoAsset *imageAsset;

@property (nonatomic, assign) BOOL photoSelected;

- (void)prepareForReuse;

- (void)loadUIWithAsset:(PhotoAsset *)imageAsset;

@property (nonatomic, assign) NSInteger indexFlag;

@property (nonatomic, weak) id<PhotoItemViewDelegate> delegate;

@end
