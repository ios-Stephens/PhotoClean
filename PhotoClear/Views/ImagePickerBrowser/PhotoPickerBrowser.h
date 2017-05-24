//
//  ImagePickerBrowser.h
//  PhoneManager
//
//  Created by Robin on 16/5/26.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoPickerBrowser;
@protocol PhotoPickerBrowserDelegate <NSObject>

- (NSInteger)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser itemsAtSection:(NSInteger)section;

- (NSString*)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser titleAtInSection:(NSInteger)section;


@optional


- (NSInteger)numberOfSectionsForImagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser;

- (void)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser deleteSelectedIndexPath:(NSArray<NSIndexPath *> *)selectedIndex;
- (void)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser didTapAtIndexPath:(NSIndexPath *)indexPath;

- (void)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser didSelectedChanged:(NSArray<NSIndexPath *> *)selects;

- (UIImage *)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser imageAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser imageNameAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser imagePathAtIndexPath:(NSIndexPath *)indexPath;


@end

@interface PhotoPickerBrowser : UIView

@property(nonatomic,weak) id<PhotoPickerBrowserDelegate> delegate;

@property(nonatomic,assign,readonly) BOOL isSmart;
@property (nonatomic, assign) BOOL hiddenDelBtn;

-(void) reloadData;

-(void) selectAll;
-(void) selectAllDesc;
-(void) selectSmart;
-(void) selectItemsWith:(NSArray<NSIndexPath*>*) indexArray;
-(NSArray<NSIndexPath*>*) selectedIndexPaths;
-(BOOL) isSelectedOfIndexPath:(NSIndexPath*) indexPath;
-(void) setIndex:(NSIndexPath*) indexPath isSelected:(BOOL) isSelected;

-(void) addSection:(NSUInteger) section withCount:(NSUInteger) count;
@end
