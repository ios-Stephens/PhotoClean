//
//  SimilarPhotoDetailViewController.m
//  Installer
//
//  Created by kingnet on 16/10/21.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import "SimilarPhotoDetailViewController.h"
#import "PhotoItemView.h"
#import "PhotoItemCollectionViewCell.h"
#import "PhotoFetchManager.h"
#define kCollectionLineSpacing  4.0
#define kDeleteButtonHeight     50.0

#define ImagePickerBrowserCellIdentifier @"ImagePickerBrowserCellIdentifier"


@interface SimilarPhotoDetailViewController () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, PhotoItemCollectionViewCellDelegate, PhotoItemViewDelegate>

@property (nonatomic, strong) UIScrollView *mScrollView;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *reusePhotoItems;

@property (nonatomic, strong) UIButton *deleteBtn;

//@property (nonatomic, strong) NSMutableArray *selectArray;

@property (nonatomic, assign) NSInteger currentPage;

//@property (nonatomic, strong) NSMutableArray *imageArray;


@end

@implementation SimilarPhotoDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title =NSLocalizedString(@"清理相似照片", nil);
    
    self.reusePhotoItems = [[NSMutableArray alloc] init];
    
    _currentPage = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(indexForVisibleItem)]) {
        _currentPage = [self.dataSource indexForVisibleItem];
    }
    
    [self initUIElement];
    
    [self reloadData];
}

#pragma mark - Style

- (void)initUIElement {
    CGFloat collectionHeight = (self.view.width - kCollectionLineSpacing*5)/4;
    CGFloat scrollHeight = [self getContentViewHeight] - collectionHeight - kCollectionLineSpacing * 2 - kDeleteButtonHeight;
    
    self.mScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, [self getStartOriginY], self.view.width, scrollHeight)];
    self.mScrollView.pagingEnabled = YES;
    self.mScrollView.delegate = self;
    [self.view addSubview:self.mScrollView];
    
    
    UICollectionViewFlowLayout *_flowLayout = [[UICollectionViewFlowLayout alloc]init];
    _flowLayout.sectionInset = UIEdgeInsetsMake(0, kCollectionLineSpacing, 0, kCollectionLineSpacing);
    _flowLayout.minimumLineSpacing = kCollectionLineSpacing;
    _flowLayout.minimumInteritemSpacing = kCollectionLineSpacing;
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _flowLayout.itemSize = CGSizeMake(collectionHeight, collectionHeight);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.view.bottom-kDeleteButtonHeight-collectionHeight-kCollectionLineSpacing*2, self.view.width, collectionHeight+kCollectionLineSpacing*2) collectionViewLayout:_flowLayout];
//    self.collectionView.scrollsToTop = NO;
    self.collectionView.bounces = YES;
    self.collectionView.delegate= self;
    self.collectionView.dataSource = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    
    [self.collectionView registerClass:[PhotoItemCollectionViewCell class] forCellWithReuseIdentifier:ImagePickerBrowserCellIdentifier];
    
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    self.collectionView.allowsMultipleSelection = YES;
    [self.view addSubview:self.collectionView];
    
//    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(self.view.mas_bottom).with.offset(-kDeleteButtonHeight);
//        make.height.mas_equalTo(collectionHeight+kCollectionLineSpacing*2);
//        make.width.equalTo(self.view);
//    }];
    
    self.deleteBtn = [[UIButton alloc] init];
    self.deleteBtn.backgroundColor = HexColor(0xee3f3c);
    self.deleteBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.deleteBtn setTitle:[NSString stringWithFormat:NSLocalizedString(@"删除相似照片(%ld张)", nil), 0] forState:UIControlStateNormal];
    [self.deleteBtn addTarget:self action:@selector(deleteBottonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.deleteBtn];
    
    [self.deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.equalTo(self.view);
        make.height.mas_equalTo(kDeleteButtonHeight);
        make.width.mas_equalTo(Device_width);
    }];
}


