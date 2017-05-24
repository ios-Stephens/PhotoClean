//
//  SlimViewController.m
//  Installer
//
//  Created by xuanpf on 17/3/16.
//  Copyright © 2017年 www.xyzs.com. All rights reserved.
//

#import "SlimViewController.h"
#import "SlimShareView.h"
//#import "TTShareToolKit.h"
#import "PhotoFetchManager.h"
//#import "AppDetailViewController.h"

#define photoTypeStr @"照片"
#define videoTypeStr @"视频"

@interface SlimViewController ()<SlimShareViewDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UIImageView *animateImageView;
@property (nonatomic, strong) UIImageView *animateBgImageView;
@property (nonatomic, strong) UILabel *numLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) UIButton *actionBtn;
@property (nonatomic, assign) NSUInteger totalNum;
@property (nonatomic, assign) NSUInteger compressedSize;
@property (nonatomic, strong) UIImageView *crossLine;

@property (nonatomic, strong) UIView *compareView;
@property (nonatomic, strong) UIImageView *beforeImage;
@property (nonatomic, strong) UIImageView *afterImage;
@property (nonatomic, strong) UILabel *beforeLabel;
@property (nonatomic, strong) UILabel *afterLabel;


@property (nonatomic, strong) UIAlertView *alert;
@property (nonatomic, assign) BOOL isCompressing;

@end

@implementation SlimViewController
@synthesize customNavBarView = _customNavBarView;

- (instancetype)initWithType:(SlimType)type{
    self = [super init];
    if (self) {
        self.type = type == SlimTypePhoto?photoTypeStr:videoTypeStr;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.type.length) {
        self.type = photoTypeStr;
    }
    [self.view setBackgroundColor:TTHexColor(0x077be6)];
    
    if ([self.type isEqualToString:photoTypeStr]) {
        self.totalNum = [[PhotoFetchManager shareInstance] cp_totalNumber];
    }else{
        self.totalNum = [[PhotoFetchManager shareInstance] cv_numberOfVideo];
    }
    
    [self.view addSubview:self.customNavBarView];
    self.customNavBarView.backgroundColor = TTClearColor;
    self.titleLab.text = [NSString stringWithFormat:@"%@%@",NSLocalizedString(self.type, nil),NSLocalizedString(@"瘦身", nil)];
    self.titleLab.textColor = TTWhiteColor;
    [self.leftItemButton setImage:[UIImage imageNamed:@"common_back_white_btn"] forState:UIControlStateNormal];
    
    [self makeCompareView];
    
    
    [self.view addSubview:self.sizeLabel];
    [self.sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.mas_equalTo(self.compareView.mas_bottom).offset(TT_IS_PHONE4?10.f:33.f);
        make.height.mas_equalTo(25.f);
    }];
    [self updateSizeLabelWithSizeStr:[Utility transformSpaceSize:[[PhotoFetchManager shareInstance] cp_estimatedCompressSize]] sizeFont:25 head:NSLocalizedString(@"优化后，预计可节约 ",nil) tail:nil];
    
    [self.view addSubview:self.numLabel];
    [self.numLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sizeLabel.mas_bottom).offset(16.f);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(12.f);
    }];
    self.numLabel.font = Font_FS03;
    NSTimeInterval timeInterval = [[PhotoFetchManager shareInstance] cp_estimatedTimeInterval];
    NSString *timeString = nil;
    if (timeInterval>60.0) {
        NSInteger time = round(timeInterval/60.0);
        timeString = [NSString stringWithFormat:@"%lu %@", (unsigned long)time,NSLocalizedString(@"分钟", nil)];
    } else {
        timeString = [NSString stringWithFormat:@"%lu %@", (unsigned long)timeInterval,NSLocalizedString(@"秒", nil)];
    }
    
    self.numLabel.text = [NSString stringWithFormat:NSLocalizedString(@"可优化照片 %lu 张，预计时间 %@",nil),(unsigned long)self.totalNum, timeString];
    
    [self.view addSubview:self.tipsLabel];
    [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(14.f);
        make.bottom.equalTo(self.view).offset(TT_IS_PHONE4?-70.f:-112.5);
    }];
    [self.tipsLabel setAttributedText:[self warningImageAppendWithString:NSLocalizedString(@" 瘦身后照片放在系统相册最后一张，便于查看",nil)]];
    self.tipsLabel.font = Font_FS03;
    
    [self.view addSubview:self.actionBtn];
    [self.actionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(32.f);
        make.right.equalTo(self.view).offset(-32.f);
        make.height.mas_equalTo(50.f);
        make.bottom.equalTo(self.view).offset(TT_IS_PHONE4?-10.f:-37.5f);
    }];
    [self.actionBtn setTitle:NSLocalizedString(@"立即优化",nil) forState:UIControlStateNormal];
    [self.actionBtn cornerRadius:25.f borderWidth:1.f borderColor:TTWhiteColor];
    [self.actionBtn addTarget:self action:@selector(startSlim) forControlEvents:UIControlEventTouchUpInside];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Style

