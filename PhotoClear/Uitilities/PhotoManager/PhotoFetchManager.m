//
//  PhotoFetchManager.m


#import "PhotoFetchManager.h"

NSString * const PhotoLibraryDidChangeNotification = @"FetchManagerPhotoLibraryDidChangeNotification";

@interface PhotoFetchManager () <PhotoManagerPrivateProtocol>

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *dateSectionsDic;

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *similarImageDic;
@property (nonatomic, strong) NSArray <NSString *> *similarDateKeys;
@property (nonatomic, assign) NSUInteger similarCount;
@property (nonatomic, assign) NSUInteger similarTotalSize;
@property (nonatomic, assign) NSUInteger similarClearSize;

// 屏幕快照 key:createDate value:照片编号数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *shotImageDic;
@property (nonatomic, strong) NSArray <NSString *> *shotDateKeys;
@property (nonatomic, assign) NSUInteger screenCount;
@property (nonatomic, assign) NSUInteger screenTotalSize;    //NSUInteger

// 瘦身照片 key:createDate value:照片编号数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *compressImageDic;
@property (nonatomic, strong) NSArray <NSString *> *compressDateKeys;
@property (nonatomic, assign) NSUInteger compressImageCount;
@property (nonatomic, assign) NSUInteger compressImageTotalSize;
@property (nonatomic, assign) NSUInteger compressImageClearSize;
@property (nonatomic, strong) NSMutableArray *photoCompressed;


// 视频 key:createDate value:视频编号数组
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *videoSectionDic;
@property (nonatomic, strong) NSArray <NSString *> *videoDateKeys;
@property (nonatomic, assign) NSUInteger videoCount;
@property (nonatomic, assign) NSUInteger videoTotalSize;
@property (nonatomic, assign) NSUInteger videoClearSize;
@property (nonatomic, strong) NSMutableArray *videoCompressed;

@property (nonatomic, copy) PhotoLoadCompleteBlock completeBlock;


@end

@implementation PhotoFetchManager

@synthesize spProgress = _spProgress;
@synthesize ssProgress = _ssProgress;
@synthesize cpProgress = _cpProgress;
@synthesize cvProgress = _cvProgress;

+ (instancetype)shareInstance {
    static PhotoFetchManager * shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[PhotoFetchManager alloc] init];
        
        if (TT_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            shareInstance = [NSClassFromString(@"PHPhotoFetchManager") new];
        }else{
            shareInstance = [NSClassFromString(@"ALPhotoFetchManager") new];
        }
    });
    
    return shareInstance;
}

- (void)albumAuthorization:(AlbumAuthorizationResultsBlock)authorizationBlock {
    //implementation in sub class
}

- (void)checkPhoto:(PhotoLoadCompleteBlock)complete {
    //implementation in sub class
    _spProgress = 0.0;
    _ssProgress = 0.0;
    _cpProgress = 0.0;
    _cvProgress = 0.0;
    _totalNumber = 0;
}

- (void)startManager {
    //implementation in sub class
}

- (void)stopManager {
    //implementation in sub class
    self.totalProgressBlock = nil;
    self.spProgressBlock = nil;
    self.ssProgressBlock = nil;
    self.cpProgressBlock = nil;
    self.cvProgressBlock = nil;
    self.completeBlock = nil;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.needReload) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PhotoLibraryDidChangeNotification object:nil];
    }
}

#pragma mark - Private

- (void)fetchProgress:(NSUInteger)number {
    dispatch_async(dispatch_get_main_queue(), ^{
        float progress = 0.0;
        NSUInteger count = number;
        if (number<=self.totalNumber) {
            progress = ((float)number)/((float)self.totalNumber);
        } else {
            count = self.totalNumber;
            progress = 1.0;
        }
        if (self.totalProgressBlock) self.totalProgressBlock(progress, count, self.totalNumber);
    });
}

