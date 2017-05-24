//
//  PhotoFetchManager.h


#import <Foundation/Foundation.h>
#import "PhotoManagerProtocal.h"
#import "PhotoAsset.h"

typedef void (^AlbumAuthorizationResultsBlock)(BOOL isAuthorization);

typedef void (^PhotoLoadCompleteBlock)();
// check progress
typedef void (^PhotoCheckProgress)(float progress);
//整体检测进度
typedef void (^PhotoTotalFetchProgress)(float progress, NSUInteger fetchNumber, NSUInteger totalNumber);


FOUNDATION_EXTERN NSString * const PhotoLibraryDidChangeNotification; //相册

@interface PhotoFetchManager : NSObject <PhotoManagerProtocol, PhotoManagerSimilarProtocol, PhotoManagerScreenshotProtocol, PhotoManagerCompressPhotoProtocol, PhotoManagerCompressVideoProtocol>


+ (instancetype)shareInstance;

//获取相册权限
- (void)albumAuthorization:(AlbumAuthorizationResultsBlock)authorizationBlock;


@property (nonatomic, assign, readonly) BOOL isProcessing;

@property (nonatomic, assign, readonly) NSUInteger totalNumber;

@property (nonatomic, assign, readonly) BOOL needReload;//是否需要重新加载

@property (nonatomic, copy) PhotoTotalFetchProgress totalProgressBlock;

@property (nonatomic, copy) PhotoCheckProgress spProgressBlock;
@property (nonatomic, copy) PhotoCheckProgress ssProgressBlock;
@property (nonatomic, copy) PhotoCheckProgress cpProgressBlock;
@property (nonatomic, copy) PhotoCheckProgress cvProgressBlock;


- (void)checkPhoto:(PhotoLoadCompleteBlock)complete;

- (void)startManager;
- (void)stopManager;



@end
