//
//  DNPhotoBrowserViewController.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/28.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@class DNImageFlowViewController;
@class DNPhotoBrowser;
@protocol DNPhotoBrowserDelegate <NSObject>

@required
- (void)sendImagesFromPhotobrowser:(DNPhotoBrowser *)photoBrowse currentAsset:(PHAsset *)asset;
- (NSUInteger)seletedPhotosNumberInPhotoBrowser:(DNPhotoBrowser *)photoBrowser;
- (BOOL)photoBrowser:(DNPhotoBrowser *)photoBrowser currentPhotoAssetIsSeleted:(PHAsset *)asset;
- (BOOL)photoBrowser:(DNPhotoBrowser *)photoBrowser seletedAsset:(PHAsset *)asset;
- (void)photoBrowser:(DNPhotoBrowser *)photoBrowser deseletedAsset:(PHAsset *)asset;
- (void)photoBrowser:(DNPhotoBrowser *)photoBrowser seleteFullImage:(BOOL)fullImage;
@end

@interface DNPhotoBrowser : UIViewController

@property (nonatomic, weak) id<DNPhotoBrowserDelegate> delegate;

- (instancetype)initWithPhotos:(NSArray *)photosArray
                  currentIndex:(NSInteger)index
                     fullImage:(BOOL)isFullImage;


- (instancetype)initWithPHPhotosArray:(NSMutableArray<PHAsset *> *)photosArray
                    currentIndex:(NSInteger)index
                       fullImage:(BOOL)isFullImage;

- (void)hideControls;
- (void)toggleControls;
@end