- (void)fetchComplete {
    _isProcessing = NO;
    _needReload = NO;
    _spProgress = 1.0;
    _ssProgress = 1.0;
    _cpProgress = 1.0;
    _cvProgress = 1.0;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.totalProgressBlock = nil;
        self.spProgressBlock = nil;
        self.ssProgressBlock = nil;
        self.cpProgressBlock = nil;
        self.cvProgressBlock = nil;
        if (self.completeBlock) self.completeBlock();
        self.completeBlock = nil;
    });
}


// imageKey:index|url. override in subclass, only for photo
- (UIImage *)imageWithImageKey:(id)imageKey {
    return nil;
}
// imageKey:index|url. override in subclass,  only for photo
- (PhotoAsset *)assetWithImageKey:(id)imageKey {
    return nil;
}

- (PhotoAsset *)assetWithVideoKey:(id)videoKey {
    return nil;
}

#pragma mark - Setter

- (void)setSpProgress:(float)spProgress {
    _spProgress = spProgress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.spProgressBlock) self.spProgressBlock(spProgress);
    });
}

- (void)setSsProgress:(float)ssProgress {
    _ssProgress = ssProgress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.ssProgressBlock) self.ssProgressBlock(ssProgress);
    });
}
- (void)setCpProgress:(float)cpProgress {
    _cpProgress = cpProgress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.cpProgressBlock) self.cpProgressBlock(cpProgress);
    });
}
- (void)setCvProgress:(float)cvProgress {
    _cvProgress = cvProgress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.cvProgressBlock) self.cvProgressBlock(cvProgress);
    });
}

#pragma mark - PhotoManagerProtocol

- (void)removeImageFromAlbumWithImageKeys:(NSArray *)indexs delectedBlock:(PhotoResultsBlock)delBlock {
    //implementation in sub class
}

- (void)removeImageFromAlbum:(NSArray<PhotoAsset *> *)assets delectedBlock:(PhotoResultsBlock)delBlock {
    //implementation in sub class
}

- (void)removeVideoFromAlbumWithVideoKeys:(NSArray *)indexs delectedBlock:(PhotoResultsBlock)delBlock {
    //implementation in sub class
}

- (void)saveImageAtFileURL:(NSURL *)fileURL savedBlock:(PhotoResultsBlock)block {
    //implementation in sub class
}

- (void)saveImage:(UIImage *)image savedBlock:(PhotoResultsBlock)block {
    //implementation in sub class
}

- (void)saveVideoAtFileURL:(NSURL *)fileURL savedBlock:(PhotoResultsBlock)block {
    //implementation in sub class
}

- (void)saveImageData:(NSData *)data savedBlock:(PhotoResultsBlock)block{
    //implementation in sub class
}


#pragma mark - PhotoManagerSimilarProtocol

- (NSUInteger)sp_totalNumber {
    return self.similarCount;
}

- (NSUInteger)sp_estimatedClearSize {
    return self.similarClearSize;
}

- (NSUInteger)sp_numberOfSections {
    return self.similarDateKeys.count;
}

- (NSUInteger)sp_itemsAtSection:(NSUInteger)section {
    if(self.similarDateKeys.count>section) {
        NSString *key = self.similarDateKeys[section];
        NSArray *objData = self.similarImageDic[key];
        return objData.count;
    }
    return 0;
}

- (NSString *)sp_titleForSection:(NSUInteger)section {
    if (section < self.similarDateKeys.count) {
        
        NSString *title = self.similarDateKeys[section];
        
        return [title substringWithRange:NSMakeRange(0, 11)];
    }
    return @"";
}

- (UIImage *)sp_imageAtIndexPath:(NSIndexPath *)indexPath {
    NSString *dateKey = self.similarDateKeys[indexPath.section];
    NSArray *dateSectionItems = self.similarImageDic[dateKey];
    id imageKey = dateSectionItems[indexPath.row];
    return [self imageWithImageKey:imageKey];
}

