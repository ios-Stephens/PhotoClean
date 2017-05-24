//
//  PHPhotoFetchManager.m


#import "PHPhotoFetchManager.h"
#import <Photos/Photos.h>
#import "ImagePHash.h"

@interface PHPhotoFetchManager () <PHPhotoLibraryChangeObserver, PhotoManagerPrivateProtocol>

@property (nonatomic, strong) PHFetchResult<PHAsset *> *fetchResult;

// 所有照片 key:createDate value:照片编号数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *dateSectionsDic;
// 所有照片asset缓存 key:照片编号数组 value:PhotoAsset
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, PhotoAsset *> *assetCacheDic;
// 所有视频asset缓存 key:视频编号数组 value:PhotoAsset
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, PhotoAsset *> *avassetCacheDic;

// 相似照片 key:createDate_i value:照片编号数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *similarImageDic;
@property (nonatomic, strong) NSArray <NSString *> *similarDateKeys;
@property (nonatomic, assign) NSUInteger similarCount;
@property (nonatomic, assign) NSUInteger similarTotalSize;
@property (nonatomic, assign) NSUInteger similarClearSize;

// 屏幕快照 key:createDate value:照片编号数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *shotImageDic;
@property (nonatomic, strong) NSArray <NSString *> *shotDateKeys;
@property (nonatomic, assign) NSUInteger screenCount;
@property (nonatomic, assign) NSUInteger screenTotalSize;

// 瘦身照片 key:createDate value:照片编号数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *compressImageDic;
@property (nonatomic, strong) NSArray <NSString *> *compressDateKeys;
@property (nonatomic, assign) NSUInteger compressImageCount;
@property (nonatomic, assign) NSUInteger compressImageTotalSize;
@property (nonatomic, assign) NSUInteger compressImageClearSize;

// 视频检索
@property (nonatomic, strong) PHFetchResult<PHAsset *> *videoFetchResult;
// 视频 key:createDate value:视频编号数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *videoSectionDic;
@property (nonatomic, strong) NSArray <NSString *> *videoDateKeys;
@property (nonatomic, assign) NSUInteger videoCount;
@property (nonatomic, assign) NSUInteger videoTotalSize;
@property (nonatomic, assign) NSUInteger videoClearSize;


@property (nonatomic, copy) PhotoLoadCompleteBlock completeBlock;

@property (nonatomic, assign) NSUInteger fetchCount;

@end

#pragma mark - implementation

@implementation PHPhotoFetchManager

@synthesize isProcessing = _isProcessing;
@synthesize completeBlock = _completeBlock;
@synthesize needReload = _needReload;
@synthesize totalNumber = _totalNumber;


- (void)albumAuthorization:(AlbumAuthorizationResultsBlock)authorizationBlock {
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        if (authorizationBlock) {
            authorizationBlock(YES);
        }
    }else if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (authorizationBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    authorizationBlock(status == PHAuthorizationStatusAuthorized);
                });
            }
        }];
    }else{
        if (authorizationBlock) {
            authorizationBlock(NO);
        }
    }
}

#pragma mark - Observer

- (void)startManager {
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)stopManager{
    [super stopManager];
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *photoFetchResultChange = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    PHFetchResultChangeDetails *videoFetchResultChange = [changeInstance changeDetailsForFetchResult:self.videoFetchResult];

    if (photoFetchResultChange.hasIncrementalChanges || videoFetchResultChange.hasIncrementalChanges) {
        // ios10以上，系统照片处理机制导致获取fetchresult后会重新接收到照片原图变更的通知，此时不应该重新检测。故排除changedIndexes
        if ((photoFetchResultChange.insertedIndexes || photoFetchResultChange.removedIndexes || photoFetchResultChange.hasMoves) || (videoFetchResultChange.insertedIndexes || videoFetchResultChange.removedIndexes || videoFetchResultChange.hasMoves)) {
            _needReload = YES;
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                [[NSNotificationCenter defaultCenter] postNotificationName:PhotoLibraryDidChangeNotification object:nil];
            }
        }
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
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        //        options.includeAllBurstAssets = YES; //连拍快照
        if ([options respondsToSelector:@selector(setIncludeAssetSourceTypes:)]) {
            options.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary;
        }
        self.fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
        _totalNumber = [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
        
//        self.videoFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:options];
//        _totalNumber += [self.videoFetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
        
        self.fetchCount = 0;
        [self fetchProgress:0];
        
        [self startFetchPhoto];
//        [self fetchCompressVideo];
        
        _isProcessing = NO;
        [self fetchComplete];
    });
}

