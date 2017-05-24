//
//  ImagePickerBrowserItemCellCollectionViewCell.h
//  PhoneManager
//
//  Created by Robin on 16/5/26.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoPickerBrowserItemCell;
@protocol PhotoPickerBrowserItemCellDelegate <NSObject>


-(void) cellDidChecked:(PhotoPickerBrowserItemCell*) cell;
-(void) cellDidClicked:(PhotoPickerBrowserItemCell*) cell;

@end

@interface PhotoPickerBrowserItemCell : UICollectionViewCell

@property(nonatomic,weak) id<PhotoPickerBrowserItemCellDelegate> delegate;

@property(nonatomic,assign) BOOL checked;

-(void) setImagePath:(NSString*) path;
-(void) setImageName:(NSString*) name;
-(void) setImage:(UIImage*) image;
@end
