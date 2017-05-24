//
//  PhotoAsset.m


#import "PhotoAsset.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation PhotoAsset

- (instancetype)initWithAsset:(id)asset {
    if (self=[super init]) {
        self.asset = asset;
        _isGif = NO;
    }
    return self;
}

- (instancetype)initWithAsset:(id)asset subType:(PhotoAssetMediaSubtype)subType {
    self = [self initWithAsset:asset];
    if (self) {
        _mediaSubtypes = subType;
        self.naturalSize = CGSizeZero;
    }
    return self;
}

- (void)dealloc {
    self.asset = nil;
}

-(UIImage*) thumbImage{
    if ([self.asset isKindOfClass:[PHAsset class]]) {
        __block UIImage *img=nil;
        PHAsset *phAsset = self.asset;
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        // 同步获得图片, 只会返回1张图片
        options.synchronous = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        //CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight)
        CGSize size =  CGSizeMake(50*[UIScreen mainScreen].scale,50*[UIScreen mainScreen].scale);
        //CGSize size =  CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight);
        // 从asset中获得图片
        //PHImageManager
        [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                img = result;
            }
        }];
        
        return img;
    } else if ([self.asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = self.asset;
        CGImageRef imgRef= [alAsset thumbnail];
        return  [UIImage imageWithCGImage:imgRef];
    }
    return nil;
    
}


- (NSUInteger)bytesize {
    if (_bytesize>0.0) {
        return _bytesize;
    }
    NSUInteger dataSize = 0.0;
    if (self.mediaSubtypes == PhotoAssetMediaSubtypeVideo && TT_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        PHAsset *phAsset = self.asset;
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
        __block NSUInteger imageSize = 0.0;
        [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            if (asset) {
                NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                if (tracks.count>0) {
                    AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
                    self.naturalSize = videoTrack.naturalSize;
                }
                self.exportPresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
                AVAssetExportPresetType originPresetType = [self originPresetType];
                NSString *exportPreset = [self presetWithPresetType:originPresetType];
                AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:exportPreset];
                exportSession.outputFileType = AVFileTypeMPEG4;
//                CMTime full = CMTimeMultiplyByFloat64(asset.duration, 1);
                exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, [asset duration]);
//                exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, full);
                imageSize = (NSUInteger)exportSession.estimatedOutputFileLength;
                dispatch_semaphore_signal(sema);
            }
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dataSize = imageSize;
    } else if ([self.asset isKindOfClass:[PHAsset class]]) {
        @autoreleasepool {
            PHAsset *phAsset = self.asset;
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = YES;
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeNone;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.version = PHImageRequestOptionsVersionOriginal;
            
            __block NSUInteger imageSize = 0.0;
            PHImageRequestID requestId = [[PHCachingImageManager defaultManager] requestImageDataForAsset:phAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                imageSize = imageData.length;
                imageData = nil;
                if ([dataUTI rangeOfString:@"gif"].location != NSNotFound) {
                    _isGif = YES;
                }
            }];
            [[PHCachingImageManager defaultManager] cancelImageRequest:requestId];
            
            dataSize = imageSize;
        }
    } else if ([self.asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = self.asset;
        ALAssetRepresentation* representation = [alAsset defaultRepresentation];
        dataSize = (NSUInteger)representation.size;
        NSString *assetURL = [alAsset valueForProperty:ALAssetPropertyAssetURL];
        if ([assetURL rangeOfString:@"gif"].location != NSNotFound) {
            _isGif = YES;
        }
        TTDEBUGLOG(@"photo url:%@",assetURL);
    }
    _bytesize = dataSize;
    return _bytesize;
}

