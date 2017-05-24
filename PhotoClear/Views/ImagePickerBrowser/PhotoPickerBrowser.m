//
//  ImagePickerBrowser.m
//  PhoneManager
//
//  Created by Robin on 16/5/26.
//  Copyright © 2016年 www.xyzs.com. All rights reserved.
//

#import "PhotoPickerBrowser.h"
#import "PhotoPickerBrowserItemCell.h"
#import "PhotoPickerBrowserSectionHeader.h"
#define ImagePickerBrowserCellIdentifier @"ImagePickerBrowserCellIdentifier"

#define pathKey(i) [NSString stringWithFormat:@"index:%ld_%ld",(i.section),(i.item)]

@interface PhotoPickerBrowser ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,
PhotoPickerBrowserItemCellDelegate,PhotoPickerBrowserSectionHeaderDelegate>
{
    UICollectionView *_bodyView;
    BOOL _isSelectAll;
    BOOL _isSmart;
    NSMutableDictionary<NSString*,NSIndexPath*> *selects;
    
    
    
}
@end

@implementation PhotoPickerBrowser

-(instancetype) init{
    return [self initWithFrame:CGRectZero];
}

-(instancetype) initWithFrame:(CGRect)frame{

    if (self=[super initWithFrame:frame]) {
        selects = [NSMutableDictionary<NSString*,NSIndexPath*> dictionaryWithCapacity:0];
        [self initLayerOut];
    }
    
    return self;
}

-(void) reloadData{
    [selects removeAllObjects];
    
    [_bodyView reloadData];

}

-(BOOL) isSmart{

   
    return _isSmart;
}

-(void) selectAll{
    //_isSmart = NO;
    _isSmart = YES;
    _isSelectAll = !_isSelectAll;
    [selects removeAllObjects];
    NSInteger section=0;
    
    do {
        
        for (NSInteger item=0; item<[self items:section]; item++) {
            
            NSIndexPath *objPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            [selects setObject:objPath
                        forKey:pathKey(objPath)];
        }
        section++;
        
    } while (section<[self Sections]);
    
    [_bodyView reloadData];
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:didSelectedChanged:)]) {
        [self.delegate imagePickerBrowser:self didSelectedChanged:selects.allValues];
    }
}

-(void) selectAllDesc{
   _isSmart = NO;
    _isSelectAll = NO;
    [selects removeAllObjects];
    [_bodyView reloadData];
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:didSelectedChanged:)]) {
        [self.delegate imagePickerBrowser:self didSelectedChanged:selects.allValues];
    }

}

-(void) selectSmart{
    
    _isSmart = YES;
    _isSelectAll = NO;
    [selects removeAllObjects];
    NSInteger totalSection =[self Sections];
    NSInteger section=0;
    
    do {
        
        
        NSInteger itemsOfSection =[self items:section];
        if (itemsOfSection>1) {
            for (NSInteger item=1; item<itemsOfSection; item++) {
                
                NSIndexPath *objPath = [NSIndexPath indexPathForItem:item inSection:section];
                
                [selects setObject:objPath
                            forKey:pathKey(objPath)];
            }
        }
        section++;
        
    } while (section<totalSection);
    
    [_bodyView reloadData];
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:didSelectedChanged:)]) {
        [self.delegate imagePickerBrowser:self didSelectedChanged:selects.allValues];
    }

}

-(void) selectItemsWith:(NSArray<NSIndexPath*>*) indexArray{


}

-(BOOL) isSelectedOfIndexPath:(NSIndexPath*) indexPath{
   
    NSString *key = [NSString stringWithFormat:@"index:%ld_%ld",indexPath.section,indexPath.row];
   
    return [selects.allKeys containsObject:key];
    
}

-(void) addSection:(NSUInteger) section withCount:(NSUInteger) count{
   
    
//    if (section==0) {
//         [_bodyView reloadData];
//    }else{
//    
////        NSMutableArray<NSIndexPath*> *indexArray = [NSMutableArray<NSIndexPath*> arrayWithCapacity:0];
////        
////        for (NSInteger row=0; row<count; row++) {
////            
////            NSIndexPath *newPath = [NSIndexPath indexPathForItem:row inSection:section];
////            
////            [indexArray addObject:newPath];
////        }
////        [_bodyView performBatchUpdates:^{
////            [_bodyView insertItemsAtIndexPaths:indexArray];
////        } completion:^(BOOL finished) {
////            
////        }];
//        
//        
//    
//    }
    
    [_bodyView reloadData];
//    [_bodyView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:count-1 inSection:section]
//                      atScrollPosition:UICollectionViewScrollPositionBottom
//                              animated:NO];
    
    
    
    
    

    
    
    
}

