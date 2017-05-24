//
//  PhotoItemCollectionViewCell.h
//  Installer
//
//  Created by kingnet on 16/10/24.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoItemCollectionViewCell;
@protocol PhotoItemCollectionViewCellDelegate <NSObject>


- (void)cellDidChecked:(PhotoItemCollectionViewCell*) cell;

@end

@interface PhotoItemCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<PhotoItemCollectionViewCellDelegate> delegate;

@property (nonatomic, assign) BOOL photoSelected;
@property (nonatomic, assign) BOOL photoHighted;

- (void)setImagePath:(NSString*) path;
- (void)setImageName:(NSString*) name;
- (void)setImage:(UIImage*) image;



@end
