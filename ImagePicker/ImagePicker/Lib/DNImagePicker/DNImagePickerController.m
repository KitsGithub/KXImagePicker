//
//  DNImagePickerController.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "DNImagePickerController.h"
#import "DNAlbumTableViewController.h"
#import "DNImageFlowViewController.h"

NSString *kDNImagePickerStoredGroupKey = @"com.dennis.kDNImagePickerStoredGroup";

ALAssetsFilter * ALAssetsFilterFromDNImagePickerControllerFilterType(DNImagePickerFilterType type)
{
    switch (type) {
        default:
        case DNImagePickerFilterTypeNone:
            return [ALAssetsFilter allAssets];
            break;
        case DNImagePickerFilterTypePhotos:
            return [ALAssetsFilter allPhotos];
            break;
        case DNImagePickerFilterTypeVideos:
            return [ALAssetsFilter allVideos];
            break;
    }
}

@interface DNImagePickerController ()<UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) id<UINavigationControllerDelegate> navDelegate;
@property (nonatomic, assign) BOOL isDuringPushAnimation;

@end

@implementation DNImagePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.delegate) {
        self.delegate = self;
    }
    
    self.interactivePopGestureRecognizer.delegate = self;
    
    [self showAlbumList];
    return;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - open methods
//获取相册最新的图片
+ (void)getLatestImageWihtCollecionName:(NSString *)collectionName complainedBlock:(getFistImageBlock)returnBlock; {
    if (collectionName.length == 0 || collectionName == nil) {
        collectionName = @"最近添加";
    }
    
    PHFetchResult *album = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    
    PHAsset *asset;
    for (NSInteger index = 0; index < album.count; index++) {
        PHAssetCollection *collection = album[index];
        if ([collection.localizedTitle isEqualToString:collectionName]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            //从相册中取出第一张图片
            asset = fetchResult.lastObject;
            break;
        }
    }
    
    PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
    opt.resizeMode = PHImageRequestOptionsResizeModeFast;
    opt.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    opt.synchronous = YES;
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFill options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            returnBlock(result);
        }
    }];
}


#pragma mark - priviate methods
- (void)showAlbumList {
    DNAlbumTableViewController *albumTableViewController = [[DNAlbumTableViewController alloc] init];
    albumTableViewController.kDNImageFlowMaxSeletedNumber = self.kDNImageFlowMaxSeletedNumber;
    albumTableViewController.filterType = (int)self.filterType;
    albumTableViewController.enableEditSeconds = self.enableEditSeconds;
    [self setViewControllers:@[albumTableViewController]];
}

#pragma mark - UINavigationController
- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate {
    [super setDelegate:delegate ? self : nil];
    self.navDelegate = delegate != self ? delegate : nil;
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated __attribute__((objc_requires_super)) {
    self.isDuringPushAnimation = YES;
    [super pushViewController:viewController animated:animated];
}

#pragma mark UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    self.isDuringPushAnimation = NO;
    if ([self.navDelegate respondsToSelector:_cmd]) {
        [self.navDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        return [self.viewControllers count] > 1 && !self.isDuringPushAnimation;
    } else {
        return YES;
    }
}

#pragma mark - Delegate Forwarder

- (BOOL)respondsToSelector:(SEL)s
{
    return [super respondsToSelector:s] || [self.navDelegate respondsToSelector:s];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)s
{
    return [super methodSignatureForSelector:s] ?: [(id)self.navDelegate methodSignatureForSelector:s];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    id delegate = self.navDelegate;
    if ([delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:delegate];
    }
}


@end