- (PhotoAsset *)sp_assetAtIndexPath:(NSIndexPath *)indexPath {
    NSString *dateKey = self.similarDateKeys[indexPath.section];
    NSArray *dateSectionItems = self.similarImageDic[dateKey];
    id imageKey = dateSectionItems[indexPath.row];
    return [self assetWithImageKey:imageKey];
}


- (NSArray<PhotoAsset *> *)sp_assetsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableArray<PhotoAsset*> *results = [NSMutableArray<PhotoAsset*> arrayWithCapacity:0];
    for (NSIndexPath* indexPath in indexPaths) {
        PhotoAsset* asset= [self sp_assetAtIndexPath:indexPath];
        if (asset) {
            [results addObject:asset];
        }
    }
    return results;
}

// override in sub class when os_version less than ios8.0
- (void)sp_removeSimilarImageWithIndexPaths:(NSArray <NSIndexPath *> *)indexs delectedBlock:(PhotoResultsBlock)delBlock {
    NSMutableArray *deleteKeys = [NSMutableArray arrayWithCapacity:0];
    
    for (NSIndexPath *indexPath in indexs) {
        NSString *dateKey = self.similarDateKeys[indexPath.section];
        NSArray *dateSectionItems = self.similarImageDic[dateKey];
        id imageKey = dateSectionItems[indexPath.row];
        [deleteKeys addObject:imageKey];
    }
    [self removeImageFromAlbumWithImageKeys:deleteKeys delectedBlock:^(NSInteger sucessCount) {
        if (sucessCount>0) {
            [self removeSimilarIndexPaths:indexs];
        }
        delBlock(sucessCount);
    }];
}

- (void)removeSimilarIndexPaths:(NSArray <NSIndexPath *> *)indexs {
    NSMutableDictionary <NSString *, NSMutableIndexSet *> *deleIndexDic = [NSMutableDictionary<NSString *, NSMutableIndexSet *> dictionaryWithCapacity:0];
    
    for (NSIndexPath *indexPath in indexs) {
        NSString *sectionKey = self.similarDateKeys[indexPath.section];
        
        NSMutableIndexSet *objSet = [deleIndexDic valueForKey:sectionKey];
        if (objSet == nil) {
            objSet = [NSMutableIndexSet indexSet];
            [deleIndexDic setObject:objSet forKey:sectionKey];
        }
        [objSet addIndex:indexPath.row];
    }
    
    for (NSString *sectionKey in deleIndexDic.allKeys) {
        NSMutableIndexSet *inxSet = deleIndexDic[sectionKey];
        NSMutableArray *dateSectionItems = self.similarImageDic[sectionKey];
        @try {
            [dateSectionItems removeObjectsAtIndexes:inxSet];
        } @catch (NSException *exception) {
            
        } @finally {
            
        }
        if (dateSectionItems.count<=1) {
            [self.similarImageDic removeObjectForKey:sectionKey];
        }
    }
    NSArray *sortArray=[self.similarImageDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *str1=obj1;
        NSString *str2=obj2;
        return [str1 compare:str2];
    }];
    self.similarDateKeys = [NSArray arrayWithArray:sortArray];
}

#pragma mark - PhotoManagerScreenshotProtocol

- (NSUInteger)ss_totalNumber {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return 0;
    }
    return self.screenCount;
}

- (NSUInteger)ss_estimatedClearSize {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return 0;
    }
    return self.screenTotalSize;
}

- (NSUInteger)ss_numberOfSections {
    return self.shotDateKeys.count;
}

- (NSUInteger)ss_itemsAtSection:(NSUInteger)section {
    if(self.shotDateKeys.count>section) {
        NSString *key = self.shotDateKeys[section];
        NSArray *objData = self.shotImageDic[key];
        return objData.count;
    }
    return 0;
}

- (NSString *)ss_titleForSection:(NSUInteger)section {
    if (section < self.shotDateKeys.count) {
        
        NSString *title = self.shotDateKeys[section];
        
        return [title substringWithRange:NSMakeRange(0, 11)];
    }
    return @"";
}

