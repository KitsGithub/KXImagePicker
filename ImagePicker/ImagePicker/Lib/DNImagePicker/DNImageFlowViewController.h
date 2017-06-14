//
//  DNImageFlowViewController.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/11.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DNImagePickerHeader.h"
#import <Photos/Photos.h>

@interface DNImageFlowViewController : UIViewController

@property (nonatomic, assign) DNImagePickerFilterType filterType;

@property (nonatomic, assign) int kDNImageFlowMaxSeletedNumber;

@property (nonatomic, assign) CGFloat enableEditSeconds;            //视频选择可剪裁时长(默认为最大时长)

//初始化方法
- (instancetype)initWithPHFetchResult:(PHFetchResult *)result;


@end