- (void)makeCompareView {
    PhotoAsset *latestAsset = [[PhotoFetchManager shareInstance] cp_assetAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    CGSize pixelSize = latestAsset.pixelSize;
    BOOL isLandScape = pixelSize.width > pixelSize.height;
    
    CGFloat imageLeft = TT_IS_IPHONE6? 35.0 : TT_IS_IPHONE6PLUS? 38.0 : TT_IS_IPAD ? 72.0 : 30.0;
    CGFloat imageViewWidth = TT_IS_IPHONE6? 142.0 : TT_IS_IPHONE6PLUS? 157.0 : TT_IS_IPAD ? 290.0 : 121.0;
    CGFloat imageViewHeight = 77.0;
    if (isLandScape) {
        imageViewHeight = TT_IS_IPHONE6? 90.0 : TT_IS_IPHONE6PLUS? 100.0 : TT_IS_IPAD ? 184.0 : 77.0;
    } else {
        imageViewHeight = TT_IS_IPHONE6? 214.0 : TT_IS_IPHONE6PLUS? 236.0 : TT_IS_IPAD ? 438.0 : 182.0;
    }
    CGFloat compareViewHeight = 18.0+20.0+imageViewHeight;
    
    CGFloat imageDisplayWidth = 0.0;
    CGFloat imageDisplayHeight = 0.0;
    if (pixelSize.width/pixelSize.height > imageViewWidth/imageViewHeight) {
        imageDisplayWidth = imageViewWidth;
        imageDisplayHeight = pixelSize.height * imageViewWidth/pixelSize.width;
    } else {
        imageDisplayHeight = imageViewHeight;
        imageDisplayWidth = pixelSize.width * imageViewHeight/pixelSize.height;
    }
    
    self.compareView = [[UIView alloc] init];
    self.compareView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.compareView];
    [self.compareView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.mas_equalTo(self.view);
        make.top.equalTo(self.view).offset(TT_IS_PHONE4?60:TT_IS_FOURINCH?80:129);
        make.height.mas_equalTo(compareViewHeight);
    }];
    
    //优化前
    self.beforeLabel = [self imageTitleLabel];
    [self.compareView addSubview:self.beforeLabel];
    self.beforeLabel.text = NSLocalizedString(@"优化前",nil);
    [self.beforeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.compareView);
        make.left.equalTo(self.compareView).offset(imageLeft);
        make.width.mas_equalTo(imageViewWidth);
        make.height.mas_equalTo(18.0f);
    }];
    
    self.beforeImage = [[UIImageView alloc] init];
    [self.compareView addSubview:self.beforeImage];
    self.beforeImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.beforeImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(imageViewWidth);
        make.height.mas_equalTo(imageViewHeight);
        make.left.mas_equalTo(imageLeft);
        make.top.equalTo(self.beforeLabel.mas_bottom).offset(10.0);
    }];
    
    UIActivityIndicatorView *indicatView1 = [[UIActivityIndicatorView alloc] init];
    [self.beforeImage addSubview:indicatView1];
    [indicatView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.beforeImage);
    }];
    [indicatView1 startAnimating];
    XYDeclareWeakSelf
    [latestAsset requestImage:^(UIImage *result) {
        weakSelf.beforeImage.image = result;
        [indicatView1 removeFromSuperview];
    }];
    
    //优化后
    self.afterLabel = [self imageTitleLabel];
    [self.compareView addSubview:self.afterLabel];
    self.afterLabel.text = NSLocalizedString(@"优化后",nil);
    [self.afterLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.beforeLabel);
        make.right.mas_equalTo(-imageLeft);
        make.width.mas_equalTo(imageViewWidth);
        make.height.mas_equalTo(20.0);
    }];
    
    self.afterImage = [[UIImageView alloc] init];
    [self.compareView addSubview:self.afterImage];
    self.afterImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.afterImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(imageViewWidth);
        make.height.mas_equalTo(imageViewHeight);
        make.right.mas_equalTo(-imageLeft);
        make.top.equalTo(self.afterLabel.mas_bottom).offset(10.0);
    }];
    
    UIActivityIndicatorView *indicatView2 = [[UIActivityIndicatorView alloc] init];
    [self.afterImage addSubview:indicatView2];
    [indicatView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.afterImage);
    }];
    [indicatView2 startAnimating];
    
    UIImageView *titleImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slim_after"]];
    [self.afterImage addSubview:titleImage];
    [titleImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.equalTo(self.afterImage);
    }];
    
    NSString *compressField = [TTDocumentsFolderPath stringByAppendingPathComponent:@"PhotoCompressDir"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:compressField]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:compressField withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    [latestAsset requestCompressImage:compressField resultHandler:^(NSURL *outputURL, NSUInteger compressedSize) {
        NSData *data = [NSData dataWithContentsOfURL:outputURL];
        UIImage *image = [UIImage imageWithData:data];
        weakSelf.afterImage.image = image;
        CGFloat right = (imageDisplayWidth-imageViewWidth)/2.f;
        CGFloat top = (imageViewHeight-imageDisplayHeight)/2.f;
        if (titleImage && titleImage.superview) {
            [titleImage mas_updateConstraints:^(MASConstraintMaker *make) {
                make.right.mas_equalTo(right);
                make.top.mas_equalTo(top);
            }];
        }
        [indicatView2 removeFromSuperview];
        [[NSFileManager defaultManager] removeItemAtPath:[outputURL path] error:nil];
    }];
}