- (void)reloadData {
    NSInteger photoCount = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfPhotos)]) {
        photoCount = [self.dataSource numberOfPhotos];
        if (_currentPage >= photoCount) _currentPage = 0;
    }
    
    NSInteger selectCount = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfPhotos)]) {
        selectCount = [self.dataSource numberOfSelectedPhotos];
    }
    [self.deleteBtn setTitle:[NSString stringWithFormat:NSLocalizedString(@"删除相似照片(%ld张)", nil),(unsigned long)selectCount] forState:UIControlStateNormal];
    
    self.mScrollView.contentSize = CGSizeMake(self.mScrollView.width * photoCount, self.mScrollView.height);
    
    [self clearInvisiblePhotoItems];
    
    [self preloadVisiblePhotoItems:_currentPage];
    
    CGPoint offset = CGPointMake(self.mScrollView.width * _currentPage, 0);
    [self.mScrollView setContentOffset:offset animated:NO];
    
    [self.collectionView reloadData];
    CGFloat collectionHeight = (self.view.width - kCollectionLineSpacing*5)/4 + kCollectionLineSpacing;
    if (_currentPage>=photoCount-4) {
        CGPoint offset = CGPointMake(collectionHeight * (photoCount-4), 0);
        [self.collectionView setContentOffset:offset animated:NO];
    } else {
        CGPoint offset = CGPointMake(collectionHeight * _currentPage, 0);
        [self.collectionView setContentOffset:offset animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (PhotoItemView *)dequeuePhotoItemViewWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    PhotoItemView *photoItem = nil;
    if (self.reusePhotoItems.count>0) {
        photoItem = [self.reusePhotoItems firstObject];
        photoItem.frame = CGRectMake(self.mScrollView.width * index, 0, self.mScrollView.width, self.mScrollView.height);
        [self.reusePhotoItems removeObjectAtIndex:0];
    } else {
        photoItem = [[PhotoItemView alloc] initWithFrame:CGRectMake(self.mScrollView.width * index, 0, self.mScrollView.width, self.mScrollView.height)];
        
    }
    photoItem.indexFlag = index;
    photoItem.delegate = self;
    return photoItem;
}

- (void)clearInvisiblePhotoItems {
    [self.mScrollView.subviews enumerateObjectsUsingBlock:^(UIView *subView, NSUInteger idx, BOOL *stop) {
        if([subView isKindOfClass:[PhotoItemView class]]){
            PhotoItemView *itemView = (PhotoItemView *)subView;
            if (![self isNeedToDisplayAtIndex:itemView.indexFlag]) {
                [itemView removeFromSuperview];
                [itemView prepareForReuse];
                [self.reusePhotoItems addObject:itemView];
            }
        }
    }];
}

- (void)preloadVisiblePhotoItems:(NSInteger)preparePage {
    NSInteger photoCount = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfPhotos)]) {
        photoCount = [self.dataSource numberOfPhotos];
        if (_currentPage >= photoCount) _currentPage = 0;
    }
    for (NSInteger index = (preparePage>1)?preparePage-1:preparePage; index<photoCount && index<preparePage+2; index++) {
        if (![self isVisibleForPhotoItemAtIndex:index]) {
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(imageAssetAtIndex:)]) {
                PhotoAsset *imageModel = [self.dataSource imageAssetAtIndex:index];
                PhotoItemView *itemView = [self dequeuePhotoItemViewWithIdentifier:nil forIndex:index];
                [itemView loadUIWithAsset:imageModel];
                if ([self isItemSelected:index]) {
                    itemView.photoSelected = YES;
                } else {
                    itemView.photoSelected = NO;
                }
                [self.mScrollView addSubview:itemView];
            }
        }
    }
}

#pragma mark - Private

