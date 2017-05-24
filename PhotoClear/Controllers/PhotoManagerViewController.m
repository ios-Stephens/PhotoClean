//
//  PhotoManagerViewController.m
//  Installer
//
//  Created by kingnet on 2017/3/10.
//  Copyright © 2017年 www.xyzs.com. All rights reserved.
//

#import "PhotoManagerViewController.h"
#import "PhotoFetchManager.h"
#import "SimilarPhotoViewController.h"
#import "ScanItemView.h"
#import "ScreenshotViewController.h"
#import "SlimViewController.h"

@interface PhotoManagerViewController ()<UIScrollViewDelegate>

@property (nonatomic, assign) BOOL fetchOK;                     //是否四个都检测完成   全部检测完成后需要将该标识符设为TRUE
@property (nonatomic, assign) BOOL needReload;

@property (nonatomic, strong) UIImageView *scanImageView;           //扫描时旋转的图片
@property (nonatomic, strong) UILabel *topScanLabel;                //扫描时上方显示的文字
@property (nonatomic, strong) UILabel *bottomScanLabel;             //扫描时下方显示的文字

@property (nonatomic, strong) UILabel *diskLabel;                   //用户显示本机剩余空间

@property (nonatomic, strong) ScanItemView *itemOne;            //相似照片检测

@property (nonatomic, strong) ScanItemView *itemTwo;                //截图检测

@property (nonatomic, strong) ScanItemView *itemThree;                  //照片瘦身

//@property (nonatomic, strong) ScanItemView *itemFour;                   //视频瘦身

@property (nonatomic, assign) NSUInteger totalClearSize;

@end

@implementation PhotoManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.titleLab.text = NSLocalizedString(@"照片清理", nil);
//    self.fetchOK = NO;
    self.totalClearSize = 0;
    self.needReload = NO;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, TTScreenWidth, TTScreenHeight-64)];
    scrollView.alwaysBounceVertical = YES;
    scrollView.delegate = self;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.contentSize = CGSizeMake(TTScreenWidth, 523);
    [self.view addSubview:scrollView];
    scrollView.backgroundColor = Color_BG01;
    
    UIView *bgView = [[UIView alloc] init];
    bgView.frame = CGRectMake(0, 0, TTScreenWidth, 283);
    bgView.backgroundColor = TTHexColor(0x077be6);
    [scrollView addSubview:bgView];
    
    
    _scanImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photoclear_animate_image"]];
    _scanImageView.frame = CGRectMake(0, 0, 180, 180);
    _scanImageView.center = CGPointMake(TTScreenWidth/2, 40+90);
    [scrollView addSubview:_scanImageView];
    
    [scrollView addSubview:self.topScanLabel];
    [scrollView addSubview:self.bottomScanLabel];
    [scrollView addSubview:self.diskLabel];
    [_diskLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(bgView.mas_bottom).mas_offset(-22.5);
        make.width.mas_equalTo(TTScreenWidth);
        make.centerX.mas_equalTo(bgView.mas_centerX);
    }];
    
    
    CGRect frame1 = CGRectMake(0, 283, TTScreenWidth, 80);
    _itemOne = [[ScanItemView alloc] initWithFrame:frame1 imageName:@"photoclear_similarphoto_disabled"];
    [_itemOne updateItemByStatus:ScanItemStatusNone type:ScanItemStatusTypeSimilarPhoto num:0 memory:0];
    XYDeclareWeakSelf
    [_itemOne setItemCilcked:^{
        [weakSelf goSimilarPhoto];
    }];
    [scrollView addSubview:_itemOne];
    
    
    CGRect frame2 = CGRectMake(0, 363, TTScreenWidth, 80);
    _itemTwo = [[ScanItemView alloc] initWithFrame:frame2 imageName:@"photoclear_screenshot_disabled"];
    [_itemTwo updateItemByStatus:ScanItemStatusNone type:ScanItemStatusTypeScreenshot num:0 memory:0];
    [_itemTwo setItemCilcked:^{
        [weakSelf goScreenShot];
    }];
    [scrollView addSubview:_itemTwo];
    
    
    CGRect frame3 = CGRectMake(0, 443, TTScreenWidth, 80);
    _itemThree = [[ScanItemView alloc] initWithFrame:frame3 imageName:@"photoclear_photoslim_disabled"];
    [_itemThree updateItemByStatus:ScanItemStatusNone type:ScanItemStatusTypePhotoSlimming num:0 memory:0];
    [_itemThree setItemCilcked:^{
        [weakSelf goSlimPhoto];
    }];
    [scrollView addSubview:_itemThree];
    
