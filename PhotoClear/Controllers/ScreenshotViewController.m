    //
//  ScreenshotViewController.m
//  Installer
//
//  Created by niuy on 17/3/8.
//  Copyright © 2017年 www.xyzs.com. All rights reserved.
//

#import "ScreenshotViewController.h"
#import "PhotoPickerBrowserSectionHeader.h"
#import "PhotoFetchManager.h"
#import "PhotoPickerBrowser.h"
@interface ScreenshotViewController ()<PhotoPickerBrowserDelegate>
{
    UILabel *_tipLable;
}

@property (nonatomic, strong) UIView *processView;
@property (nonatomic, strong) UIButton *deleteBtn;
@property (nonatomic, strong) UIButton *rightBarButtonItem;
@property (nonatomic, strong) PhotoPickerBrowser *imagePickerBrowser;

@end


@implementation ScreenshotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLab.text = NSLocalizedString(@"截屏图片", nil);
    
    [self.customNavBarView addSubview:self.rightBarButtonItem];
    [self.rightBarButtonItem mas_makeConstraints:^(MASConstraintMaker *make){
        make.bottom.equalTo(self.customNavBarView);
        make.height.mas_equalTo(44);
        make.right.equalTo(self.customNavBarView.mas_right).with.offset(-15);
    }];
    [self setRightBarButtonTitle:NSLocalizedString(@"取消", nil)];

    [self.view addSubview:self.imagePickerBrowser];
    
    self.deleteBtn.hidden = YES;
    [self.view addSubview:self.deleteBtn];
    [self.deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.equalTo(self.view);
        make.height.mas_equalTo(50);
        make.width.mas_equalTo(Device_width);
    }];
    
    _tipLable = [[UILabel alloc] init];
    _tipLable.text=NSLocalizedString(@"没有截屏图片需要清理", nil);
    [self.view addSubview:_tipLable];
    [_tipLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    _tipLable.hidden = YES;
    _tipLable.font = Font_FS05;
    _tipLable.textColor = Color_FC04;
    
    [self loadData];

}

-(void) viewDidAppear:(BOOL)animated{
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
        _imagePickerBrowser.hiddenDelBtn = YES;  //隐藏删除所选按钮
    }
    return _imagePickerBrowser;
}

#pragma mark - Action
-(void) leftBarButtonAction:(UIBarButtonItem*) sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightBarButtonAction:(UIButton *) sender{
    if ([sender.currentTitle isEqualToString:NSLocalizedString(@"全选", nil)]) {
        [self selectSmart];
    }else{
        [self selectDesc];
    }
}