-(NSArray<NSIndexPath*>*) selectedIndexPaths{
    

    NSArray *resultArray = [selects.allValues sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        NSIndexPath *number1 = obj1 ;
        NSIndexPath *number2 = obj2 ;
        
        NSComparisonResult result = [number1 compare:number2];
        
        return result == NSOrderedDescending; // 升序
        //        return result == NSOrderedAscending;  // 降序
    }];
    
    return resultArray;
}

-(NSString*) sectionTiles:(NSIndexPath*) index{
    if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:titleAtInSection:)]) {
        return [self.delegate imagePickerBrowser:self titleAtInSection:index.section];
    }
    return @"";
}

-(NSInteger) Sections{
    
    NSInteger sections=0;
    if (self.delegate&&[self.delegate respondsToSelector:@selector(numberOfSectionsForImagePickerBrowser:)]) {
        sections= [self.delegate numberOfSectionsForImagePickerBrowser:self];
    }
    return sections;
}

-(NSInteger) items{
    
    return [self items:0];
}

-(NSInteger) items:(NSInteger) section{
    if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:itemsAtSection:)]) {
        return [self.delegate imagePickerBrowser:self itemsAtSection:section];
    }
    return 0;
}



-(void) initLayerOut{
   UICollectionViewFlowLayout *_flowLayout = [[UICollectionViewFlowLayout alloc]init];
    [_flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    _flowLayout.sectionInset = UIEdgeInsetsMake(4, 4, 4, 4);
    _flowLayout.minimumLineSpacing = 4;
    _flowLayout.minimumInteritemSpacing = 4;
     
    CGFloat itemWidth = (Device_width-(4*5))/4;
    _flowLayout.itemSize =CGSizeMake(itemWidth, itemWidth);
    _bodyView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_flowLayout];
    _bodyView.scrollsToTop = NO;
    _bodyView.bounces = YES;
    _bodyView.delegate= self;
    _bodyView.dataSource = self;
    _bodyView.showsHorizontalScrollIndicator = NO;
    _bodyView.contentInset = UIEdgeInsetsMake(0,0,50,0);
    [_bodyView registerClass:[PhotoPickerBrowserItemCell class]
  forCellWithReuseIdentifier:ImagePickerBrowserCellIdentifier];
    
    [_bodyView registerClass:[PhotoPickerBrowserSectionHeader class]
  forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
         withReuseIdentifier:@"UICollectionElementKindSectionHeader"];
    
    [_bodyView setBackgroundColor:[UIColor whiteColor]];
    _bodyView.allowsMultipleSelection=YES;
    [self addSubview:_bodyView];
    
    [_bodyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.right.equalTo(self);
    }];
    
    
    

}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
  
    return [self Sections];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    return [self items:section];
    
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *cellIdentifier = ImagePickerBrowserCellIdentifier;
    PhotoPickerBrowserItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor grayColor];
    cell.delegate = self;
    [self initCell:cell atIndePath:indexPath];
    
    NSString *key = [NSString stringWithFormat:@"index:%ld_%ld",indexPath.section,indexPath.item];
    if ([selects.allKeys containsObject:key]) {
        cell.checked = YES;
    }else{
       cell.checked = NO;
    }
    return cell;
}


#pragma mark - UICollectionViewDelegate

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        PhotoPickerBrowserSectionHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"UICollectionElementKindSectionHeader"forIndexPath:indexPath];
        [headerView setTitle:[self sectionTiles:indexPath]];
        
        [headerView setDelEnable:[self isSectionHeaderEnable:indexPath]];
        headerView.delegate =self;
        headerView.section = indexPath.section;
        if (self.hiddenDelBtn) {
            [headerView delBtnHidden];
        }
        
        return headerView;
    }
    
    return nil;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    if ([self Sections]>0) {
        return CGSizeMake(Device_width, 45);
    }
    return CGSizeMake(Device_width, 1);
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:didTapAtIndexPath:)]) {
        [self.delegate imagePickerBrowser:self didTapAtIndexPath:indexPath];
    }

}

