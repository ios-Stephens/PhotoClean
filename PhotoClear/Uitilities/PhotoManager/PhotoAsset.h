//
//  PhotoAsset.h
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_OPTIONS(NSUInteger, PhotoAssetMediaSubtype) {
    PhotoAssetMediaSubtypeNone               = 0,
    PhotoAssetMediaSubtypeImage              = 1,
    PhotoAssetMediaSubtypeVideo              = 2,
    PhotoAssetMediaSubtypeAudio              = 3,
};

typedef NS_OPTIONS(NSUInteger, AVAssetExportPresetType) {
    AVAssetExportPresetTypeNone                      = 0,
    AVAssetExportPresetTypeLowQuality                = 1,
    AVAssetExportPresetTypeMediumQuality             = 2,
    AVAssetExportPresetType640x480                   = 3,
    AVAssetExportPresetType960x540                   = 4,
    AVAssetExportPresetType1280x720                  = 5,
    AVAssetExportPresetType1920x1080                 = 6,
    AVAssetExportPresetType3840x2160                 = 7,
    AVAssetExportPresetTypeHighestQuality            = 8,
};

@interface PhotoAsset<__covariant ObjectType> : NSObject

@property (nonatomic, strong) __kindof ObjectType asset;

@property (nonatomic, assign) NSUInteger bytesize;

@property (nonatomic, assign) CGSize pixelSize;

@property (nonatomic, assign, readonly) PhotoAssetMediaSubtype mediaSubtypes;

@property (nonatomic, assign, readonly) BOOL isGif;

//@property (nonatomic, retain) id imageKey;//imageIndex|url

@property (nonatomic, strong, readonly) UIImage *thumbImage;


//@property(nonatomic,copy,readonly) NSString *localIdentifier;

- (instancetype)initWithAsset:(ObjectType)asset;
- (instancetype)initWithAsset:(id)asset subType:(PhotoAssetMediaSubtype)subType;

//only for photo
- (void)requestImage:(void(^)(UIImage *result))resultHandler;

- (BOOL)ableToCompress;
- (void)requestEstimatedCompressImage:(void (^)(NSUInteger estimatedCompress))resultHandler;
//- (void)requestCompressImage:(void(^)(UIImage *result, NSUInteger compressSize))resultHandler;
- (void)requestCompressImage:(NSString *)outputPath resultHandler:(void(^)(NSURL *outputURL, NSUInteger compressedSize))resultHandler;

// only for video
@property (nonatomic, assign) CGSize naturalSize;
@property (nonatomic, strong, readonly) NSArray *exportPresets;

- (void)requestAVAsset:(void (^)(AVAsset *))resultHandler;
- (void)requestAVAssetExportSession:(void (^)(AVAssetExportSession *exportSession, AVAssetExportPresetType exportPreset, NSUInteger estimatedCompress))resultHandler;
- (void)requestCompressVideo:(NSString *)outputPath resultHandler:(void(^)(NSURL *outputURL, NSUInteger compressedSize))resultHandler;

@end