- (CGSize)pixelSize {
    if ([self.asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = self.asset;
        _pixelSize = CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight);
        return _pixelSize;
    } else if ([self.asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = self.asset;
        ALAssetRepresentation* representation = [alAsset defaultRepresentation];
        _pixelSize = representation.dimensions;
        return _pixelSize;
    }
    return CGSizeZero;
}

#pragma mark - Photo


- (void)requestImage:(void (^)(UIImage *__nullable result))resultHandler {
    
    if ([self.asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = self.asset;
        __block UIImage *img=nil;
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        // 同步获得图片, 只会返回1张图片
        options.synchronous = NO;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        //CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight)
        
        //        CGSize size =  CGSizeMake(100*[UIScreen mainScreen].scale,100*[UIScreen mainScreen].scale);
        CGSize size =  CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight);
        // 从asset中获得图片
        [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                img = result;
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultHandler(img);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultHandler(nil);
                });
            }
        }];
    } else if ([self.asset isKindOfClass:[ALAsset class]]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (!self.asset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultHandler(nil);
                });
            }
            UIImage *img=nil;
            
            ALAsset *alAsset = self.asset;
            ALAssetRepresentation* representation = [alAsset defaultRepresentation];
            //获取资源图片的长宽
            //CGSize dimension = [representation dimensions];
            //获取资源图片的高清图
            CGImageRef imgRef =[representation fullResolutionImage];
            //获取资源图片的全屏图
            //CGImageRef imgRef = [representation fullScreenImage];
            img = [UIImage imageWithCGImage:imgRef scale:representation.scale orientation:(UIImageOrientation)representation.orientation];
            imgRef = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                resultHandler(img);
            });
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            resultHandler(nil);
        });
    }
}

