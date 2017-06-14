//
//  DNImagePickerHeader.h
//  ZhiMaBaoBao
//
//  Created by mac on 2017/5/31.
//  Copyright © 2017年 liugang. All rights reserved.
//

#ifndef DNImagePickerHeader_h
#define DNImagePickerHeader_h

typedef NS_ENUM(NSUInteger, DNImagePickerFilterType) {
    DNImagePickerFilterTypeNone = 0,
    DNImagePickerFilterTypePhotos,
    DNImagePickerFilterTypeVideos,
    DNImagePickerFilterTypeAudio
};

#define isIOS8 [[UIDevice currentDevice].systemVersion doubleValue]>=8.0?YES:NO
#define VideoMaxTimeInterval 180        //允许视频最大秒数

#endif /* DNImagePickerHeader_h */