//    CGRect frame4 = CGRectMake(0, 523, TTScreenWidth, 80);
//    _itemFour = [[ScanItemView alloc] initWithFrame:frame4 imageName:@"photoclear_videoslim_disabled"];
//    [_itemFour showBottomLine:NO];
//    [_itemFour updateItemByStatus:ScanItemStatusNone type:ScanItemStatusTypeVideoSlimming num:0 memory:0];
//    [_itemFour setItemCilcked:^{
//        [self_weak_ goSlimVideo];
//    }];
//    [scrollView addSubview:_itemFour];
    
    self.fetchOK = NO;
    
    [[PhotoFetchManager shareInstance] startManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoLibraryDidChange:) name:PhotoLibraryDidChangeNotification object:nil];
    
    [self checkAlbumAuthorizationAndFetch];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.needReload) {
        // 相册数据变更，需要重新检测，此时应重新loading页面 note by yangpy
        [self reloadViewData];
    }
}

//- (void)viewDidAppear:(BOOL)animated{
//    [super viewDidAppear:animated];
//    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
//}

- (void)didMoveToParentViewController:(UIViewController *)parent{
    [super didMoveToParentViewController:parent];
    if (!parent) {//侧滑退出
        [[PhotoFetchManager shareInstance] stopManager];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    //    [super dealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[PhotoFetchManager shareInstance] stopManager];
}

- (void)leftItemButtonClick {
    [[PhotoFetchManager shareInstance] stopManager];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - getter/setter

- (UILabel *)topScanLabel{
    if(!_topScanLabel){
        _topScanLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 12)];
        _topScanLabel.center = CGPointMake(TTScreenWidth/2, 106);
        _topScanLabel.text = [NSLocalizedString(@"检查中", nil) stringByAppendingString:@" 0/0"];
        _topScanLabel.textAlignment = NSTextAlignmentCenter;
        _topScanLabel.font = Font_FS03;
        _topScanLabel.textColor = Color_FC10;
    }
    return _topScanLabel;
}

- (UILabel *)bottomScanLabel{
    if(!_bottomScanLabel){
        _bottomScanLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 39)];
        _bottomScanLabel.center = CGPointMake(TTScreenWidth/2,142.5);
        _bottomScanLabel.text = @"0%";
        _bottomScanLabel.font = TTSystemFont(39);
        _bottomScanLabel.textAlignment = NSTextAlignmentCenter;
        _bottomScanLabel.textColor = Color_FC10;
    }
    return _bottomScanLabel;
}

- (UILabel *)diskLabel{
    if(!_diskLabel){
        _diskLabel = [[UILabel alloc] init];
        _diskLabel.font = Font_FS03;
        _diskLabel.textColor = Color_FC10;
        _diskLabel.textAlignment = NSTextAlignmentCenter;
        _diskLabel.text = @"";
        [self setDiskLabelByRealTime];
    }
    return _diskLabel;
}

- (void)setFetchOK:(BOOL)fetchOK{
    _fetchOK = fetchOK;
    _itemOne.userInteractionEnabled = fetchOK;
    _itemTwo.userInteractionEnabled = fetchOK;
    _itemThree.userInteractionEnabled = fetchOK;
//    _itemFour.userInteractionEnabled = fetchOK;
}


#pragma mark - 

- (void)reloadViewData {
    XYDeclareWeakSelf;
    [self resetScanStatus];
    [self startScanAnimation];

    [[PhotoFetchManager shareInstance] albumAuthorization:^(BOOL isAuthorization) {
        if (isAuthorization) {
            weakSelf.fetchOK = NO;
            weakSelf.totalClearSize = 0;
            [weakSelf fetchPhotoAlbum];
        }
    }];
}

#pragma  mark - private mathod

- (void)checkAlbumAuthorizationAndFetch {
    XYDeclareWeakSelf;
    [[PhotoFetchManager shareInstance] albumAuthorization:^(BOOL isAuthorization) {
        if (isAuthorization) {
            //            [SVProgressHUD showWithStatus:@"loading"];
            [_itemOne updateItemByStatus:ScanItemStatusWorking type:ScanItemStatusTypeSimilarPhoto num:0 memory:0];
            [weakSelf startScanAnimation];
            [weakSelf fetchPhotoAlbum];
        }else{
            [UIAlertView showWithTitle:NSLocalizedString(@"无法访问照片",nil)
                               message:NSLocalizedString(@"请到“设置” - “隐私” - “照片”选项中允许本应用访问您的照片",nil)
                     cancelButtonTitle:NSLocalizedString(@"我知道了",nil)
                     otherButtonTitles:@[NSLocalizedString(@"立即前往",nil)]
                              tapBlock:^(UIAlertView* alertView, NSInteger buttonIndex) {
                                  
                                  if (buttonIndex==1) {
                                      NSURL *url = [NSURL URLWithString:TT_IS_IOS8_AND_UP ? UIApplicationOpenSettingsURLString : @"prefs:root=Privacy&path=PHOTOS"];
                                      [[UIApplication sharedApplication] openURL:url];
                                  }
                                  
                              }];
        }
    }];
}