- (UIImage *)ss_imageAtIndexPath:(NSIndexPath *)indexPath {
    NSString *dateKey = self.shotDateKeys[indexPath.section];
    NSArray *dateSectionItems = self.shotImageDic[dateKey];
    id imageKey = dateSectionItems[indexPath.row];
    return [self imageWithImageKey:imageKey];
}

- (NSUInteger)ss_byteSizeOfPhotoAtIndexPath:(NSIndexPath *)indexPath {
    NSString *dateKey = self.shotDateKeys[indexPath.section];
    NSArray *dateSectionItems = self.shotImageDic[dateKey];
    id imageKey = dateSectionItems[indexPath.row];
    PhotoAsset *photoAsset = [self assetWithImageKey:imageKey];
    return photoAsset.bytesize;
}

- (void)ss_removeScreenImageWithIndexPaths:(NSArray <NSIndexPath *> *)indexs delectedBlock:(PhotoResultsBlock)delBlock {
    NSMutableArray *deleteKeys = [NSMutableArray arrayWithCapacity:0];
    
    for (NSIndexPath *indexPath in indexs) {
        NSString *dateKey = self.shotDateKeys[indexPath.section];
        NSArray *dateSectionItems = self.shotImageDic[dateKey];
        id imageKey = dateSectionItems[indexPath.row];
        [deleteKeys addObject:imageKey];
    }
    [self removeImageFromAlbumWithImageKeys:deleteKeys delectedBlock:^(NSInteger sucessCount) {
        if (sucessCount>0) {
            [self removeScreenIndexPaths:indexs];
        }
        delBlock(sucessCount);
    }];
}

- (void)removeScreenIndexPaths:(NSArray <NSIndexPath *> *)indexs {
    NSMutableDictionary <NSString *, NSMutableIndexSet *> *deleIndexDic = [NSMutableDictionary<NSString *, NSMutableIndexSet *> dictionaryWithCapacity:0];
    
    for (NSIndexPath *indexPath in indexs) {
        NSString *sectionKey = self.shotDateKeys[indexPath.section];
        
        NSMutableIndexSet *objSet = [deleIndexDic valueForKey:sectionKey];
        if (objSet == nil) {
            objSet = [NSMutableIndexSet indexSet];
            [deleIndexDic setObject:objSet forKey:sectionKey];
        }
        [objSet addIndex:indexPath.row];
    }
    
    for (NSString *sectionKey in deleIndexDic.allKeys) {
        NSMutableIndexSet *inxSet = deleIndexDic[sectionKey];
        NSMutableArray *dateSectionItems = self.shotImageDic[sectionKey];
        @try {
            [dateSectionItems removeObjectsAtIndexes:inxSet];
        } @catch (NSException *exception) {
            
        } @finally {
            
        }

        if (dateSectionItems.count <= 0) {

            [self.shotImageDic removeObjectForKey:sectionKey];
        }
    }
    NSArray *sortArray = [self.shotImageDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *str1=obj1;
        NSString *str2=obj2;
        return [str2 compare:str1];
    }];
    self.shotDateKeys = [NSArray arrayWithArray:sortArray];
}

#pragma mark - PhotoManagerCompressPhotoProtocol

- (NSUInteger)cp_totalNumber {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return 0;
    }
    return self.compressImageCount;
}

- (NSUInteger)cp_estimatedCompressSize {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return 0;
    }
    return self.compressImageClearSize;
}

- (NSTimeInterval)cp_estimatedTimeInterval {
    NSTimeInterval itemTiem = 1.5;
    return itemTiem*self.compressImageCount;
}

- (NSUInteger)cp_numberOfSections {
    return self.compressDateKeys.count;
}

- (NSUInteger)cp_itemsAtSection:(NSUInteger)section {
    if(self.compressDateKeys.count>section) {
        NSString *key = self.compressDateKeys[section];
        NSArray *objData = self.compressImageDic[key];
        return objData.count;
    }
    return 0;
}