- (void)updateSizeLabelWithSizeStr:(NSString *)size sizeFont:(NSUInteger)font head:(NSString *)head tail:(NSString *)tail{
    NSString *headStr = head?:NSLocalizedString(@"优化后，可节约 ",nil);
    NSString *tailStr = tail?:NSLocalizedString(@" 空间",nil);
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@%@",headStr,size,tailStr] attributes:@{NSFontAttributeName:Font_FS06}];
    [attributeStr setAttributes:@{NSFontAttributeName:TTSystemFont(font)} range:NSMakeRange(headStr.length, size.length)];
    [self.sizeLabel setAttributedText:attributeStr];
}

- (void)updateNumLabelWithCurrentNum:(NSUInteger)currentNum{
    [self.numLabel setText:[NSString stringWithFormat:@"%lu/%lu%@", (unsigned long)currentNum, (unsigned long)self.totalNum,NSLocalizedString(@"张",nil)]];
}

- (void)startSlim{
    self.isCompressing = YES;
    
    [self.sizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(TT_PHONE5_P?132.f:60.f);
        make.height.mas_equalTo(21.f);
        make.left.right.equalTo(self.view);
    }];
    [self updateSizeLabelWithSizeStr:@"0B" sizeFont:21 head:nil tail:nil];
    
    [self.beforeImage removeFromSuperview];
    [self.afterImage removeFromSuperview];
    [self.beforeLabel removeFromSuperview];
    [self.afterLabel removeFromSuperview];
    
    [self.view addSubview:self.animateBgImageView];
    [self.animateBgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sizeLabel).offset(46.f);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(255.f);
    }];
    
    [self.animateBgImageView addSubview:self.animateImageView];
    [self.animateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(17.f);
        make.width.height.mas_equalTo(186.f);
        make.centerX.equalTo(self.animateBgImageView);
    }];
    
    [self.animateBgImageView addSubview:self.crossLine];
    [self.crossLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.animateImageView);
    }];
    
    [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.animateBgImageView.mas_bottom).offset(TT_IS_PHONE4?0.f:23.f);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(22.f);
    }];
    self.numLabel.font = TTSystemFont(22);
    self.numLabel.alpha = 0.8;
    [self updateNumLabelWithCurrentNum:0];
    
    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI * 2.0);
    rotationAnimation.duration = 0.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    rotationAnimation.removedOnCompletion = NO;
    [self.animateImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    [self.tipsLabel setAttributedText:[self warningImageAppendWithString:NSLocalizedString(@" 照片瘦身过程中，请不要关闭XY苹果助手",nil)]];
    
    [self.actionBtn setTitle:NSLocalizedString(@"取消",nil) forState:UIControlStateNormal];
    [self.actionBtn removeTarget:self action:@selector(startSlim) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    
    XYDeclareWeakSelf
    if ([self.type isEqualToString:photoTypeStr]) {
        [[PhotoFetchManager shareInstance] cp_startCompressPhotoBlock:^(NSUInteger count, NSUInteger compressedSize) {
            [weakSelf updateSizeLabelWithSizeStr:[Utility transformSpaceSize:compressedSize] sizeFont:21 head:nil tail:nil];
            [weakSelf updateNumLabelWithCurrentNum:count];
        } complete:^(NSUInteger count, NSUInteger compressedSize) {
            weakSelf.compressedSize = compressedSize;
            [weakSelf showSlimCompleteAlert];
        }];
    }else{
        [[PhotoFetchManager shareInstance] cv_startCompressVideoBlock:^(NSUInteger count, NSUInteger compressedSize) {
            [weakSelf updateSizeLabelWithSizeStr:[Utility transformSpaceSize:compressedSize] sizeFont:21 head:nil tail:nil];
            [weakSelf updateNumLabelWithCurrentNum:count];
        } complete:^(NSUInteger count, NSUInteger compressedSize) {
            weakSelf.compressedSize = compressedSize;
            [weakSelf showSlimCompleteAlert];
        }];
    }
}

- (void)cancelDelete {
    [self.animateImageView.layer removeAllAnimations];
    
    [self.tipsLabel setAttributedText:[self warningImageAppendWithString:NSLocalizedString(@" 需要删除已压缩照片的原图才可完成瘦身",nil)]];
    
    [self.actionBtn setTitle:NSLocalizedString(@"删除重复照片",nil) forState:UIControlStateNormal];
    [self.actionBtn removeTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBtn addTarget:self action:@selector(deleteFileAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)finishSlim{
    self.numLabel.alpha = 1.f;
    [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(TT_PHONE5_P?119.f:60.f);
        make.height.mas_equalTo(23.f);
        make.left.right.equalTo(self.view);
    }];
    self.numLabel.text = NSLocalizedString(@"瘦身已完成",nil);
    self.numLabel.font = TTSystemFont(23);
    
    [self.sizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.numLabel.mas_bottom).offset(14.f);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(21.f);
    }];
    
    [self updateSizeLabelWithSizeStr:[Utility transformSpaceSize:self.compressedSize] sizeFont:21 head:NSLocalizedString(@"已经节约 ",nil) tail:NSLocalizedString(@" 手机空间",nil)];
    
    
    [self.animateImageView.layer removeAllAnimations];
    [self.animateBgImageView removeAllSubviews];
    self.animateBgImageView.image = [UIImage imageNamed:@"slim_finished"];
    [self.animateBgImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sizeLabel.mas_bottom).offset(TT_IS_PHONE4?45.f:90.f);
        make.width.height.mas_equalTo(125.f);
        make.centerX.equalTo(self.view);
    }];

    [self.tipsLabel setAttributedText:[self warningImageAppendWithString:[NSString stringWithFormat:NSLocalizedString(@" 已删除的%@在\"相簿-最近删除\"中",nil),NSLocalizedString(self.type,nil)]]];
    self.tipsLabel.font = TTSystemFont(14);
    [self.tipsLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(TT_IS_PHONE4?-130.f:-153.f);
    }];
    
    [self.actionBtn removeFromSuperview];
    
    SlimShareView *shareView = [[SlimShareView alloc] init];
    [self.view addSubview:shareView];
    [shareView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(107);
    }];
    shareView.backgroundColor = TTWhiteColor;
    shareView.delegate = self;
}

