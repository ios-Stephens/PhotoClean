//
//  SimilarPhotoDetailViewController.h
//  Installer
//
//  Created by kingnet on 16/10/21.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import "BasicPushViewController.h"
#import "PhotoAsset.h"

@protocol SimilarPhotoDetailDataSource <NSObject>

- (NSInteger)numberOfPhotos;
- (NSInteger)indexForVisibleItem;

- (BOOL)isSelectedForPhotoItemAtIndex:(NSInteger)index;

- (PhotoAsset *)imageAssetAtIndex:(NSInteger)index;

- (NSArray *)imageArrayDidSelected;
- (NSInteger)numberOfSelectedPhotos;

@end

@protocol SimilarPhotoDetailDelegate <NSObject>

- (void)imageAsset:(PhotoAsset *)imageAsset didSelectedAtIndex:(NSInteger)index;
- (void)imageAsset:(PhotoAsset *)imageAsset didDeselectedAtIndex:(NSInteger)index;
- (void)backActionWithVisibleItem:(NSInteger)index hasDelete:(BOOL)hasDel;
- (void)deleteSelectedImage:(void(^)(BOOL))block;

@end

@interface SimilarPhotoDetailViewController : BasicPushViewController




@property (nonatomic, weak) id <SimilarPhotoDetailDataSource> dataSource;
@property (nonatomic, weak) id <SimilarPhotoDetailDelegate> delegate;

@end