- (PhotoAsset *)cp_assetAtIndexPath:(NSIndexPath *)indexPath {
    NSString *dateKey = self.compressDateKeys[indexPath.section];
    NSArray *dateSectionItems = self.compressImageDic[dateKey];
    id imageKey = dateSectionItems[indexPath.row];
    return [self assetWithImageKey:imageKey];
}

- (void)cp_startCompressPhotoBlock:(void(^)(NSUInteger count, NSUInteger compressedSize))progressBlock complete:(void(^)(NSUInteger count, NSUInteger compressedSize))completeBlock{
    NSString *compressField = [TTDocumentsFolderPath stringByAppendingPathComponent:@"PhotoCompressDir"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:compressField]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:compressField withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (self.compressImageCount>0) {
//            float progress = 0.0;
            __block NSInteger compressCount = 0;
            __block NSInteger compressOKCount = 0;
            __block NSInteger compressedTotalSize = 0;
            
            self.photoCompressed = [[NSMutableArray alloc] initWithCapacity:self.videoCount];
            
            dispatch_queue_t queue = dispatch_queue_create("compressPhoto.queue", DISPATCH_QUEUE_SERIAL);
            for (NSString *dateKey in self.compressDateKeys) {
                if (self.photoCompressed == nil) return;
                NSArray *dateSectionItems = self.compressImageDic[dateKey];
                for (id imageKey in dateSectionItems) {
                    if (self.photoCompressed == nil) return;
                    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                    dispatch_async(queue, ^{
                        PhotoAsset *photoAsset = [self assetWithImageKey:imageKey];
                        [photoAsset requestCompressImage:compressField resultHandler:^(NSURL *outputURL, NSUInteger compressedSize) {
                            compressedTotalSize += compressedSize;
                            if (self.photoCompressed == nil) return;
                            [self saveImageAtFileURL:outputURL savedBlock:^(NSInteger sucessCount) {
                                if (sucessCount) {
                                    compressOKCount ++;
                                    @synchronized (self.photoCompressed) {
                                        [self.photoCompressed addObject:imageKey];
                                    }
                                    NSString *outputPath = [outputURL path];
                                    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
                                        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:NULL];
                                    }
                                }
                                compressCount ++;
                                dispatch_semaphore_signal(sema);
                            }];
                        }];
                    });
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
//                    progress = (float)compressCount/(float)self.compressImageCount;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressBlock) progressBlock(compressCount, compressedTotalSize);
                    });
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSFileManager defaultManager] removeItemAtPath:compressField error:NULL];
                if (completeBlock) completeBlock(compressOKCount, compressedTotalSize);
            });
        }
    });
}

- (void)cp_removeOriginPhoto:(PhotoResultsBlock)delBlock {
    if (self.compressImageCount>0 && self.photoCompressed) {
        NSString *compressField = [TTDocumentsFolderPath stringByAppendingPathComponent:@"PhotoCompressDir"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:compressField]) {
            [[NSFileManager defaultManager] removeItemAtPath:compressField error:NULL];
        }
        NSArray *deleArray = [NSArray arrayWithArray:self.photoCompressed];
        [self removeImageFromAlbumWithImageKeys:deleArray delectedBlock:^(NSInteger sucessCount) {
            if (sucessCount>0) {
                self.compressImageCount = 0;
                self.compressImageTotalSize = 0;
                self.compressImageClearSize = 0;
                self.compressDateKeys = nil;
                self.compressImageDic = nil;
                self.photoCompressed = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (delBlock) delBlock(sucessCount);
            });
        }];
    }
}

- (void)cp_cancelCompressPhoto:(PhotoResultsBlock)delBlock {
    if (self.compressImageCount>0 && self.photoCompressed) {
        @synchronized (self.photoCompressed) {
            if (self.photoCompressed.count>0) {
                [self cp_removeOriginPhoto:delBlock];
            } else {
                if (delBlock) delBlock(0);
            }
            self.photoCompressed = nil;
        }
    } else {
        if (delBlock) delBlock(0);
    }
    
}

