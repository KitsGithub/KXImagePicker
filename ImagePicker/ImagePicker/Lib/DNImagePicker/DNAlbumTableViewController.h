//
//  DNAlbumTableViewController.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "DNImagePickerHeader.h"

@interface DNAlbumTableViewController : UITableViewController

@property (nonatomic, assign) DNImagePickerFilterType filterType;

@property (nonatomic, assign) CGFloat enableEditSeconds;            //视频选择可剪裁时长(默认为最大时长)


@property (nonatomic, assign) int kDNImageFlowMaxSeletedNumber;


@end