- (BOOL)isItemSelected:(NSInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(isSelectedForPhotoItemAtIndex:)]) {
        return [self.dataSource isSelectedForPhotoItemAtIndex:index];
    }
    return NO;
}

- (void)selectPhotoItemAtIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    PhotoItemCollectionViewCell *cell = (PhotoItemCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    
    PhotoItemView *photoItemView = [self photoItemViewAtIndex:index];
    
    if ([self isItemSelected:index]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(imageAsset:didDeselectedAtIndex:)]) {
            [self.delegate imageAsset:photoItemView.imageAsset didDeselectedAtIndex:index];
        }
        cell.photoSelected = NO;
        photoItemView.photoSelected = NO;
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(imageAsset:didSelectedAtIndex:)]) {
            [self.delegate imageAsset:photoItemView.imageAsset didSelectedAtIndex:index];
        }
        cell.photoSelected = YES;
        photoItemView.photoSelected = YES;
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfPhotos)]) {
        NSInteger selectCount = [self.dataSource numberOfSelectedPhotos];
        [self.deleteBtn setTitle:[NSString stringWithFormat:NSLocalizedString(@"删除相似照片(%ld张)", nil), (unsigned long)selectCount] forState:UIControlStateNormal];
    }
    
    
}

- (PhotoItemView *)photoItemViewAtIndex:(NSInteger)index {
    PhotoItemView *photoItemView = nil;
    for (UIView *subView in self.mScrollView.subviews) {
        if([subView isKindOfClass:[PhotoItemView class]]){
            PhotoItemView *itemView = (PhotoItemView *)subView;
            if (itemView.indexFlag == index) {
                photoItemView = itemView;
            }
        }
    }
    return photoItemView;
}

- (NSInteger)indexOfPhotoItemView:(PhotoItemView *)photoItemView {
    if ([self.mScrollView.subviews containsObject:photoItemView]) {
        return photoItemView.indexFlag;
    }
    return -1;
}

- (BOOL)isVisibleForPhotoItemAtIndex:(NSInteger)index {
    PhotoItemView *photoItem = [self photoItemViewAtIndex:index];
    if (photoItem == nil) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isNeedToDisplayAtIndex:(NSInteger)index {
    if (index>_currentPage-2 && index<_currentPage+2) {
        return YES;
    }
    return NO;
}


#pragma mark - Action

- (void)backActionWithCurrentIndex:(NSInteger)index hasDelete:(BOOL)hasDel {
    [self.navigationController popViewControllerAnimated:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(backActionWithVisibleItem:hasDelete:)]) {
        [self.delegate backActionWithVisibleItem:index hasDelete:hasDel];
    }
}

-(void)deleteBottonAction:(UIButton*)sender {
//    if (self.dataSource && [self.dataSource respondsToSelector:@selector(imageArrayDidSelected)]) {
//        NSArray *selectArray = [self.dataSource imageArrayDidSelected];
//        if (selectArray.count>0) {
//            sender.enabled = NO;
//            NSInteger curIndex = self.currentPage;
//            if ([self.dataSource isSelectedForPhotoItemAtIndex:curIndex]) {
//                curIndex = -1;
//            }
//            
//            __weak __typeof(self)weakself = self;
//            PhotoFetchManager *photoManager = [PhotoFetchManager shareInstance];
//            [photoManager removeImageFromAlbum:selectArray delectedBlock:^(NSInteger sucessCount) {
//                if (sucessCount>0) {
//                    [weakself backActionWithCurrentIndex:curIndex hasDelete:YES];
//                }
//                sender.enabled = YES;
//            }];
//        }
//    }
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(isSelectedForPhotoItemAtIndex:)]) {
        sender.enabled = NO;
        NSInteger curIndex = self.currentPage;
        if ([self.dataSource isSelectedForPhotoItemAtIndex:curIndex]) {
            curIndex = -1;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(deleteSelectedImage:)]) {
            __weak __typeof(self)weakself = self;
            [self.delegate deleteSelectedImage:^(BOOL sucess) {
                sender.enabled = YES;
                if (sucess) {
                    [weakself backActionWithCurrentIndex:curIndex hasDelete:YES];
                }
            }];
        }
    }
}

