//
//  ALPhotoFetchManager.m
//

#import "ALPhotoFetchManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ImagePHash.h"

@interface ALPhotoFetchManager () <PhotoManagerPrivateProtocol>

//key:createDate value:照片asseturl数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *dateSectionsDic;
//key:createDate_i value::照片asseturl数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *similarImageDic;
@property (nonatomic, strong) NSArray <NSString *> *similarDateKeys;
@property (nonatomic, assign) NSUInteger similarCount;
@property (nonatomic, assign) NSUInteger similarTotalSize;
@property (nonatomic, assign) NSUInteger similarClearSize;

@property (nonatomic, copy) PhotoLoadCompleteBlock completeBlock;

@property (nonatomic, assign) NSUInteger fetchCount;

@end

@implementation ALPhotoFetchManager


@synthesize isProcessing = _isProcessing;
@synthesize completeBlock = _completeBlock;
@synthesize needReload = _needReload;
@synthesize totalNumber = _totalNumber;

- (void)albumAuthorization:(AlbumAuthorizationResultsBlock)authorizationBlock {
    ALAuthorizationStatus status =[ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusAuthorized) {
        if (authorizationBlock) {
            authorizationBlock(YES);
        }
    }else if (status == ALAuthorizationStatusNotDetermined) {
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (*stop) {
                // TODO:...
                if (authorizationBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        authorizationBlock(YES);
                    });
                }
                return;
            }
            *stop = YES;//不能省略
        } failureBlock:^(NSError *error) {
            if (authorizationBlock) {
                authorizationBlock(NO);
            }
        }];
    }else {
        if (authorizationBlock) {
            authorizationBlock(NO);
        }
    }
}

- (ALAssetsLibrary *)assetsLibrary {
    static ALAssetsLibrary *library;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

#pragma mark - Observer

- (void)startManager {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoLibraryDidChange:) name:ALAssetsLibraryChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)stopManager{
    [super stopManager];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)photoLibraryDidChange:(NSNotification *)notification {
    _needReload = YES;
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PhotoLibraryDidChangeNotification object:nil];
    }
}

#pragma mark - Public

- (void)checkPhoto:(PhotoLoadCompleteBlock)complete {
    self.completeBlock = complete;
    if (_isProcessing) return;
    [super checkPhoto:complete];
    _isProcessing = YES;
    _needReload = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __block NSUInteger count = 0;
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                count += [group numberOfAssets];
                dispatch_semaphore_signal(sema);
            }
        } failureBlock:^(NSError *error) {
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        _totalNumber = count;
        self.fetchCount = 0;
        [self fetchProgress:0];
        
        [self startFetchPhoto];
    });
}

- (void)startFetchPhoto {
    self.spProgress = 0.0;
    self.dateSectionsDic = [NSMutableDictionary<NSString *, NSMutableArray *> dictionaryWithCapacity:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index,BOOL *stop){
                
                NSString *assetType = [result valueForProperty:ALAssetPropertyType];
                if ([assetType isEqualToString:ALAssetTypePhoto]){
                    NSURL *assetUrl = (NSURL*) [[result defaultRepresentation] url];
                    
                    NSDate *assetDate = [result valueForProperty:ALAssetPropertyDate];
                    NSString *creatDateStr = [dateFormatter stringFromDate:assetDate];
                    
                    NSMutableArray *dateSectionItems;
                    if ([self.dateSectionsDic.allKeys containsObject:creatDateStr]) {
                        dateSectionItems = self.dateSectionsDic[creatDateStr];
                    }else{
                        dateSectionItems = [NSMutableArray arrayWithCapacity:0];
                        self.dateSectionsDic[creatDateStr] = dateSectionItems;
                    }
                    [dateSectionItems addObject:assetUrl];
                    self.fetchCount++;
                    [self fetchProgress:self.fetchCount];
                }
            }];
            [self fetchSimilarImage];
        } else {
            _isProcessing = NO;
        }
    } failureBlock:^(NSError *error) {
        _isProcessing = NO;
    }];
}

#pragma mark - Private

