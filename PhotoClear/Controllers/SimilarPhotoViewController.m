//
//  SimilarPhotoViewController.m
//  PhoneManager
//
//  Created by Robin on 16/5/30.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import "SimilarPhotoViewController.h"
#import "PhotoFetchManager.h"
#import "SimilarPhotoDetailViewController.h"
//#import "SimilarProcessView.h"
#import "PhotoPickerBrowser.h"

@interface SimilarPhotoViewController () <PhotoPickerBrowserDelegate, SimilarPhotoDetailDelegate, SimilarPhotoDetailDataSource>
{
    UILabel *_tipLable;
    
}

@property(nonatomic, strong) UIButton *rightBarButtonItem;

@property(nonatomic, strong) UIView *processView;

@property (nonatomic, strong) UIButton *deleteBtn;
@property (nonatomic, strong) PhotoPickerBrowser *imagePickerBrowser;

// 选中照片数组，用于加载详情页
@property (nonatomic, strong) NSMutableArray *willDisplayArray;
@property (nonatomic, strong) NSIndexPath *curIndexPath;

@end

@implementation SimilarPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title =NSLocalizedString(@"清理相似照片", nil);
    self.titleLab.text = self.title;
    
    [self.customNavBarView  addSubview:self.rightBarButtonItem];
    [self.rightBarButtonItem mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.customNavBarView);
        make.height.mas_equalTo(44);
        make.right.equalTo(self.customNavBarView.mas_right).with.offset(-15);
    }];
    [self setRightBarButtonTitle:NSLocalizedString(@"智能筛选", nil)];
    
    [self.view addSubview:self.imagePickerBrowser];
    
    self.deleteBtn.hidden = YES;
    [self.view addSubview:self.deleteBtn];
    [self.deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.equalTo(self.view);
        make.height.mas_equalTo(50);
        make.width.mas_equalTo(Device_width);
    }];
    
    _tipLable = [[UILabel alloc] init];
    _tipLable.text=NSLocalizedString(@"没有相似照片需要清理", nil);
    [self.view addSubview:_tipLable];
    [_tipLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        //make.height.mas_equalTo(30);
        //make.width.mas_equalTo(300);
    }];
    _tipLable.hidden = YES;
    _tipLable.font = Font_FS05;
    _tipLable.textColor = Color_FC04;
    
    [self loadData];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([PhotoFetchManager shareInstance].needReload) {
        [SVProgressHUD showWithStatus:@"loading"];
        XYDeclareWeakSelf;
        [[PhotoFetchManager shareInstance] checkPhoto:^{
            [weakSelf loadData];
            [SVProgressHUD dismiss];
        }];
    }
}

-(void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
//    [SimilarProcessView dismiss];
    [SVProgressHUD dismiss];
}

#pragma mark - Style