- (void)delBottonAction:(UIButton *)sender{
    sender.enabled = NO;
    NSArray<NSIndexPath*> *indexPaths = [_imagePickerBrowser selectedIndexPaths];
 
    [[PhotoFetchManager shareInstance] ss_removeScreenImageWithIndexPaths:indexPaths delectedBlock:^(NSInteger sucessCount) {
        /*
        [UIAlertView showWithTitle:@"瘦身即将完成，请允许XY苹果助手删除原图，否则相册会出现重复图片" message:nil cancelButtonTitle:@"不允许" otherButtonTitles:@[@"删除"] tapBlock:^(UIAlertView *alertView, NSInteger sucessCount) {
            if (sucessCount > 0) {
                [self deletePhotoSuccess];
            }else{
                [self deletePhotoFail];
            }
        }];
        */
        
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
    
    [self.imagePickerBrowser reloadData];
    if ([[PhotoFetchManager shareInstance] ss_numberOfSections] > 0) {
        [self selectSmart];
        self.rightBarButtonItem.enabled = YES;
        self.deleteBtn.hidden = NO;
    }else{
        _tipLable.hidden = NO;
        self.deleteBtn.hidden = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}

#pragma mark - ImagePickerBrowserDelegate

//组
- (NSInteger)numberOfSectionsForImagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser {
    return [[PhotoFetchManager shareInstance] ss_numberOfSections];
}

//组照片数
- (NSInteger)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser itemsAtSection:(NSInteger)section {
    return [[PhotoFetchManager shareInstance] ss_itemsAtSection:section];
}

//组标题
- (NSString*)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser titleAtInSection:(NSInteger)section {
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy年MM月dd日"];
    NSDate *date = [format dateFromString:[[PhotoFetchManager shareInstance] ss_titleForSection:section]];
    [format setDateFormat:NSLocalizedString(@"yyyy年MM月dd日", nil)];
    return [format stringFromDate:date];
}

//索引照片
- (UIImage *)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser imageAtIndexPath:(NSIndexPath *)indexPath {
    return [[PhotoFetchManager shareInstance] ss_imageAtIndexPath:indexPath];
}

//删除照片
- (void)imagePickerBrowser:(PhotoPickerBrowser*)imagePickerBrowser didSelectedChanged:(NSArray<NSIndexPath *> * )selects {
    
    if (selects.count>0) {
        NSUInteger byteSize = 0;
        for (int i = 0; i<selects.count; i++) {
            NSUInteger itemSize = [[PhotoFetchManager shareInstance] ss_byteSizeOfPhotoAtIndexPath:selects[i]];
            byteSize += itemSize;
//            TTDEBUGLOG(@"screen shot image size:%lu(%@) total:%lu(%@)", (unsigned long)itemSize, [Utility transformSpaceSize:itemSize], (unsigned long)byteSize, [Utility transformSpaceSize:byteSize]);
        }
        [self.deleteBtn setTitle:[NSString stringWithFormat:@"%@(%@%@)",NSLocalizedString(@"删除", nil),NSLocalizedString(@"节约", nil),[Utility transformSpaceSize:byteSize]] forState:0];
        
        _deleteBtn.backgroundColor = HexColor(0xee3f3c);
        [_deleteBtn setTitleColor:Color_FC10 forState:UIControlStateNormal];
        self.deleteBtn.hidden =NO;
        }else{
        
        [_deleteBtn setTitle:NSLocalizedString(@"删除", nil) forState:UIControlStateNormal];
        _deleteBtn.backgroundColor = HexColor(0xf6f6f6);
        [_deleteBtn setTitleColor:Color_FC04 forState:UIControlStateNormal];
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _deleteBtn.enabled = YES;
       
    }
    if (!imagePickerBrowser.isSmart) {
        [self setRightBarButtonTitle:NSLocalizedString(@"全选", nil)];
    }else{
        [self setRightBarButtonTitle:NSLocalizedString(@"取消", nil)];
    }
}
- (void)imagePickerBrowser:(PhotoPickerBrowser *)imagePickerBrowser deleteSelectedIndexPath:(NSArray<NSIndexPath *> *)selectedIndex {
    imagePickerBrowser.userInteractionEnabled=NO;
    [[PhotoFetchManager shareInstance] ss_removeScreenImageWithIndexPaths:selectedIndex delectedBlock:^(NSInteger sucessCount) {
        
        if (sucessCount>0) {
            [self deletePhoto];
        }
        imagePickerBrowser.userInteractionEnabled=YES;
    }];
    
}

- (void)deleteSelectedImage:(void(^)(BOOL))block {
    NSArray<NSIndexPath*> *indexPaths = [_imagePickerBrowser selectedIndexPaths];
    [[PhotoFetchManager shareInstance] ss_removeScreenImageWithIndexPaths:indexPaths delectedBlock:^(NSInteger sucessCount) {
        if (block) block(sucessCount>0);
    }];
}

- (void)backActionWithVisibleItem:(NSInteger)index hasDelete:(BOOL)hasDel {
    if (hasDel) {
        [self loadData];
    }
}

-(void) selectSmart{
    
    [self setRightBarButtonColor:Color_FC06];
    
    [self setRightBarButtonTitle:NSLocalizedString(@"取消", nil)];
    
    [_imagePickerBrowser selectAll];
    
}

-(void) selectDesc{
    
    [self setRightBarButtonColor:Color_FC06];
    
    [self setRightBarButtonTitle:NSLocalizedString(@"全选", nil)];
    
    [_imagePickerBrowser selectAllDesc];
    
}

- (void)deletePhotoSuccess {
    [[LoadingAnimation shareInstance] showWithComplete:NSLocalizedString(@"删除成功", nil)];
    [self loadData];
}

- (void)deletePhotoFail {
    
}

- (void)deletePhoto{
    [[LoadingAnimation shareInstance] showWithComplete:NSLocalizedString(@"删除成功", nil)];
    [self loadData];
}

@end