- (void)fetchPhotoAlbum {
    XYDeclareWeakSelf;
    [[PhotoFetchManager shareInstance] setSpProgressBlock:^(float progress) {
        if(progress == 1.0 && weakSelf.itemOne.status != ScanItemStatusOver){
            NSUInteger count = [[PhotoFetchManager shareInstance] sp_totalNumber];
            NSUInteger estimatedClearSize = [[PhotoFetchManager shareInstance] sp_estimatedClearSize];
            [weakSelf.itemOne updateItemByStatus:ScanItemStatusOver type:ScanItemStatusTypeSimilarPhoto num:count memory:estimatedClearSize];
            weakSelf.totalClearSize += estimatedClearSize;
        }
    }];
    [[PhotoFetchManager shareInstance] setSsProgressBlock:^(float progress) {
        if (progress == 0.0) {
            [weakSelf updateScanLabel:NSLocalizedString(@"正在检测", nil) bottomText:NSLocalizedString(@"截屏照片", nil) scanStatus:_fetchOK];
            [weakSelf.itemTwo updateItemByStatus:ScanItemStatusWorking type:ScanItemStatusTypeScreenshot num:0 memory:0];
        } else if (progress == 1.0 && weakSelf.itemTwo.status == ScanItemStatusWorking) {
            NSUInteger count = [[PhotoFetchManager shareInstance] ss_totalNumber];
            NSUInteger estimatedClearSize = [[PhotoFetchManager shareInstance] ss_estimatedClearSize];
            weakSelf.totalClearSize += estimatedClearSize;
            [weakSelf.itemTwo updateItemByStatus:ScanItemStatusOver type:ScanItemStatusTypeScreenshot num:count memory:estimatedClearSize];
        }
    }];
    [[PhotoFetchManager shareInstance] setCpProgressBlock:^(float progress) {
        if (progress == 0.0) {
            [weakSelf.itemThree updateItemByStatus:ScanItemStatusWorking type:ScanItemStatusTypePhotoSlimming num:0 memory:0];
            [weakSelf updateScanLabel:NSLocalizedString(@"正在检测", nil) bottomText:NSLocalizedString(@"瘦身照片", nil) scanStatus:_fetchOK];
        } else if (progress == 1.0 && weakSelf.itemThree.status == ScanItemStatusWorking) {
            NSUInteger count = [[PhotoFetchManager shareInstance] cp_totalNumber];
            NSUInteger estimatedCompressSize = [[PhotoFetchManager shareInstance] cp_estimatedCompressSize];
            weakSelf.totalClearSize += estimatedCompressSize;
            [weakSelf.itemThree updateItemByStatus:ScanItemStatusOver type:ScanItemStatusTypePhotoSlimming num:count memory:estimatedCompressSize];
        }
    }];
//    [[PhotoFetchManager shareInstance] setCvProgressBlock:^(float progress) {
//        TTDEBUGLOG(@"检测瘦身视频progress:%.2f", progress);
//        if (progress == 0.0) {
//            [weakSelf.itemFour updateItemByStatus:ScanItemStatusWorking type:ScanItemStatusTypeVideoSlimming num:0 memory:0];
//            [weakSelf updateScanLabel:@"正在检测" bottomText:@"瘦身视频" scanStatus:_fetchOK];
//        } else if (progress == 1.0 && weakSelf.itemFour.status == ScanItemStatusWorking) {
//            NSUInteger count = [[PhotoFetchManager shareInstance] cv_numberOfVideo];
//            NSUInteger estimatedCompressSize = [[PhotoFetchManager shareInstance] cv_estimatedCompressSize];
//            weakSelf.totalClearSize += estimatedCompressSize;
//            [weakSelf.itemFour updateItemByStatus:ScanItemStatusOver type:ScanItemStatusTypeVideoSlimming num:count memory:estimatedCompressSize];
//        }
//    }];
    [[PhotoFetchManager shareInstance] setTotalProgressBlock:^(float progress, NSUInteger fetchNumber, NSUInteger totalNumber) {
        weakSelf.topScanLabel.text = [NSString stringWithFormat:@"%@ %lu/%lu",NSLocalizedString(@"检查中", nil),(unsigned long)fetchNumber,(unsigned long)totalNumber];
        weakSelf.bottomScanLabel.text = [NSString stringWithFormat:@"%lu%%", (unsigned long)(progress*100)];
    }];

    [[PhotoFetchManager shareInstance] checkPhoto:^{
        weakSelf.fetchOK = YES;
        weakSelf.needReload = NO;
        [weakSelf stopScanAnimation];
        
        NSString *clearSizeText = [Utility transformSpaceSize:_totalClearSize];
        
        [weakSelf updateScanLabel:nil bottomText:clearSizeText scanStatus:YES];
    }];

}


