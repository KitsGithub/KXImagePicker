//
//  DNImagePickerController.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DNImagePickerHeader.h"


typedef void(^getFistImageBlock)(UIImage *image);
@class ALAssetsFilter;
FOUNDATION_EXTERN NSString *kDNImagePickerStoredGroupKey;


UIKIT_EXTERN ALAssetsFilter * ALAssetsFilterFromDNImagePickerControllerFilterType(DNImagePickerFilterType type);

@class DNImagePickerController;
@protocol DNImagePickerControllerDelegate <NSObject>
@optional
/**
 *  imagePickerController‘s seleted photos
 *
 *  @param imagePickerController
 *  @param imageAssets           the seleted photos packaged DNAsset type instances
 *  @param fullImage             if the value is yes, the seleted photos is full image
 */
- (void)dnImagePickerController:(DNImagePickerController *)imagePicker
                     sendImages:(NSArray *)imageAssets
                    isFullImage:(BOOL)fullImage;


/**
 获取视频的代理方法

 @param imagePicker imagePicker
 @param videoImage  视频数据流
 */
- (void)dnImagePickerController:(DNImagePickerController *)imagePicker
                      sendVideo:(NSString *)videoLoaclURLStr;

- (void)dnImagePickerControllerDidCancel:(DNImagePickerController *)imagePicker;
@end


@interface DNImagePickerController : UINavigationController
@property (nonatomic, assign) int kDNImageFlowMaxSeletedNumber;     //选择图片最多的张数
@property (nonatomic, assign) CGFloat enableEditSeconds;            //视频选择可剪裁时长(默认为最大时长)
@property (nonatomic, assign) DNImagePickerFilterType filterType;
@property (nonatomic, weak) id<DNImagePickerControllerDelegate> imagePickerDelegate;

/**
 获取相册最新的一张图片
 @param collectionName 相册名称,如果不传则默认最近添加
 */
+ (void)getLatestImageWihtCollecionName:(NSString *)collectionName complainedBlock:(getFistImageBlock)returnBlock;

@end