- (void)deleteFileAction:(id)sender {
    XYDeclareWeakSelf
    if ([self.type isEqualToString:photoTypeStr]) {
        [[PhotoFetchManager shareInstance] cp_removeOriginPhoto:^(NSInteger sucessCount) {
            if (sucessCount) {
                [weakSelf finishSlim];
            }
        }];
    }else{
        [[PhotoFetchManager shareInstance] cv_removeOriginVideo:^(NSInteger sucessCount) {
            if (sucessCount) {
                [weakSelf finishSlim];
            }
        }];
    }
}


- (void)showSlimCompleteAlert {
    self.isCompressing = NO;
    if (self.alert && self.alert.visible) {
        [self.alert dismissWithClickedButtonIndex:0 animated:NO];
    }
    self.alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"瘦身即将完成，请允许XY苹果助手删除原图，否则相册会出现重复%@",nil),NSLocalizedString(self.type,nil)] message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"我知道了",nil) otherButtonTitles:nil];
    [self.alert show];
}

- (void)completeAlertDelete{
    XYDeclareWeakSelf
    if ([self.type isEqualToString:photoTypeStr]) {
        [[PhotoFetchManager shareInstance] cp_removeOriginPhoto:^(NSInteger sucessCount) {
            if (sucessCount) {
                [weakSelf finishSlim];
            } else {
                [weakSelf cancelDelete];
            }
        }];
    } else {
        [[PhotoFetchManager shareInstance] cv_removeOriginVideo:^(NSInteger sucessCount) {
            if (sucessCount) {
                [weakSelf finishSlim];
            }else{
                [weakSelf cancelDelete];
            }
        }];
    }
}