#pragma ImagePickerBrowserItemCellDelegate

-(void) cellDidClicked:(PhotoPickerBrowserItemCell*) cell{
    NSIndexPath *indexPath=[_bodyView indexPathForCell:cell];
    if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:didTapAtIndexPath:)]) {
                
        [self.delegate imagePickerBrowser:self didTapAtIndexPath:indexPath];
    }
}

-(void) cellDidChecked:(PhotoPickerBrowserItemCell*) cell{
    _isSmart = NO;
    if (_isSelectAll) {
        _isSelectAll = NO;
    }
    NSIndexPath *indexPath=[_bodyView indexPathForCell:cell];
    [self setIndex:indexPath isSelected:cell.checked];

}

#pragma ImagePickerBrowserSectionHeaderDelegate

-(void) delButtonDidClicked:(PhotoPickerBrowserSectionHeader*) header{
    
    NSMutableArray<NSIndexPath*>* sectionSelects =[NSMutableArray<NSIndexPath*> arrayWithCapacity:0];
    
    NSString *key = [NSString stringWithFormat:@"index:%ld_",header.section];
    for (NSString *objKey in selects.allKeys) {
        
        if ([objKey rangeOfString:key].location!=NSNotFound) {
            [sectionSelects addObject:selects[objKey]];
        }
    }
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:deleteSelectedIndexPath:)]) {
        [self.delegate imagePickerBrowser:self deleteSelectedIndexPath:sectionSelects];
    }
    
}


-(void) initCell:(PhotoPickerBrowserItemCell *)cell atIndePath:(NSIndexPath *)indexPath{
   
    if (self.delegate) {

        if ([self.delegate respondsToSelector:@selector(imagePickerBrowser:imageAtIndexPath:)]) {
            
            [cell setImage:[self.delegate imagePickerBrowser:self imageAtIndexPath:indexPath]];
            
        }else if ([self.delegate respondsToSelector:@selector(imagePickerBrowser:imageNameAtIndexPath:)]) {
            
            [cell setImageName:[self.delegate imagePickerBrowser:self imageNameAtIndexPath:indexPath]];
            
        }else if ([self.delegate respondsToSelector:@selector(imagePickerBrowser:imagePathAtIndexPath:)]) {
            
            [cell setImagePath:[self.delegate imagePickerBrowser:self imagePathAtIndexPath:indexPath]];
            
        }
    }
}

-(void) setIndex:(NSIndexPath*) indexPath isSelected:(BOOL) isSelected{
   
    NSString *key = [NSString stringWithFormat:@"index:%ld_%ld",indexPath.section,indexPath.item];
    
    
    BOOL hasChanged=NO;
    if (isSelected) {
        if (![selects.allKeys containsObject:key]) {
            [selects setObject:indexPath forKey:key];
            hasChanged = YES;
        }
    }else{
        if ([selects.allKeys containsObject:key]) {
            [selects removeObjectForKey:key];
            hasChanged = YES;
        }
    }
    
    if (hasChanged) {
        
//        ImagePickerBrowserSectionHeader *headerView;
//        if ([_bodyView respondsToSelector:@selector(supplementaryViewForElementKind:atIndexPath:)]) {
//            headerView = (ImagePickerBrowserSectionHeader*)[_bodyView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
//        }
//        
//        if (headerView&&[headerView isKindOfClass:[ImagePickerBrowserSectionHeader class]]) {
//            [headerView setDelEnable:[self isSectionHeaderEnable:indexPath]];
//        }else{
//            [_bodyView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
//        }
        
        [UIView setAnimationsEnabled:NO];
        [_bodyView performBatchUpdates:^{
            [_bodyView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
        } completion:^(BOOL finished) {
            [UIView setAnimationsEnabled:YES];
        }];
        
        
        if (self.delegate&&[self.delegate respondsToSelector:@selector(imagePickerBrowser:didSelectedChanged:)]) {
            [self.delegate imagePickerBrowser:self didSelectedChanged:selects.allValues];
        }
    }

}

-(BOOL) isSectionHeaderEnable:(NSIndexPath*) indexPath{
   
    NSString *key = [NSString stringWithFormat:@"index:%ld_",indexPath.section];
    for (NSString *objKey in selects.allKeys) {
        
        if ([objKey rangeOfString:key].location!=NSNotFound) {
            return YES;
        }
    }
   
    return NO;
}


@end