- (UIButton *)rightBarButtonItem {
    if (_rightBarButtonItem == nil) {
        _rightBarButtonItem  = [[UIButton alloc]  init];
        _rightBarButtonItem.titleLabel.font =Font_FS06;
        [_rightBarButtonItem setTitleColor:Color_FC06 forState:UIControlStateNormal];
        [_rightBarButtonItem setTitleColor:Color_FC05 forState:UIControlStateDisabled];
        [_rightBarButtonItem addTarget:self action:@selector(rightBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightBarButtonItem;
}

- (UIButton *)deleteBtn {
    if (_deleteBtn == nil) {
        _deleteBtn = [[UIButton alloc] init];
        _deleteBtn.backgroundColor = HexColor(0xee3f3c);
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_deleteBtn addTarget:self action:@selector(delBottonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteBtn;
}

- (PhotoPickerBrowser *)imagePickerBrowser {
    if (_imagePickerBrowser == nil) {
        _imagePickerBrowser = [[PhotoPickerBrowser alloc] initWithFrame:CGRectMake(0, 64, Device_width, Device_height-64)];
        _imagePickerBrowser.delegate = self;
        _imagePickerBrowser.backgroundColor = [UIColor redColor];
    }
    return _imagePickerBrowser;
    
}

#pragma mark - Action

- (void)leftBarButtonAction:(UIBarButtonItem*) sender{
//    [SimilarProcessView dismiss];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightBarButtonAction:(UIButton *)sender{
    
    if ([sender.currentTitle isEqualToString:NSLocalizedString(@"智能筛选",nil)]) {
        [self selectSmart];
    }else{
        [self selectDesc];
        
    }
}

- (void)delBottonAction:(UIButton *)sender{
    sender.enabled = NO;
    NSArray<NSIndexPath*> *indexPaths = [_imagePickerBrowser selectedIndexPaths];
    [[PhotoFetchManager shareInstance] sp_removeSimilarImageWithIndexPaths:indexPaths delectedBlock:^(NSInteger sucessCount) {
        
        if (sucessCount>0) {
            [self deletePhotoSuccess];
        } else {
            [self deletePhotoFail];
        }
        sender.enabled = YES;
    }];
    
}

#pragma mark -

-(void) setRightBarButtonTitle:(NSString*) title{
    
    [self.rightBarButtonItem setTitle:title forState:UIControlStateNormal];
}

-(void) setRightBarButtonColor:(UIColor*) color{
    [self.rightBarButtonItem setTitleColor:color forState:UIControlStateNormal];
}


-(void) loadData{
    self.rightBarButtonItem.enabled = NO;
    self.deleteBtn.hidden = YES;
    _tipLable.hidden = YES;
    
//    [SimilarProcessView show:0];
    
    [self.imagePickerBrowser reloadData];
    if ([[PhotoFetchManager shareInstance] sp_numberOfSections] > 0) {
        [self selectSmart];
        self.rightBarButtonItem.enabled = YES;
        self.deleteBtn.hidden = NO;
    }else{
        _tipLable.hidden = NO;
        self.deleteBtn.hidden = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
        //[SVProgressHUD showSuccessWithStatus:@"没有相似的照片"];
    }
        
//        [SimilarProcessView dismiss];
    
    

}

//#pragma mark - SimilarPhotoManagerDelegate
//
//-(void)processCompleteOfLocation:(NSUInteger)section withCount:(NSUInteger)count{
//    
//    if (count>0) {
//        [SimilarProcessView show:count];
//    }
//  
//}


#pragma mark - ImagePickerBrowserDelegate

//组
- (NSInteger)numberOfSectionsForImagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser {
    return [[PhotoFetchManager shareInstance] sp_numberOfSections];
}

//组照片数
- (NSInteger)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser itemsAtSection:(NSInteger)section {
    
    return [[PhotoFetchManager shareInstance] sp_itemsAtSection:section];
}


//组标题
- (NSString*)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser titleAtInSection:(NSInteger)section {
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy年MM月dd日"];
    NSDate *date = [format dateFromString:[[PhotoFetchManager shareInstance] sp_titleForSection:section]];
    [format setDateFormat:NSLocalizedString(@"yyyy年MM月dd日", nil)];
    return [format stringFromDate:date];
}


//索引照片
- (UIImage *)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser imageAtIndexPath:(NSIndexPath *)indexPath {
    
    return [[PhotoFetchManager shareInstance] sp_imageAtIndexPath:indexPath];
}

- (void)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser didTapAtIndexPath:(NSIndexPath *)indexPath {
    
    self.curIndexPath = indexPath;
    
    NSMutableArray *selectedArray = [NSMutableArray arrayWithArray:_imagePickerBrowser.selectedIndexPaths];
    
    if (![selectedArray containsObject:indexPath]){
        [selectedArray addObject:indexPath];
    }
    
    NSArray *sortArray = [selectedArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        NSIndexPath *number1 = (NSIndexPath*)obj1 ;
        NSIndexPath *number2 = (NSIndexPath*)obj2 ;
        
        NSComparisonResult result = [number1 compare:number2];
        
        return result == NSOrderedDescending; // 升序
        //        return result == NSOrderedAscending;  // 降序
    }];
    self.willDisplayArray = [NSMutableArray arrayWithArray:sortArray];
    
    //[_imagePickerBrowser setIndex:indexPath isSelected:YES];
    
    SimilarPhotoDetailViewController *similarDetailVC = [[SimilarPhotoDetailViewController alloc] init];
    similarDetailVC.delegate = self;
    similarDetailVC.dataSource = self;
    [[AppTool currentNavigationController] pushViewController:similarDetailVC animated:YES];
    
}

- (void)imagePickerBrowser:(PhotoPickerBrowser*)imagePickerBrowser didSelectedChanged:(NSArray<NSIndexPath *> *)selects {
    if (selects.count>0) {
        [self.deleteBtn setTitle:[NSString stringWithFormat:NSLocalizedString(@"删除相似照片(%ld张)", nil),(unsigned long)selects.count] forState:0];
        self.deleteBtn.hidden =NO;
    }else{
        self.deleteBtn.hidden =YES;
    }
    if (!imagePickerBrowser.isSmart) {
       
        //[self setRightBarButtonColor:Color_FC06];
        
        [self setRightBarButtonTitle:NSLocalizedString(@"智能筛选",nil)];
    }else{
        //[self setRightBarButtonColor:Color_FC06];
        
        [self setRightBarButtonTitle:NSLocalizedString(@"取消筛选",nil)];
    
    }
    
}

- (void)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser deleteSelectedIndexPath:(NSArray<NSIndexPath *> *)selectedIndex {
    imagePickerBrowser.userInteractionEnabled=NO;
    [[PhotoFetchManager shareInstance] sp_removeSimilarImageWithIndexPaths:selectedIndex delectedBlock:^(NSInteger sucessCount) {
        
        if (sucessCount>0) {
            [self deletePhoto];
        }
        imagePickerBrowser.userInteractionEnabled=YES;
    }];

}


#pragma mark - SimilarPhotoDetailDataSource

- (NSInteger)numberOfPhotos {
    return self.willDisplayArray.count;
}

- (NSInteger)indexForVisibleItem {
    
    NSInteger index = [self.willDisplayArray indexOfObject:self.curIndexPath];
    
    return index;
}


- (BOOL)isSelectedForPhotoItemAtIndex:(NSInteger)index {
    
    NSIndexPath *objPath = self.willDisplayArray[index];
    return [_imagePickerBrowser isSelectedOfIndexPath:objPath];
}


- (PhotoAsset *)imageAssetAtIndex:(NSInteger)index{
    
    NSIndexPath *indexPath = self.willDisplayArray[index];
   
    return [[PhotoFetchManager shareInstance] sp_assetAtIndexPath:indexPath];
}

- (NSArray *)imageArrayDidSelected {
    
    NSMutableArray *selectsImgs = [NSMutableArray arrayWithCapacity:0];
    
    NSArray<NSIndexPath*> *indexPaths = [_imagePickerBrowser selectedIndexPaths];
    
    NSArray<PhotoAsset *> *assetArray = [[PhotoFetchManager shareInstance] sp_assetsAtIndexPaths:indexPaths];
    [selectsImgs addObjectsFromArray:assetArray];
    return selectsImgs;
}

- (NSInteger)numberOfSelectedPhotos {
    return [_imagePickerBrowser selectedIndexPaths].count;
}

#pragma mark - SimilarPhotoDetailDelegate

- (void)imageAsset:(PhotoAsset *)imageAsset didSelectedAtIndex:(NSInteger)index{
    NSIndexPath *objPath = self.willDisplayArray[index];
    [_imagePickerBrowser setIndex:objPath isSelected:YES];

}
- (void)imageAsset:(PhotoAsset *)imageAsset didDeselectedAtIndex:(NSInteger)index {
    NSIndexPath *objPath = self.willDisplayArray[index];
    [_imagePickerBrowser setIndex:objPath isSelected:NO];

}

- (void)deleteSelectedImage:(void(^)(BOOL))block {
    NSArray<NSIndexPath*> *indexPaths = [_imagePickerBrowser selectedIndexPaths];
    [[PhotoFetchManager shareInstance] sp_removeSimilarImageWithIndexPaths:indexPaths delectedBlock:^(NSInteger sucessCount) {
        if (block) block(sucessCount>0);
    }];
}

- (void)backActionWithVisibleItem:(NSInteger)index hasDelete:(BOOL)hasDel {
    if (hasDel) {
        [self loadData];
    }
}

//-(NSIndexPath*) indexPathFromIndex:(NSInteger) index{
//    NSInteger section;
//    NSInteger row = 0;
//    NSInteger total=0;
//    NSInteger sectionCount = [[PhotoFetchManager shareInstance] sp_numberOfSections];
//    
//    for (int s=0; s < sectionCount; s++) {
//        
//        NSInteger sectionCount = [[PhotoFetchManager shareInstance] sp_itemsAtSection:s];
//        
//        section = s;
//        if (total<=index&&index<total+sectionCount) {
//            row = index-total;
//            break;
//        }else{
//            total+=sectionCount;
//        }
//    }
//   
//    NSIndexPath *objPath = [NSIndexPath indexPathForRow:row inSection:section];
//    
//    return objPath;
//}




-(void) selectSmart{
    
    
    
    [self setRightBarButtonColor:Color_FC06];
    
    [self setRightBarButtonTitle:NSLocalizedString(@"取消筛选",nil)];
    
    [_imagePickerBrowser selectSmart];

}

-(void) selectDesc{
    
    [self setRightBarButtonColor:Color_FC06];
    
    [self setRightBarButtonTitle:NSLocalizedString(@"智能筛选",nil)];
    
    [_imagePickerBrowser selectAllDesc];
    
}




- (void)deletePhotoSuccess {
    [[LoadingAnimation shareInstance] showWithComplete:NSLocalizedString(@"删除成功",nil)];
    [self loadData];
}

- (void)deletePhotoFail {
    
}

- (void)deletePhoto{
    [[LoadingAnimation shareInstance] showWithComplete:NSLocalizedString(@"删除成功",nil)];
    [self loadData];
}

@end