- (void)leftItemButtonClick{
    if (self.isCompressing) {
        [self cancel:nil];
    }else{
        [super leftItemButtonClick];
    }
}

- (void)cancel:(UIButton *)sender{
    self.alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"瘦身尚未完成，是否确认取消瘦身",nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"继续瘦身",nil) otherButtonTitles:NSLocalizedString(@"取消",nil), nil];
    [self.alert show];
}

- (void)cancelResultHandle:(NSInteger)sucessCount {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSAttributedString *)warningImageAppendWithString:(NSString *)str{
    NSTextAttachment *attch = [[NSTextAttachment alloc] init];
    attch.image = [UIImage imageNamed:@"slim_warning"];
    attch.bounds = CGRectMake(0, -3.f, 15.f, 15.f);
    NSAttributedString *image = [NSAttributedString attributedStringWithAttachment:attch];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:str];
    [string insertAttributedString:image atIndex:0];
    return string;
}

- (UILabel *)imageTitleLabel{
    UILabel *label = [UILabel new];
    label.font = Font_FS03;
    label.textColor = Color_FC10;
    label.textAlignment = NSTextAlignmentCenter;
    label.frame = CGRectMake(0, 0, 142, 12);
    return label;
}

#pragma mark -- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    XYDeclareWeakSelf
    if (alertView.numberOfButtons == 2) {
        if (buttonIndex != 0) {
            [UIAlertView showWithTitle:[NSString stringWithFormat:NSLocalizedString(@"瘦身尚未完成，请允许XY苹果助手删除原图，否则相册会出现重复%@",nil),NSLocalizedString(self.type,nil)] message:nil cancelButtonTitle:NSLocalizedString(@"我知道了",nil) otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if ([weakSelf.type isEqualToString:photoTypeStr]) {
                    [[PhotoFetchManager shareInstance] cp_cancelCompressPhoto:^(NSInteger sucessCount) {
                        [weakSelf cancelResultHandle:sucessCount];
                    }];
                }else{
                    [[PhotoFetchManager shareInstance] cv_cancelCompressVideo:^(NSInteger sucessCount) {
                        [weakSelf cancelResultHandle:sucessCount];
                    }];
                }
            }];
        }
    }else{
//        XYPositionInfo *positionInfo = [XYPositionInfo infoWithPosition:self.trackPosition];
        [self completeAlertDelete];
    }
}

