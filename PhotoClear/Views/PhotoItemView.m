//
//  PhotoItemView.m
//  Installer
//
//  Created by kingnet on 16/10/21.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import "PhotoItemView.h"

#define checkImage @"check"
#define unCheckImage @"unCheck"

@interface PhotoItemView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *mScrollView;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *checkImageView;

/** bounds */
@property (nonatomic,assign) CGRect screenBounds;

/** center*/
@property (nonatomic,assign) CGPoint screenCenter;

/** imageView的点击 */
@property (nonatomic,strong) UITapGestureRecognizer *tap_double_imageViewGesture;
@property (nonatomic,strong) UITapGestureRecognizer *tap_imageViewGesture;

@end

@implementation PhotoItemView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initUIStyle];
    }
    return self;
}

- (void)initUIStyle {
    self.mScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
    self.mScrollView.contentSize = self.bounds.size;
    self.mScrollView.maximumZoomScale = 2.0;
    self.mScrollView.minimumZoomScale = 0.5;
    self.mScrollView.delegate = self;
    [self addSubview:self.mScrollView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
    [self.mScrollView addSubview:self.imageView];
    
    self.checkImageView = [[UIImageView alloc] init];
    [self.checkImageView setImage:[UIImage imageNamed:unCheckImage]];
    [self addSubview:self.checkImageView];
    [self.checkImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top).with.offset(20);
        make.right.equalTo(self.mas_right).with.offset(-20);
        make.width.height.mas_equalTo(24);
        
    }];
    
    [self.tap_imageViewGesture requireGestureRecognizerToFail:self.tap_double_imageViewGesture];
    [self addGestureRecognizer:self.tap_imageViewGesture];
    [self addGestureRecognizer:self.tap_double_imageViewGesture];
}

- (void)prepareForReuse {
    self.imageAsset = nil;
    self.imageView.image = nil;
    self.mScrollView.zoomScale = 1.0;
    self.indexFlag = -1;
    self.delegate = nil;
}

- (void)loadUIWithAsset:(PhotoAsset *)imageAsset {
    self.imageAsset = imageAsset;
    __weak __typeof(self)weakself = self;
    [imageAsset requestImage:^(UIImage * _Nullable result) {
        weakself.imageView.image = result;
        CGSize imageSize = result.size;
        CGRect frame = [weakself calFrame:imageSize];
        weakself.imageView.frame = frame;
        weakself.mScrollView.contentSize = frame.size;
    }];
}

-(void)setPhotoSelected:(BOOL)photoSelected {
    _photoSelected = photoSelected;
    if (photoSelected) {
        [self.checkImageView setImage:[UIImage imageNamed:checkImage]];
    } else {
        [self.checkImageView setImage:[UIImage imageNamed:unCheckImage]];
    }
}

#pragma mark - Private

/*
 *  imageView单击
 */
- (UITapGestureRecognizer *)tap_imageViewGesture {
    if(_tap_imageViewGesture == nil){
        
        _tap_imageViewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap_imageViewTap:)];
        _tap_imageViewGesture.numberOfTapsRequired = 1;
    }
    
    return _tap_imageViewGesture;
}

-(UITapGestureRecognizer *)tap_double_imageViewGesture{
    
    if(_tap_double_imageViewGesture == nil){
        
        _tap_double_imageViewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap_double_imageViewTap:)];
        _tap_double_imageViewGesture.numberOfTapsRequired = 2;
    }
    
    return _tap_double_imageViewGesture;
}


-(CGRect)screenBounds {
    
    if(CGRectEqualToRect(_screenBounds, CGRectZero)){
        
        _screenBounds = self.bounds;
    }
    
    return _screenBounds;
}

-(CGPoint)screenCenter {
    if(CGPointEqualToPoint(_screenCenter, CGPointZero)){
        CGSize size = self.screenBounds.size;
        _screenCenter = CGPointMake(size.width * .5f, size.height * .5f);
    }
    
    return _screenCenter;
}


/*
 *  确定frame
 */
-(CGRect)calFrame:(CGSize)iamgeSize {
    
    CGSize size = iamgeSize;
    
    CGFloat w = size.width;
    CGFloat h = size.height;
    
    CGRect superFrame = self.screenBounds;
    CGFloat superW =superFrame.size.width;
    CGFloat superH =superFrame.size.height;
    
    CGFloat calW = superW;
    CGFloat calH = superW;
    
    if (w>=h) {//较宽
        
        if(w> superW){//比屏幕宽
            
            CGFloat scale = superW / w;
            
            //确定宽度
            calW = w * scale;
            calH = h * scale;
            
        }else if(w <= superW){//比屏幕窄，直接居中显示
            
            calW = w;
            calH = h;
        }
        
    }else if(w<h){//较高
        
        CGFloat scale1 = superH / h;
        CGFloat scale2 = superW / w;
        
        BOOL isFat = w * scale1 > superW;//比较胖
        
        CGFloat scale =isFat ? scale2 : scale1;
        
        if(h> superH){//比屏幕高
            
            //确定宽度
            calW = w * scale;
            calH = h * scale;
            
        }else if(h <= superH){//比屏幕窄，直接居中显示
            
            if(w>superW){
                
                //确定宽度
                calW = w * scale;
                calH = h * scale;
                
                
            }else{
                calW = w;
                calH = h;
            }
            
        }
    }
    
    CGFloat x = self.screenCenter.x - calW *.5f;
    CGFloat y = self.screenCenter.y - calH * .5f;
    CGRect frame = (CGRect){CGPointMake(x, y),CGSizeMake(calW, calH)};
    
    return frame;
}

#pragma mark - Action

/*
 *  imageView双击
 */
-(void)tap_double_imageViewTap:(UITapGestureRecognizer *)tap {
    
    CGFloat zoomScale = self.mScrollView.zoomScale;
    
    if(zoomScale<1.0f || zoomScale>=2.0f){
        [self.mScrollView setZoomScale:1.0f animated:YES];
    } else {
        [self.mScrollView setZoomScale:2.0f animated:YES];
    }
}

-(void)tap_imageViewTap:(UITapGestureRecognizer *)tap {
    
    self.photoSelected = !self.photoSelected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoItemDidChecked:)]) {
        [self.delegate photoItemDidChecked:self];
    }
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidZoom:(UIScrollView *)scrollView{
    
    
    CGFloat xcenter = scrollView.center.x , ycenter = scrollView.center.y;
    
    xcenter = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width/2 : xcenter;
    
    ycenter = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height/2 : ycenter;
    
    [self.imageView setCenter:CGPointMake(xcenter, ycenter)];
}

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}


@end
