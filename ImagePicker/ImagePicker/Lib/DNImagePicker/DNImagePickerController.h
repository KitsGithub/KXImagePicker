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
@class PHAsset;

@class DNImagePickerController;
@protocol DNImagePickerControllerDelegate <NSObject>
@optional


/**
 选择了照片之后回调

 @param imagePicker picker
 @param imageAssets 图片元数据数组
 */
- (void)dnImagePickerController:(DNImagePickerController *)imagePicker
                     sendImages:(NSArray<PHAsset *> *)imageAssets
                    isFullImage:(BOOL)fullImage;


/**
 视频编辑完后的回调

 @param imagePicker picker
 @param videoLoaclURLStr 视频编辑完保存的本地路径
 */
- (void)dnImagePickerController:(DNImagePickerController *)imagePicker
                      sendVideo:(NSString *)videoLoaclURLStr;


/**
 取消的点击

 @param imagePicker picker
 */
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