- (void)startFetchPhoto {
    self.spProgress = 0.0;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
    
    //all
    self.dateSectionsDic = [NSMutableDictionary<NSString *, NSMutableArray *> dictionaryWithCapacity:0];
    self.assetCacheDic = [NSMutableDictionary<NSNumber *, PhotoAsset *> dictionaryWithCapacity:0];
    //screenshot
    self.shotImageDic = [NSMutableDictionary<NSString *,NSMutableArray *> dictionaryWithCapacity:0];
    BOOL screenshotVilid = TT_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0");
    CGSize screenSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * [[UIScreen mainScreen] scale], [[UIScreen mainScreen] bounds].size.height * [[UIScreen mainScreen] scale]);
    //瘦身照片
    self.compressImageDic = [NSMutableDictionary<NSString *, NSMutableArray *> dictionaryWithCapacity:0];
    
    __block NSUInteger totalSize = 0;
    
    [self.fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 按日期分组
        NSString *creatDateStr = [dateFormatter stringFromDate:obj.creationDate];
        
        PhotoAsset<PHAsset *> *photoAsset = [[PhotoAsset<PHAsset *> alloc] initWithAsset:obj];
        NSUInteger imageSize = photoAsset.bytesize;
        
        NSMutableArray *dateSectionItems;
        if ([self.dateSectionsDic.allKeys containsObject:creatDateStr]) {
            dateSectionItems = self.dateSectionsDic[creatDateStr];
        }else{
            dateSectionItems = [NSMutableArray arrayWithCapacity:0];
            self.dateSectionsDic[creatDateStr] = dateSectionItems;
        }
        [dateSectionItems addObject:[NSNumber numberWithUnsignedInteger:idx]];
        
        BOOL isScreenshot = NO;
        if (screenshotVilid) {
            isScreenshot = obj.mediaSubtypes == PHAssetMediaSubtypePhotoScreenshot;
        } else {
            CGSize pixelSize = [photoAsset pixelSize];
            isScreenshot = CGSizeEqualToSize(pixelSize, screenSize);
        }
        
        if (isScreenshot) {
            NSMutableArray *dateSectionShots;
            if ([self.shotImageDic.allKeys containsObject:creatDateStr]) {
                dateSectionShots = self.shotImageDic[creatDateStr];
            }else{
                dateSectionShots = [NSMutableArray arrayWithCapacity:0];
                self.shotImageDic[creatDateStr] = dateSectionShots;
            }
            [dateSectionShots addObject:[NSNumber numberWithUnsignedInteger:idx]];
        } else if ([photoAsset ableToCompress] && !photoAsset.isGif) {
            NSMutableArray *dateSectionCompress;
            if ([self.compressImageDic.allKeys containsObject:creatDateStr]) {
                dateSectionCompress = self.compressImageDic[creatDateStr];
            }else{
                dateSectionCompress = [NSMutableArray arrayWithCapacity:0];
                self.compressImageDic[creatDateStr] = dateSectionCompress;
            }
            [dateSectionCompress addObject:[NSNumber numberWithUnsignedInteger:idx]];
        }
        
        totalSize += imageSize;
        [self.assetCacheDic setObject:photoAsset forKey:[NSNumber numberWithUnsignedInteger:idx]];
        self.fetchCount++;
        [self fetchProgress:self.fetchCount];
    }];
    
    //        TTDEBUGLOG(@"photo total size :%lu", (unsigned long)totalSize);
    
    [self fetchSimilarImage];
    [self fetchScreenShot];
    [self fetchCompressPhoto];
}

#pragma mark - Private

- (UIImage *)imageWithImageKey:(id)imageKey {
    PhotoAsset<PHAsset *> *asset = [self assetWithImageKey:imageKey];
    UIImage *thumbImage = [asset thumbImage];
    return thumbImage;
}

- (PhotoAsset *)assetWithImageKey:(id)imageKey {
    PhotoAsset<PHAsset *> *photoAsset = [self.assetCacheDic objectForKey:imageKey];
    if (photoAsset == nil) {
        PHAsset * phAsset = [self.fetchResult objectAtIndex:[imageKey unsignedIntegerValue]];
        photoAsset = [[PhotoAsset<PHAsset *> alloc] initWithAsset:phAsset];
        [self.assetCacheDic setObject:photoAsset forKey:imageKey];
    }
    return photoAsset;
}

