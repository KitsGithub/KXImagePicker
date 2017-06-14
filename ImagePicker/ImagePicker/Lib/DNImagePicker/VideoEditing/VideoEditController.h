//
//  VideoEditController.h
//  ZhiMaBaoBao
//
//  Created by liugang on 2017/6/2.
//  Copyright © 2017年 liugang. All rights reserved.
//

#import "BaseViewController.h"

@interface VideoEditController : BaseViewController

@property (nonatomic, strong) NSURL *path;
@property (nonatomic, assign) CGFloat enableEditSeconds;     //可剪裁时长(默认为最大时长)

@end
