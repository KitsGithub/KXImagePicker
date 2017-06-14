# KXImagePicker
base to DNImagePicer <br/>
大家多多交流，多多指教，遇到问题可以联系我QQ: 381377046 ，备注KXImagePicker 我会尽快优化<br/>

## DEMO
![image](https://github.com/KitsGithub/KXImagePicker/blob/master/Screenshots/ImagePickerScreenShot.gif)

基于DNImagePicker所做的封装,关于DNImagePicker可以查看源码：https://github.com/AwesomeDennis/DNImagePicker<br/>

由于DNImagePicker 使用的是AssetsLibrary.framework，其在API已经不更新了，苹果推出了新的Photos.framework 因此，在此项目中把DNImagePicker中的AssetsLibrary框架 完全替换成Photos的框架<br/>

同样的，在其基础上新增了类似于微信的视频编辑界面和缩略图预览

### Key Property

根据传进来的```fillterType```判断用户要打开什么类型的相册,其枚举类值与系统的类似
```objc
typedef NS_ENUM(NSUInteger, DNImagePickerFilterType) {
DNImagePickerFilterTypeNone = 0,
DNImagePickerFilterTypePhotos,
DNImagePickerFilterTypeVideos,
DNImagePickerFilterTypeAudio
};

@property (nonatomic, assign) DNImagePickerFilterType filterType;
```

如果选择的```filterType```是```DNImagePickerFilterTypeVideos``` 这个枚举值
```objc
@property (nonatomic, assign) CGFloat enableEditSeconds;            //视频选择可剪裁时长(默认为最大时长)
```
则可以通过这个值来获取裁剪视频的时间范围<br/>
若```fillterType```值为```DNImagePickerFilterTypePhotos``` 这个枚举值
```objc
@property (nonatomic, assign) int kDNImageFlowMaxSeletedNumber;     //选择图片最多的张数
```
可以通过这个属性来控制每次选择的图片数<br/>

很多业务上，在最外面打开相册的按钮都会去显示最新添加的图片，因而我提供了一个新的接口来获取相册最后一张的图片
```objc
typedef void(^getFistImageBlock)(UIImage *image);

/**
获取相册最新的一张图片
@param collectionName 相册名称,如果不传则默认最近添加
*/
+ (void)getLatestImageWihtCollecionName:(NSString *)collectionName complainedBlock:(getFistImageBlock)returnBlock;
```


### DNImagePickerControllerDelegate
代理方法如下
```objc
/**
选择了照片之后回调

@param imagePicker picker
@param imageAssets 图片元数据数组
*/
- (void)dnImagePickerController:(DNImagePickerController *)imagePicker sendImages:(NSArray<PHAsset *> *)imageAssets isFullImage:(BOOL)fullImage;
```

```objc
/**
视频编辑完后的回调

@param imagePicker picker
@param videoLoaclURLStr 视频编辑完保存的本地路径
*/
- (void)dnImagePickerController:(DNImagePickerController *)imagePicker
sendVideo:(NSString *)videoLoaclURLStr;
```

```objc
/**
取消的点击

@param imagePicker picker
*/
- (void)dnImagePickerControllerDidCancel:(DNImagePickerController *)imagePicker;
```