#pragma mark - Accessor

- (void)setCurrentPage:(NSInteger)currentPage {
    if (self.collectionView && self.mScrollView) {
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:_currentPage inSection:0];
        PhotoItemCollectionViewCell *cell = (PhotoItemCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:currentIndexPath];
        cell.photoHighted = NO;
        
        _currentPage = currentPage;
        currentIndexPath = [NSIndexPath indexPathForItem:_currentPage inSection:0];
        cell = (PhotoItemCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:currentIndexPath];
        cell.photoHighted = YES;
        
        [self clearInvisiblePhotoItems];
//        [self preloadVisiblePhotoItems:_currentPage];
        
        
        CGFloat collectionHeight = (self.view.width - kCollectionLineSpacing*5)/4 + kCollectionLineSpacing;
        CGFloat curOffsetX = currentPage * collectionHeight;
        CGFloat curOffsetX_ = currentPage * collectionHeight + collectionHeight;
        CGFloat offsetX = self.collectionView.contentOffset.x;
        CGFloat offsetX_ = self.collectionView.contentOffset.x+self.view.width;
        if (offsetX>curOffsetX) {
            CGPoint offset = CGPointMake(collectionHeight * currentPage, 0);
            [self.collectionView setContentOffset:offset animated:YES];
//            [self.collectionView scrollToItemAtIndexPath:currentIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
        } else if (offsetX_<curOffsetX_) {
            CGPoint offset = CGPointMake(collectionHeight * (currentPage-3), 0);
            [self.collectionView setContentOffset:offset animated:YES];
//            [self.collectionView scrollToItemAtIndexPath:currentIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
        }
        
        CGPoint offset = CGPointMake(self.mScrollView.width * currentPage, 0);
        [self.mScrollView setContentOffset:offset animated:YES];
    }
}

#pragma mark - UIScrollViewDelegate

//- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
//    NSInteger page = scrollView.contentOffset.x/scrollView.width;
//    if (self.currentPage != page) {
//        self.currentPage = page;
//    }
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSUInteger page = scrollView.contentOffset.x / scrollView.bounds.size.width + .5f;
    if (page != self.currentPage) {
        [self preloadVisiblePhotoItems:page];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.mScrollView) {
        NSInteger page = scrollView.contentOffset.x/scrollView.width;
        if (self.currentPage != page) {
            self.currentPage = page;
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger photoCount = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfPhotos)]) {
        photoCount = [self.dataSource numberOfPhotos];
    }
    return photoCount;
    
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *cellIdentifier = ImagePickerBrowserCellIdentifier;
    PhotoItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor grayColor];
    cell.delegate = self;
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(imageAssetAtIndex:)]) {
        PhotoAsset *asset = [self.dataSource imageAssetAtIndex:indexPath.item];
        [cell setImage:[asset thumbImage]];
    }
    if ([self isItemSelected:indexPath.item]) {
        cell.photoSelected = YES;
    } else {
        cell.photoSelected = NO;
    }
    cell.photoHighted = indexPath.item == self.currentPage;
    
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    if (indexPath.item != self.currentPage) {
        [self preloadVisiblePhotoItems:indexPath.item];
        self.currentPage = indexPath.item;
    }
}

#pragma mark - PhotoItemCollectionViewCellDelegate

- (void)cellDidChecked:(PhotoItemCollectionViewCell*) cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [self selectPhotoItemAtIndex:indexPath.item];
}

#pragma mark - PhotoItemViewDelegate

- (void)photoItemDidChecked:(PhotoItemView *)photoItem {
    NSInteger index = [self indexOfPhotoItemView:photoItem];
    [self selectPhotoItemAtIndex:index];
}

@end