- (ALAsset *)requestAssetForUrl:(NSURL*)url {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block ALAsset *obj;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.assetsLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
            obj = asset;
            dispatch_semaphore_signal(sema);
        } failureBlock:^(NSError *error) {
            obj = nil;
            dispatch_semaphore_signal(sema);
        }];
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return obj;
}


- (UIImage *)imageWithImageKey:(id)imageKey {
    ALAsset *obj = [self requestAssetForUrl:imageKey];
    if (obj) {
        UIImage *image = [UIImage imageWithCGImage:[obj thumbnail]];
        return image;
    }
    return nil;
}

- (PhotoAsset *)assetWithImageKey:(id)imageKey {
    ALAsset *obj = [self requestAssetForUrl:imageKey];
    PhotoAsset<ALAsset *> *asset = [[PhotoAsset<ALAsset *> alloc] initWithAsset:obj];
    return asset;
}

#pragma mark - PhotoManagerProtocol

- (void)removeImageFromAlbumWithImageKeys:(NSArray *)indexs delectedBlock:(PhotoResultsBlock)delBlock {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        [UIAlertView showWithTitle:nil
                           message:@"IOS8.0 以下不支持删除功能"
                 cancelButtonTitle:@"确定"
                 otherButtonTitles:nil
                          tapBlock:^(UIAlertView* alertView, NSInteger buttonIndex) {
                              if(delBlock) delBlock(0);
                          }];
        
    }
}

- (void)removeImageFromAlbum:(NSArray<PhotoAsset *> *)assets delectedBlock:(PhotoResultsBlock)delBlock {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        [UIAlertView showWithTitle:nil
                           message:@"IOS8.0 以下不支持删除功能"
                 cancelButtonTitle:@"确定"
                 otherButtonTitles:nil
                          tapBlock:^(UIAlertView* alertView, NSInteger buttonIndex) {
                              if(delBlock) delBlock(0);
                          }];
        
    }
}

- (void)removeVideoFromAlbumWithVideoKeys:(NSArray *)indexs delectedBlock:(PhotoResultsBlock)delBlock {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        [UIAlertView showWithTitle:nil
                           message:@"IOS8.0 以下不支持删除功能"
                 cancelButtonTitle:@"确定"
                 otherButtonTitles:nil
                          tapBlock:^(UIAlertView* alertView, NSInteger buttonIndex) {
                              if(delBlock) delBlock(0);
                          }];
        
    }
}

- (void)saveImageData:(NSData *)data savedBlock:(PhotoResultsBlock)block{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(error?0:1);
                }
            });
        }];
    });
}

#pragma mark - SimilarImage

- (void)fetchSimilarImage {
    NSMutableDictionary <NSString *, NSMutableArray *> *similarResultDic = [NSMutableDictionary dictionaryWithCapacity:0];
    
    NSDictionary *imageHasDic = [self getHashOfAllImages];
    self.spProgress = 0.5;
    
    for (NSString *dateKay in imageHasDic.allKeys) {
        NSDictionary *dateSectionDic = imageHasDic[dateKay];
        NSDictionary *sectionDic = [self fetchSimilar:dateSectionDic date:dateKay];
        [similarResultDic addEntriesFromDictionary:sectionDic];
    }
    self.similarImageDic = [NSMutableDictionary dictionaryWithDictionary:similarResultDic];
    
    NSArray *sortArray = [self.similarImageDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *str1=obj1;
        NSString *str2=obj2;
        return [str1 compare:str2];
    }];
    self.similarDateKeys = [NSArray arrayWithArray:sortArray];
    
    
    NSUInteger totalSize = 0.0;
    NSUInteger clearSize = 0.0;
    NSUInteger count = 0;
    for (NSString *dateKey in self.similarDateKeys) {
        NSArray *dateSectionItems = self.similarImageDic[dateKey];
        for (NSInteger i = 0; i<dateSectionItems.count; i++) {
            NSNumber *imageKey = dateSectionItems[i];
            PhotoAsset *photoAsset = [self assetWithImageKey:imageKey];
            NSUInteger imageSize = photoAsset.bytesize;
            totalSize += imageSize;
            if (i != 0) {
                clearSize += imageSize;
            }
            count ++;
        }
    }
