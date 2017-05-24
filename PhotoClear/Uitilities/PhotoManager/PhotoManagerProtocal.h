//
//  PhotoManagerProtocal.h


#import <Foundation/Foundation.h>
@class PhotoAsset;

typedef void (^PhotoResultsBlock)(NSInteger sucessCount);
typedef void (^PhotoProgressBlock)(NSInteger sucessCount);

@protocol PhotoManagerProtocol <NSObject>


- (void)removeImageFromAlbumWithImageKeys:(NSArray *)indexs delectedBlock:(PhotoResultsBlock)delBlock;
- (void)removeImageFromAlbum:(NSArray<PhotoAsset *> *)assets delectedBlock:(PhotoResultsBlock)delBlock;

- (void)removeVideoFromAlbumWithVideoKeys:(NSArray *)indexs delectedBlock:(PhotoResultsBlock)delBlock;

- (void)saveImageAtFileURL:(NSURL *)fileURL savedBlock:(PhotoResultsBlock)block;
- (void)saveImage:(UIImage *)image savedBlock:(PhotoResultsBlock)block;
- (void)saveVideoAtFileURL:(NSURL *)fileURL savedBlock:(PhotoResultsBlock)block;
- (void)saveImageData:(NSData *)data savedBlock:(PhotoResultsBlock)block;

@end

@protocol PhotoManagerPrivateProtocol <NSObject>

@optional
- (void)fetchProgress:(NSUInteger)number;
- (void)fetchComplete;
@property (nonatomic, assign) float spProgress;
@property (nonatomic, assign) float ssProgress;
@property (nonatomic, assign) float cpProgress;
@property (nonatomic, assign) float cvProgress;

@end

// 相似照片
@protocol PhotoManagerSimilarProtocol <NSObject>

- (NSUInteger)sp_totalNumber;
// 预估节省空间（use "Utility transformSpaceSize:" to transform value to string）
- (NSUInteger)sp_estimatedClearSize;

// 按 相似程度&日期 分组
- (NSUInteger)sp_numberOfSections;
- (NSUInteger)sp_itemsAtSection:(NSUInteger)section;

// 日期
- (NSString *)sp_titleForSection:(NSUInteger)section;
// 缩略图
- (UIImage *)sp_imageAtIndexPath:(NSIndexPath *)indexPath;

- (void)sp_removeSimilarImageWithIndexPaths:(NSArray <NSIndexPath *> *)indexs delectedBlock:(PhotoResultsBlock)delBlock;

//
- (PhotoAsset *)sp_assetAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray<PhotoAsset *> *)sp_assetsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;


@end

// 屏幕快照
@protocol PhotoManagerScreenshotProtocol <NSObject>

// 总张数
- (NSUInteger)ss_totalNumber;
// 预估节省空间（use "Utility transformSpaceSize:" to transform value to string）
- (NSUInteger)ss_estimatedClearSize;

// 按日期倒序分组
- (NSUInteger)ss_numberOfSections;
- (NSUInteger)ss_itemsAtSection:(NSUInteger)section;

// 日期
- (NSString *)ss_titleForSection:(NSUInteger)section;
// 缩略图
- (UIImage *)ss_imageAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)ss_byteSizeOfPhotoAtIndexPath:(NSIndexPath *)indexPath;

- (void)ss_removeScreenImageWithIndexPaths:(NSArray <NSIndexPath *> *)indexs delectedBlock:(PhotoResultsBlock)delBlock;

@end

// 照片瘦身
@protocol PhotoManagerCompressPhotoProtocol <NSObject>

- (NSUInteger)cp_totalNumber;
// 预估节省空间（use "Utility transformSpaceSize:" to transform value to string）
- (NSUInteger)cp_estimatedCompressSize;
- (NSTimeInterval)cp_estimatedTimeInterval;

// 按日期倒序分组
- (NSUInteger)cp_numberOfSections;
- (NSUInteger)cp_itemsAtSection:(NSUInteger)section;

- (PhotoAsset *)cp_assetAtIndexPath:(NSIndexPath *)indexPath;

// the handle is on global_queue (asynchronous), and completeBlock\delBlock will called on main_queue
- (void)cp_startCompressPhotoBlock:(void(^)(NSUInteger count, NSUInteger compressedSize))progressBlock complete:(void(^)(NSUInteger count, NSUInteger compressedSize))completeBlock;
- (void)cp_removeOriginPhoto:(PhotoResultsBlock)delBlock;
- (void)cp_cancelCompressPhoto:(PhotoResultsBlock)delBlock;

@end

// 视频瘦身
@protocol PhotoManagerCompressVideoProtocol <NSObject>

- (NSUInteger)cv_numberOfVideo;
// 预估节省空间（use "Utility transformSpaceSize:" to transform value to string）
- (NSUInteger)cv_estimatedCompressSize;

// the handle is on global_queue (asynchronous), and progressBlock\completeBlock\delBlock will called on main_queue
- (void)cv_startCompressVideoBlock:(void(^)(NSUInteger count, NSUInteger compressedSize))progressBlock complete:(void(^)(NSUInteger count, NSUInteger compressedSize))completeBlock;
- (void)cv_removeOriginVideo:(PhotoResultsBlock)delBlock;
- (void)cv_cancelCompressVideo:(PhotoResultsBlock)delBlock;

@end

