//
//  ImagePickerBrowserSectionHeader.h
//  Installer
//
//  Created by liuyp on 2016/10/20.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@class PhotoPickerBrowserSectionHeader;
@protocol PhotoPickerBrowserSectionHeaderDelegate <NSObject>



-(void) delButtonDidClicked:(PhotoPickerBrowserSectionHeader*) header;

@end

@interface PhotoPickerBrowserSectionHeader : UICollectionReusableView

@property(nonatomic,weak) id<PhotoPickerBrowserSectionHeaderDelegate> delegate;

@property(nonatomic,assign) NSInteger section;

-(void) setTitle:(NSString*) title;

-(void) setDelEnable:(BOOL) isDelEnable;

-(void) delBtnHidden;

@end
