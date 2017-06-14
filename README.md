# KXImagePicker
base to DNImagePicer
基于DNImagePicker所做的封装,关于DNImagePicker可以查看源码：https://github.com/AwesomeDennis/DNImagePicker<br/>
由于DNImagePicker 使用的是AssetsLibrary.framework，其在API已经不更新了，苹果推出了新的Photos.framework 因此，在此项目中把DNImagePicker中的AssetsLibrary框架 完全替换成Photos的框架<br/>

同样的，在其基础上新增了类似于微信的视频编辑界面和缩略图预览

### Key Property
```objc
@property (nonatomic, assign) int kDNImageFlowMaxSeletedNumber;     //选择图片最多的张数
```

根据传进来的fillterType判断用户要打开什么类型的相册
```objc
@property (nonatomic, assign) DNImagePickerFilterType filterType;
```
其值与系统的type类似
```objc
typedef NS_ENUM(NSUInteger, DNImagePickerFilterType) {
DNImagePickerFilterTypeNone = 0,
DNImagePickerFilterTypePhotos,
DNImagePickerFilterTypeVideos,
DNImagePickerFilterTypeAudio
};
```

如果选择的是 ```objc DNImagePickerFilterTypeVideos``` 这个属性的话
```objc
@property (nonatomic, assign) CGFloat enableEditSeconds;            //视频选择可剪裁时长(默认为最大时长)
```
则可以通过这个值来获取裁剪视频的时间范围