//    NSString *totalSizeStr = [Utility transformSpaceSize:totalSize];
//    NSString *clearSizeStr = [Utility transformSpaceSize:clearSize];
//    TTDEBUGLOG(@"similar image:{totalSize:%@, clearSize:%@}", totalSizeStr, clearSizeStr);
    self.similarCount = count;
    self.similarTotalSize = totalSize;
    self.similarClearSize = clearSize;
    self.spProgress = 1.0;
    _isProcessing = NO;
    [self fetchComplete];
}

// reture <NSString *dateKey_i, NSArray <NSNumber *imageIndex> *imageIndexArray>
- (NSDictionary *)fetchSimilar:(NSDictionary *)imageHashDic date:(NSString *)dateString {
    NSMutableDictionary <NSString *, NSMutableArray *> *similarDic = [NSMutableDictionary dictionaryWithCapacity:0];
    for (NSURL *url in imageHashDic.allKeys) {
        NSString *curHash = imageHashDic[url];
        BOOL isFetched = NO;
        for (NSString *hashKey in similarDic.allKeys) {
            if ([ImagePHash distance:curHash betweenS2:hashKey]<5) {
                NSMutableArray *hashSectionItems = similarDic[hashKey];
                [hashSectionItems addObject:url];
                isFetched = YES;
                break;
            }
        }
        if (isFetched == NO) {
            NSMutableArray *hashSectionItems = [NSMutableArray arrayWithObject:url];
            [similarDic setObject:hashSectionItems forKey:curHash];
        }
    }
    NSMutableDictionary <NSString *, NSMutableArray *> *resultDic = [NSMutableDictionary dictionaryWithCapacity:0];
    NSInteger indexNum = 0;
    for (NSString *hashKey in similarDic.allKeys) {
        NSMutableArray *indexArray = similarDic[hashKey];
        if (indexArray.count>1) {
            NSString *dateGroupKey = [NSString stringWithFormat:@"%@_%ld", dateString, (long)indexNum++];
            [resultDic setObject:indexArray forKey:dateGroupKey];
        }
    }
    if (resultDic.count>0) {
        return resultDic;
    }
    return nil;
}

// reture <NSString *dateKey, NSDictionary <NSNumber *imageIndex, NSString *hashValue> *dic>
- (NSDictionary *)getHashOfAllImages {
    NSMutableDictionary *imagehHashDic = [[NSMutableDictionary alloc] init];
    dispatch_queue_t queue = dispatch_queue_create("requestAssetForUrl258456.123456", DISPATCH_QUEUE_SERIAL);
    NSUInteger count = 0.0;
    for (NSString *dateKay in self.dateSectionsDic.allKeys) {
        NSArray *dateSectionItems = self.dateSectionsDic[dateKay];
        NSMutableDictionary *hashDic = [[NSMutableDictionary alloc] initWithCapacity:dateSectionItems.count];
        
        for (NSURL *url in dateSectionItems) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            dispatch_async(queue, ^{
                [self.assetsLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
                    UIImage *result = [UIImage imageWithCGImage:[asset thumbnail]];
                    if (result) {
                        NSString *hash = [ImagePHash getHashWithImage:result withIdentifier:url.absoluteString];
                        [hashDic setObject:hash forKey:url];
                    }
                    dispatch_semaphore_signal(sema);
                } failureBlock:^(NSError *error) {
                    dispatch_semaphore_signal(sema);
                }];
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            count++;
            [self fetchProgress:count];
        }
        [imagehHashDic setObject:hashDic forKey:dateKay];
    }
    return imagehHashDic;
}

#pragma mark - PhotoManagerSimilarProtocol


- (void)sp_removeSimilarImageWithIndexPaths:(NSArray <NSIndexPath *> *)indexs delectedBlock:(PhotoResultsBlock)delBlock{
    if(TT_SYSTEM_VERSION_LESS_THAN(@"8.0")){
        [UIAlertView showWithTitle:nil
                           message:@"IOS8.0 以下不支持删除功能"
                 cancelButtonTitle:@"确定"
                 otherButtonTitles:nil
                          tapBlock:^(UIAlertView* alertView, NSInteger buttonIndex) {
                              if(delBlock) delBlock(0);
                          }];
        
    }
}

@end