#pragma mark -- SlimShareViewDelegate
- (void)slimShareWithType:(SlimShareType)type{
//    TTShareConentItme *shareData=[[TTShareConentItme alloc] init];
//    shareData.imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"Icon"], 1.0);
//    shareData.shareUrl = @"http://pc.xyzs.com/share";
//    shareData.title = [NSString stringWithFormat:@"我用XY苹果助手·照片管理功能，节约了%@%@的内存",[[UIDevice currentDevice] model],[Utility transformSpaceSize:self.compressedSize]];
//    shareData.content =@"XY苹果助手支持相似照片、截屏照片、照片瘦身等功能，尽快安装体验一下吧！";
//    shareData.obje = self;
//    switch (type) {
//        case SlimShareTypeWeibo:
//        {
//            if ([WeiboSDK isWeiboAppInstalled]) {
//               shareData.content = [NSString stringWithFormat:@"%@。\r\n%@ 戳→%@ %@",shareData.title, shareData.content,shareData.shareUrl,@"（分享自 @XY助手官微）"];
//            }else{
//                [UIAlertView showWithTitle:@"未安装微博客户端" message:@"是否现在去下载" cancelButtonTitle:@"以后再说" otherButtonTitles:@[@"现在下载"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
//                    if (buttonIndex == 1) {
//                        AppDetailViewController* detailController = [[AppDetailViewController alloc] init];
//                        detailController.appItunesId = @"350962117";//微博iTunesId
//                        [self.navigationController pushViewController:detailController animated:YES];
//                    }
//                }];
//                return;
//            }
//            shareData.channel =TTShareChannelWithSineWeibo;
//        }
//            break;
//        case SlimShareTypeWXTimeLine:
//        {
//            shareData.channel =TTShareChannelWithWXZoo;
//        }
//            break;
//        case SlimShareTypeWeChat:
//        {
//            shareData.channel =TTShareChannelWithWXFriend;
//        }
//            break;
//        case SlimShareTypeQzone:
//        {
//            shareData.channel =TTShareChannelWithQQZoo;
//        }
//            break;
//        case SlimShareTypeQQ:{
//            shareData.channel =TTShareChannelWithQQFirend;
//        }
//            break;
//
//        default:
//            break;
//    }
//    [[TTShareToolKit shareKit] shareToolKit:shareData];
}

#pragma mark -- getter/setter
- (UILabel *)sizeLabel{
    if (!_sizeLabel) {
        _sizeLabel = [UILabel new];
        _sizeLabel.textAlignment = NSTextAlignmentCenter;
        _sizeLabel.alpha = 0.9;
        _sizeLabel.textColor = Color_FC10;
    }
    return _sizeLabel;
}

- (UILabel *)tipsLabel{
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.textColor = Color_FC10;
    }
    return _tipsLabel;
}

- (UIImageView *)animateImageView{
    if (!_animateImageView) {
        _animateImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slim_animate_image"]];
        _animateImageView.contentMode = UIViewContentModeCenter;
    }
    return _animateImageView;
}

- (UIImageView *)animateBgImageView{
    if (!_animateBgImageView) {
        _animateBgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slim_animate_bg"]];
        _animateBgImageView.contentMode = UIViewContentModeCenter;
    }
    return _animateBgImageView;
}

- (UIImageView *)crossLine{
    if (!_crossLine) {
        _crossLine = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slim_animate_crossline"]];
        _crossLine.contentMode = UIViewContentModeCenter;
    }
    return _crossLine;
}

- (UILabel *)numLabel{
    if (!_numLabel) {
        _numLabel = [UILabel new];
        _numLabel.textColor = Color_FC10;
        _numLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _numLabel;
}

- (UIButton *)actionBtn{
    if (!_actionBtn) {
        _actionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _actionBtn.backgroundColor = TTHexColor(0x077be6);
        _actionBtn.titleLabel.font = Font_FS06;
        [_actionBtn setTitleColor:Color_FC10 forState:UIControlStateNormal];
    }
    return _actionBtn;
}

- (UIView *)customNavBarView {
    if (!_customNavBarView) {
        _customNavBarView = [super customNavBarView];
        [_customNavBarView addSubview:self.leftItemButton];
    }
    return _customNavBarView;
}

@end