#pragma mark - PhotoManagerProtocol

- (void)removeImageFromAlbumWithImageKeys:(NSArray <NSNumber *> *)indexs delectedBlock:(PhotoResultsBlock)delBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSMutableArray *assets = [NSMutableArray arrayWithCapacity:0];
        for (NSNumber *index in indexs) {
            PHAsset *obj =[self.fetchResult objectAtIndex:[index unsignedIntegerValue]];
            if (obj) {
                [assets addObject:obj];
            }
        }
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest deleteAssets:assets];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (delBlock) {
                    delBlock(success == YES ? assets.count : 0);
                }
            });
        }];
        
    });
}

- (void)removeImageFromAlbum:(NSArray<PhotoAsset *> *)assets delectedBlock:(PhotoResultsBlock)delBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *assetArray = [NSMutableArray arrayWithCapacity:0];
        for (PhotoAsset *asset in assets) {
            [assetArray addObject:asset.asset];
        }
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest deleteAssets:assetArray];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (delBlock) {
                    delBlock(success == YES ? assets.count : 0);
                }
            });
        }];
    });
}

- (void)removeVideoFromAlbumWithVideoKeys:(NSArray *)indexs delectedBlock:(PhotoResultsBlock)delBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *assets = [NSMutableArray arrayWithCapacity:0];
        for (NSNumber *index in indexs) {
            PHAsset *obj =[self.videoFetchResult objectAtIndex:[index unsignedIntegerValue]];
            if (obj) {
                [assets addObject:obj];
            }
        }
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest deleteAssets:assets];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (delBlock) {
                    delBlock(success == YES ? assets.count : 0);
                }
            });
        }];
        
    });
}

- (void)saveImageAtFileURL:(NSURL *)fileURL savedBlock:(PhotoResultsBlock)block {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(success == YES ? 1 : 0);
                }
            });
        }];
    });
}

- (void)saveImage:(UIImage *)image savedBlock:(PhotoResultsBlock)block {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(success == YES ? 1 : 0);
                }
            });
        }];
    });
}

- (void)saveVideoAtFileURL:(NSURL *)fileURL savedBlock:(PhotoResultsBlock)block {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(success == YES ? 1 : 0);
                }
            });
        }];
    });
}

- (void)saveImageData:(NSData *)data savedBlock:(PhotoResultsBlock)block{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:data options:nil];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(success == YES ? 1 : 0);
                }
            });
        }];
    });
}

#pragma mark - SimilarImage

- (void)fetchSimilarImage {
    NSMutableDictionary <NSString *, NSMutableArray *> *similarResultDic = [NSMutableDictionary dictionaryWithCapacity:0];
    
    NSDictionary *imageHasDic = [self getHashOfAllImages];
    
    for (NSString *dateKay in imageHasDic.allKeys) {
        NSDictionary *dateSectionDic = imageHasDic[dateKay];
        NSDictionary *sectionDic = [self fetchSimilar:dateSectionDic date:dateKay];
        [similarResultDic addEntriesFromDictionary:sectionDic];
    }
    self.similarImageDic = [NSMutableDictionary dictionaryWithDictionary:similarResultDic];
    
    NSArray *sortArray = [self.similarImageDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *str1=obj1;
        NSString *str2=obj2;
        NSComparisonResult result = [str1 compare:str2];
        return result == NSOrderedAscending;
    }];
    self.similarDateKeys = [NSArray arrayWithArray:sortArray];
    
    NSUInteger totalSize = 0;
    NSUInteger clearSize = 0;
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
}