//开始转圈圈
- (void)startScanAnimation{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI *2.0 ];
    rotationAnimation.duration = 0.5;
    rotationAnimation.cumulative =YES;
    rotationAnimation.repeatCount =100000;
    rotationAnimation.removedOnCompletion = NO;
    [_scanImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopScanAnimation{
    [_scanImageView.layer removeAnimationForKey:@"rotationAnimation"];
}
//实时设置当前容量/总容量   因为清理完毕时需要调用
- (void)setDiskLabelByRealTime{
    CGFloat totalSpaceNum = [[[UIDevice currentDevice] totalDiskSpace] floatValue];
    CGFloat freeSpaceNum = [[[UIDevice currentDevice] freeDiskSpace] floatValue];
    NSString *total = [NSString stringWithFormat:@"%.1lf",totalSpaceNum/1024/1024/1024];            //GB
    NSString *free = [NSString stringWithFormat:@"%.1lf",freeSpaceNum/1024/1024/1024];

    _diskLabel.text = [NSString stringWithFormat:@"%@   %@G/%@G",NSLocalizedString(@"可用容量/总容量", nil),free,total];
}

//status为是否四个都扫描结束
- (void)updateScanLabel:(NSString *)topText bottomText:(NSString *)bottomText scanStatus:(BOOL)status{
    if(status == NO){
        _topScanLabel.text = topText;
        _bottomScanLabel.text = bottomText;
    }else{
        _topScanLabel.text = NSLocalizedString(@"优化后可节约空间", nil);
        _bottomScanLabel.text = bottomText;
    }
}
//重置扫描状态
- (void)resetScanStatus{
    [self setDiskLabelByRealTime];              //重新获取可用磁盘空间与总磁盘空间
    
    _topScanLabel.text = [NSLocalizedString(@"检查中", nil) stringByAppendingString:@" 0/0"];
    _bottomScanLabel.text = @"0%";
    
    
    [_itemOne updateItemByStatus:ScanItemStatusNone type:ScanItemStatusTypeSimilarPhoto num:0 memory:0];
    [_itemOne updateItemByStatus:ScanItemStatusWorking type:ScanItemStatusTypeSimilarPhoto num:0 memory:0];
    
    [_itemTwo updateItemByStatus:ScanItemStatusNone type:ScanItemStatusTypeScreenshot num:0 memory:0];

    [_itemThree updateItemByStatus:ScanItemStatusNone type:ScanItemStatusTypePhotoSlimming num:0 memory:0];

//    [_itemFour updateItemByStatus:ScanItemStatusNone type:ScanItemStatusTypeVideoSlimming num:0 memory:0];
}

#pragma mark - Action

- (void)goSimilarPhoto {
    SimilarPhotoViewController *similarPhotoVC = [[SimilarPhotoViewController alloc] init];
    [self.navigationController pushViewController:similarPhotoVC animated:YES];
}

- (void)goScreenShot {
    ScreenshotViewController *screenPhotoVC = [[ScreenshotViewController alloc] init];
    [self.navigationController pushViewController:screenPhotoVC animated:YES];
}

- (void)goSlimPhoto {
    SlimViewController *slimPhotoVC = [[SlimViewController alloc] initWithType:SlimTypePhoto];
    [self.navigationController pushViewController:slimPhotoVC animated:YES];
}

- (void)goSlimVideo {
    SlimViewController *slimVideoVC = [[SlimViewController alloc] initWithType:SlimTypeVideo];
    [self.navigationController pushViewController:slimVideoVC animated:YES];
}


- (void)photoLibraryDidChange:(NSNotification *)noti {
    if (self.isViewAppear && !self.needReload) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadViewData];
        });
    }
    self.needReload = YES;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if(scrollView.contentOffset.y<0){
        scrollView.contentOffset  = CGPointMake(0, 0);
    }
}



@end