#pragma mark - PhotoManagerCompressVideoProtocol

- (NSUInteger)cv_numberOfVideo {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return 0;
    }
    return self.videoCount;
}

- (NSUInteger)cv_estimatedCompressSize {
    if (TT_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return 0;
    }
    return self.videoClearSize;
}

- (void)cv_startCompressVideoBlock:(void(^)(NSUInteger count, NSUInteger compressedSize))progressBlock complete:(void(^)(NSUInteger count, NSUInteger compressedSize))completeBlock{
    NSString *videoField = [TTDocumentsFolderPath stringByAppendingPathComponent:@"VideoCompressDir"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:videoField]) {
         [[NSFileManager defaultManager] createDirectoryAtPath:videoField withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (self.videoCount>0) {
//            float progress = 0.0;
            __block NSInteger compressCount = 0;
            __block NSInteger compressOKCount = 0;
            __block NSInteger compressedTotalSize = 0;
            
            self.videoCompressed = [[NSMutableArray alloc] initWithCapacity:self.videoCount];
            
            dispatch_queue_t queue = dispatch_queue_create("compressVideo.queue", DISPATCH_QUEUE_SERIAL);
            for (NSString *dateKey in self.videoDateKeys) {
                if (self.videoCompressed == nil) return;
                NSArray *dateSectionItems = self.videoSectionDic[dateKey];
                for (id videoKey in dateSectionItems) {
                    if (self.videoCompressed == nil) return;
                    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                    dispatch_async(queue, ^{
                        PhotoAsset *videoAsset = [self assetWithVideoKey:videoKey];
                        [videoAsset requestCompressVideo:videoField resultHandler:^(NSURL *outputURL, NSUInteger compressedSize) {
                            if (self.videoCompressed == nil) return;
                            compressedTotalSize += compressedSize;
                            [self saveVideoAtFileURL:outputURL savedBlock:^(NSInteger sucessCount) {
                                if (sucessCount) {
                                    compressOKCount ++;
                                    @synchronized (self.videoCompressed) {
                                        [self.videoCompressed addObject:videoKey];
                                    }
                                }
                                compressCount ++;
                                dispatch_semaphore_signal(sema);
                            }];
                        }];
                    });
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
//                    progress = (float)compressCount/(float)self.videoCount;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressBlock) progressBlock(compressCount, compressedTotalSize);
                    });
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSFileManager defaultManager] removeItemAtPath:videoField error:NULL];
                if (completeBlock) completeBlock(compressOKCount, compressedTotalSize);
            });
        }
    });
}

- (void)cv_removeOriginVideo:(PhotoResultsBlock)delBlock {
    if (self.videoCount>0 && self.videoCompressed) {
        NSString *compressField = [TTDocumentsFolderPath stringByAppendingPathComponent:@"VideoCompressDir"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:compressField]) {
            [[NSFileManager defaultManager] removeItemAtPath:compressField error:NULL];
        }
        NSArray *deleArray = [NSArray arrayWithArray:self.videoCompressed];
        [self removeVideoFromAlbumWithVideoKeys:deleArray delectedBlock:^(NSInteger sucessCount) {
            if (sucessCount>0) {
                self.videoCount = 0;
                self.videoTotalSize = 0;
                self.videoClearSize = 0;
                self.videoDateKeys = nil;
                self.videoSectionDic = nil;
                self.videoCompressed = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (delBlock) delBlock(sucessCount);
            });
        }];
    }
}

- (void)cv_cancelCompressVideo:(PhotoResultsBlock)delBlock {
    if (self.videoCount>0 && self.videoCompressed) {
        @synchronized (self.videoCompressed) {
            if (self.videoCompressed.count>0) {
                [self cv_removeOriginVideo:delBlock];
            } else {
                if (delBlock) delBlock(0);
            }
            self.videoCompressed = nil;
        }
    } else {
        if (delBlock) delBlock(0);
    }
}

@end