- (BOOL)ableToCompress {
    NSUInteger size = [self bytesize];
    
    if (size>1024*1024) {
        CGSize pixelSize = [self pixelSize];
        CGSize screenSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * [[UIScreen mainScreen] scale], [[UIScreen mainScreen] bounds].size.height * [[UIScreen mainScreen] scale]);
        // 高分辨率图片且小于1.5MB不压缩
        if (pixelSize.width>screenSize.width && pixelSize.height>screenSize.height && size<1024*1024*1.5) {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (CGFloat)estimatedCompressQuality:(NSUInteger)size {
    CGFloat quality = 0.5;
    if (size>1024*1024*5) {
        quality = 0.1;
    } else if (size>1024*1024*3) {
        quality = 0.3;
    } else if (size>1024*1024*2) {
        quality = 0.4;
    } else {
        quality = 0.5;
    }
    return quality;
}

- (void)requestEstimatedCompressImage:(void (^)(NSUInteger estimatedCompress))resultHandler {
//    CGSize pixelSize = [self pixelSize];
//    CGSize screenSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * [[UIScreen mainScreen] scale], [[UIScreen mainScreen] bounds].size.height * [[UIScreen mainScreen] scale]);
    
    NSUInteger size = [self bytesize];
//    if (pixelSize.width>screenSize.width && pixelSize.height>screenSize.height) {
        // 高分辨率图片且小于2MB可能无法压缩，不能预估(大于2MB的图片评估为可压缩)
//        __block NSUInteger estimatedCompressed = 0;
//        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
//        [self requestImage:^(UIImage *result) {
//            if (result) {
//                NSData *imageData = UIImageJPEGRepresentation(result, 0);
//                NSUInteger byteSize = imageData.length;
//                NSUInteger maxCompressedSize = size-byteSize;
//                // 最大压缩量大于100KB时判定为可压缩
//                if (maxCompressedSize>1024*100) {
//                    estimatedCompressed = ((float)size)*0.4;
//                }
//                dispatch_semaphore_signal(sema);
//            } else {
//                dispatch_semaphore_signal(sema);
//            }
//        }];
//        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
//        resultHandler(estimatedCompressed);
//    } else {
    NSUInteger estimatedCompressed = 0;
    CGFloat quality = 0.4;
    if (size>1024*1024*5) {
        quality = 0.2;
    } else if (size>1024*1024*3) {
        quality = 0.3;
    }
    estimatedCompressed = ((float)size)*quality;
    resultHandler(estimatedCompressed);
//    }
}

- (void)requestCompressImage:(NSString *)outputPath resultHandler:(void(^)(NSURL *outputURL, NSUInteger compressedSize))resultHandler {
    @autoreleasepool {
        [self requestImage:^(UIImage *result) {
            if (result) {
                UIImage *originImage = result;
                NSUInteger size = [self bytesize];
                NSUInteger byteSize = size;
                
                CGSize pixelSize = [self pixelSize];
                CGSize screenSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * [[UIScreen mainScreen] scale], [[UIScreen mainScreen] bounds].size.height * [[UIScreen mainScreen] scale]);
                
                NSData *originData = nil;
                if (pixelSize.width>screenSize.width && pixelSize.height>screenSize.height) {
                    // 高分辨率图片可能压缩
                    CGFloat newWidth = screenSize.width;
                    CGFloat newHeight = screenSize.height;
                    if (pixelSize.width/pixelSize.height > screenSize.width/screenSize.height) {
                        newWidth = pixelSize.width * (screenSize.height/pixelSize.height);
                    } else {
                        newHeight = pixelSize.height * (screenSize.width/pixelSize.width);
                    }
                    CGSize newSize = CGSizeMake(newWidth, newHeight);
                    originImage = [self imageWithImage:result scaledToSize:newSize];
                    originData = UIImageJPEGRepresentation(originImage, 1.0);
                    byteSize = originData.length;
                }
                
                CGFloat quality = [self estimatedCompressQuality:byteSize];
                NSData *imageData = originData;
                while (quality>=0 && byteSize>1024*800) {
                    imageData = UIImageJPEGRepresentation(originImage, quality);
                    byteSize = imageData.length;
                    //                double com = (float)byteSize/(float)size;
                    //                TTDEBUGLOG(@"compress progress:%.3f", com);
                    quality -= 0.1;
                }
                NSString *timeString = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
                NSString *resultPath = [outputPath stringByAppendingPathComponent:[NSString stringWithFormat:@"outputPhoto-%@.jpg", timeString]];
                NSURL *outputURL = [NSURL fileURLWithPath:resultPath];
                [imageData writeToURL:outputURL atomically:YES];
                //            UIImage *image = [UIImage imageWithData:imageData];
                NSUInteger compressedSize = size-byteSize;
                
                resultHandler(outputURL, compressedSize);
            } else {
                resultHandler(nil, 0);
            }
        }];
    }
}

//图片压缩到指定大小
- (UIImage *)imageWithImage:(UIImage*)image
               scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Video

- (void)setExportPresets:(NSArray *)exportPresets {
    if (exportPresets) {
        _exportPresets = [NSArray arrayWithArray:exportPresets];
    }
}

/*
 AVAssetExportPresetHighestQuality,
 AVAssetExportPreset3840x2160,
 AVAssetExportPreset1920x1080,
 AVAssetExportPreset1280x720,
 AVAssetExportPreset960x540，
 AVAssetExportPreset640x480,
 AVAssetExportPresetMediumQuality,
 AVAssetExportPresetLowQuality,
 AVAssetExportPresetPassthrough,
 */
- (NSString *)presetWithPresetType:(AVAssetExportPresetType)exportPresetType {
    NSString *presetName = AVAssetExportPresetPassthrough;
    switch (exportPresetType) {
        case AVAssetExportPresetTypeHighestQuality:
            presetName = AVAssetExportPresetLowQuality;
            break;
        case AVAssetExportPresetType3840x2160:
            presetName = AVAssetExportPreset3840x2160;
            break;
        case AVAssetExportPresetType1920x1080:
            presetName = AVAssetExportPreset1920x1080;
            break;
        case AVAssetExportPresetType1280x720:
            presetName = AVAssetExportPreset1280x720;
            break;
        case AVAssetExportPresetType960x540:
            presetName = AVAssetExportPreset960x540;
            break;
        case AVAssetExportPresetType640x480:
            presetName = AVAssetExportPreset640x480;
            break;
        case AVAssetExportPresetTypeMediumQuality:
            presetName = AVAssetExportPresetMediumQuality;
            break;
        case AVAssetExportPresetTypeLowQuality:
            presetName = AVAssetExportPresetLowQuality;
            break;
        default:
            break;
    }
    return presetName;
}

- (AVAssetExportPresetType)originPresetType {
    if (CGSizeEqualToSize(self.naturalSize, CGSizeZero)) {
        return AVAssetExportPresetTypeNone;
    }
    AVAssetExportPresetType exportPresetType = AVAssetExportPresetType1280x720;
    if (self.naturalSize.width>2160 && self.naturalSize.height>2160) {
        exportPresetType = AVAssetExportPresetTypeHighestQuality;
    } else if (self.naturalSize.width>1080 && self.naturalSize.height>1080) {
        exportPresetType = AVAssetExportPresetType3840x2160;
    } else if (self.naturalSize.width>720 && self.naturalSize.height>720) {
        exportPresetType = AVAssetExportPresetType1920x1080;
    } else if (self.naturalSize.width>540 && self.naturalSize.height>540) {
        exportPresetType = AVAssetExportPresetType1280x720;
    } else if (self.naturalSize.width>480 && self.naturalSize.height>480) {
        exportPresetType = AVAssetExportPresetType960x540;
    } else if (self.naturalSize.width>320 && self.naturalSize.height>320) {
        exportPresetType = AVAssetExportPresetType640x480;
    } else if (self.naturalSize.width>128 && self.naturalSize.height>128) {
        exportPresetType = AVAssetExportPresetTypeMediumQuality;
    } else {
        exportPresetType = AVAssetExportPresetTypeLowQuality;
    }
    return exportPresetType;
}

- (AVAssetExportPresetType)recommendedExportPreset {
    AVAssetExportPresetType originPresetType = [self originPresetType];
    
    AVAssetExportPresetType exportPresetType = AVAssetExportPresetType960x540;
    NSString *exportPreset = [self presetWithPresetType:exportPresetType];
    while (exportPresetType>=originPresetType || ![self.exportPresets containsObject:exportPreset]) {
        exportPresetType -= 1;
        if (exportPresetType<=AVAssetExportPresetTypeNone) {
            exportPresetType = AVAssetExportPresetTypeLowQuality;
            break;
        }
        exportPreset = [self presetWithPresetType:exportPresetType];
    }
    return exportPresetType;
}


- (BOOL)isAbleCompressToPreset:(AVAssetExportPresetType)exportPresetType {
    AVAssetExportPresetType originPresetType = [self originPresetType];
    if (exportPresetType<=originPresetType) {
        return YES;
    }
    return NO;
}

- (void)requestAVAsset:(void (^)(AVAsset *))resultHandler {
    if ([self.asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = self.asset;
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        // 同步获得图片, 只会返回1张图片
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            if (asset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultHandler(asset);
                });
            }
        }];
    } else {
        
    }
}