// reture <NSString *dateKey_i, NSArray <NSNumber *imageIndex> *imageIndexArray>
- (NSDictionary *)fetchSimilar:(NSDictionary *)imageHashDic date:(NSString *)dateString {
    NSMutableDictionary <NSString *, NSMutableArray *> *similarDic = [NSMutableDictionary dictionaryWithCapacity:0];
    for (NSNumber *index in imageHashDic.allKeys) {
        NSString *curHash = imageHashDic[index];
        BOOL isFetched = NO;
        for (NSString *hashKey in similarDic.allKeys) {
            int distance = [ImagePHash distance:curHash betweenS2:hashKey];
            if (distance<5) {
                NSMutableArray *hashSectionItems = similarDic[hashKey];
                [hashSectionItems addObject:index];
                isFetched = YES;
                break;
            }
        }
        if (isFetched == NO) {
            NSMutableArray *hashSectionItems = [NSMutableArray arrayWithObject:index];
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
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    // 同步获得图片, 只会返回1张图片
    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    NSMutableDictionary *imagehHashDic = [[NSMutableDictionary alloc] init];
    
    for (NSString *dateKay in self.dateSectionsDic.allKeys) {
        NSArray *dateSectionItems = self.dateSectionsDic[dateKay];
        NSMutableDictionary *hashDic = [[NSMutableDictionary alloc] initWithCapacity:dateSectionItems.count];
        CGSize size =  CGSizeMake(8,8);
        for (NSNumber *index in dateSectionItems) {
            PHAsset *asset = [self.fetchResult objectAtIndex:[index unsignedIntegerValue]];
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if (result) {
                    NSString *hash= [ImagePHash getHashWithImage:result withIdentifier:asset.localIdentifier];
                    [hashDic setObject:hash forKey:index];
                }
            }];
        }
        [imagehHashDic setObject:hashDic forKey:dateKay];
    }
    return imagehHashDic;
}


#pragma mark - ScreenShot

- (void)fetchScreenShot {
    self.ssProgress = 0.0;
    
    self.screenCount = 0;
    self.screenTotalSize = 0;
    self.shotDateKeys = nil;
    if (self.shotImageDic.count>0) {
        NSArray *sortArray = [self.shotImageDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *str1=obj1;
            NSString *str2=obj2;
            return [str2 compare:str1];
        }];
        self.shotDateKeys = [NSArray arrayWithArray:sortArray];
        
        NSUInteger totalSize = 0.0;
        NSInteger count = 0;
        for (NSString *dateKey in self.shotDateKeys) {
            NSArray *dateSectionItems = self.shotImageDic[dateKey];
            for (NSInteger i = 0; i<dateSectionItems.count; i++) {
                NSNumber *imageKey = dateSectionItems[i];
                PhotoAsset *photoAsset = [self assetWithImageKey:imageKey];
                NSUInteger imageSize = photoAsset.bytesize;
                totalSize += imageSize;
                count++;
            }
        }
//        NSString *shotTotalSize = [Utility transformSpaceSize:totalSize];
//        TTDEBUGLOG(@"screenshot image totalSize:%@(totalSize:%lu) count:%ld", shotTotalSize, (unsigned long)totalSize, (long)count);
        self.screenCount = count;
        self.screenTotalSize = totalSize;
    }
    self.ssProgress = 1.0;
}

#pragma mark - Photo Compress

- (void)fetchCompressPhoto {
    self.cpProgress = 0.0;
    
    self.compressImageCount = 0;
    self.compressImageTotalSize = 0;
    self.compressImageClearSize = 0;
    self.compressDateKeys = nil;
    
    if (self.compressImageDic.count>0) {
        NSArray *sortArray = [self.compressImageDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *str1=obj1;
            NSString *str2=obj2;
            return [str1 compare:str2];
        }];
        self.compressDateKeys = [NSArray arrayWithArray:sortArray];
        
        NSUInteger totalSize = 0.0;
        NSInteger count = 0;
        NSUInteger clearSize = 0;
        for (NSString *dateKey in self.compressDateKeys) {
            NSMutableArray *dateSectionItems = self.compressImageDic[dateKey];
            NSMutableIndexSet *filteredItems = [[NSMutableIndexSet alloc] init];
            for (NSInteger i = 0; i<dateSectionItems.count; i++) {
                NSNumber *imageKey = dateSectionItems[i];
                PhotoAsset *photoAsset = [self assetWithImageKey:imageKey];
                NSUInteger imageSize = photoAsset.bytesize;
                __block NSUInteger compressedSize = 0;
                [photoAsset requestEstimatedCompressImage:^(NSUInteger estimatedCompress) {
                    compressedSize = estimatedCompress;
                }];
                if (compressedSize>0) {
                    clearSize += compressedSize;
                    totalSize += imageSize;
                    count++;
                } else {
                    [filteredItems addIndex:i];
                }
//                TTDEBUGLOG(@"able compress phot imageSize:%lu(%@)", (unsigned long)imageSize, [Utility transformSpaceSize:imageSize]);
            }
            if (filteredItems.count>0) {
                [dateSectionItems removeObjectsAtIndexes:filteredItems];
            }
        }
//        NSString *compressTotalSize = [Utility transformSpaceSize:totalSize];
//        TTDEBUGLOG(@"able compress phot totalSize:%@(totalSize:%lu) count:%ld", compressTotalSize, (unsigned long)totalSize, (long)count);
        self.compressImageCount = count;
        self.compressImageTotalSize = totalSize;
        self.compressImageClearSize = clearSize;
    }
    self.cpProgress = 1.0;
}

#pragma mark - Video Fetch

- (void)fetchCompressVideo {
    self.cvProgress = 0.0;
    
    self.videoTotalSize = 0;
    self.videoClearSize = 0;
    self.videoCount = 0;
    self.videoDateKeys = nil;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
    
    self.videoSectionDic = [NSMutableDictionary<NSString *, NSMutableArray *> dictionaryWithCapacity:0];
    self.avassetCacheDic = [NSMutableDictionary<NSNumber *, PhotoAsset *> dictionaryWithCapacity:0];
    __block NSUInteger totalSize = 0;
    __block NSUInteger clearSize = 0;
    __block NSUInteger clearCount = 0;
    
    
    [self.videoFetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        
        PhotoAsset<PHAsset *> *videoAsset = [[PhotoAsset<PHAsset *> alloc] initWithAsset:obj subType:PhotoAssetMediaSubtypeVideo];
        NSUInteger videoByteSize = videoAsset.bytesize;
        __block NSUInteger compressedSize = 0;
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [videoAsset requestAVAssetExportSession:^(AVAssetExportSession *exportSession, AVAssetExportPresetType exportPreset, NSUInteger estimatedCompress) {
            // 压缩质量不低于 AVAssetExportPresetType960x540
            if (exportPreset >= AVAssetExportPresetType960x540) {
                compressedSize = estimatedCompress;
            }
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        // 压缩质量不低于 AVAssetExportPresetType960x540
        if (compressedSize>0) {
            // 按日期分组
            NSString *creatDateStr = [dateFormatter stringFromDate:obj.creationDate];
            
            NSMutableArray *dateSectionItems;
            if ([self.videoSectionDic.allKeys containsObject:creatDateStr]) {
                dateSectionItems = self.videoSectionDic[creatDateStr];
            }else{
                dateSectionItems = [NSMutableArray arrayWithCapacity:0];
                self.videoSectionDic[creatDateStr] = dateSectionItems;
            }
            [dateSectionItems addObject:[NSNumber numberWithUnsignedInteger:idx]];
            totalSize += videoByteSize;
            clearSize += compressedSize;
            clearCount ++;
        }
        
        [self.avassetCacheDic setObject:videoAsset forKey:[NSNumber numberWithUnsignedInteger:idx]];
        self.fetchCount++;
        [self fetchProgress:self.fetchCount];
    }];
    
    if (self.videoSectionDic.count>0) {
        NSArray *sortArray = [self.videoSectionDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *str1=obj1;
            NSString *str2=obj2;
            return [str1 compare:str2];
        }];
        self.videoDateKeys = [NSArray arrayWithArray:sortArray];
        
//        NSString *videoTotalSize = [Utility transformSpaceSize:totalSize];
//        TTDEBUGLOG(@"video totalSize:%@(totalSize:%lu) count:%ld", videoTotalSize, (unsigned long)totalSize, (long)clearCount);
    }
    self.videoTotalSize = totalSize;
    self.videoClearSize = clearSize;
    self.videoCount = clearCount;
    self.cvProgress = 1.0;
}

- (PhotoAsset *)assetWithVideoKey:(id)videoKey {
    PhotoAsset<PHAsset *> *videoAsset = [self.avassetCacheDic objectForKey:videoKey];
    if (videoAsset == nil) {
        PHAsset * phAsset = [self.videoFetchResult objectAtIndex:[videoKey unsignedIntegerValue]];
        videoAsset = [[PhotoAsset<PHAsset *> alloc] initWithAsset:phAsset subType:PhotoAssetMediaSubtypeVideo];
        [self.avassetCacheDic setObject:videoAsset forKey:videoKey];
    }
    
    return videoAsset;
}


@end