- (void)requestAVAssetExportSession:(void (^)(AVAssetExportSession *exportSession, AVAssetExportPresetType exportPreset, NSUInteger estimatedCompress))resultHandler {
    if ([self.asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = self.asset;
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        
        NSUInteger size = [self bytesize];
        @autoreleasepool {
            [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                if (asset) {
                    AVAssetExportPresetType recommendedPresetType = [self recommendedExportPreset];
                    NSString *exportPreset = [self presetWithPresetType:recommendedPresetType];
                    
                    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:exportPreset];
                    exportSession.outputFileType = AVFileTypeMPEG4;
                    CMTime full = CMTimeMultiplyByFloat64(asset.duration, 1);
                    exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, full);
                    NSUInteger estimatedCompressed = size - (NSUInteger)exportSession.estimatedOutputFileLength;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //                    TTDEBUGLOG(@"exportSession.presetName:%@, exportPresets:%@, videoSize:%@, estimatedOutputFileLength:%lld", exportSession.presetName, self.exportPresets, NSStringFromCGSize(self.naturalSize), exportSession.estimatedOutputFileLength);
                        resultHandler(exportSession, recommendedPresetType, estimatedCompressed);
                    });
                }
            }];
        }
    } else {
        
    }
}

- (void)requestCompressVideo:(NSString *)outputPath resultHandler:(void(^)(NSURL *outputURL, NSUInteger compressedSize))resultHandler {
    if ([self.asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = self.asset;
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
        NSUInteger size = [self bytesize];
        AVAssetExportPresetType recommendedPresetType = [self recommendedExportPreset];
        NSString *exportPreset = [self presetWithPresetType:recommendedPresetType];
        
        [[PHImageManager defaultManager] requestExportSessionForVideo:phAsset options:options exportPreset:exportPreset resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
            if (exportSession) {
                NSString *timeString = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
                
                NSString *resultPath = [outputPath stringByAppendingPathComponent:[NSString stringWithFormat:@"outputJFVideo-%@.mp4", timeString]];
                NSURL *outputURL = [NSURL fileURLWithPath:resultPath];
                exportSession.outputURL = outputURL;
                exportSession.outputFileType = AVFileTypeMPEG4;
                exportSession.shouldOptimizeForNetworkUse = YES;
                [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
                    NSData *videoData = [NSData dataWithContentsOfURL:outputURL];
                    NSUInteger compressed = size - videoData.length;
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        TTDEBUGLOG(@"exportSession.presetName:%@, compressed:%lu", exportSession.presetName, (unsigned long)compressed);
                        resultHandler(outputURL, compressed);
                    });
                }];
            }
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            resultHandler(nil, 0);
        });
    }
}

@end
