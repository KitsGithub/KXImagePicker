//
//  DNImageFlowViewController.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/11.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//




#import "DNImageFlowViewController.h"
#import "DNImagePickerController.h"
#import "DNPhotoBrowser.h"
#import "UIViewController+DNImagePicker.h"
#import "UIView+DNImagePicker.h"
#import "UIColor+Hex.h"
#import "DNAssetsViewCell.h"
#import "DNSendButton.h"
#import "DNAsset.h"
#import "NSURL+DNIMagePickerUrlEqual.h"

//#import "DNVideoEditingController.h"
#import "VideoEditController.h"

#import <Photos/Photos.h>


@interface DNImageFlowViewController () <UICollectionViewDataSource, UICollectionViewDelegate, DNAssetsViewCellDelegate, DNPhotoBrowserDelegate>

@property (nonatomic, strong) UICollectionView *imageFlowCollectionView;
@property (nonatomic, strong) DNSendButton *sendButton;

@property (nonatomic, strong) NSMutableArray *assetsArray;

//已选中图片
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectedAssetsArray;
//已选中的视频
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectedVedioAssetsArray;

@property (nonatomic, assign) BOOL isFullImage;

//相簿内容
@property (nonatomic, strong) PHFetchResult *result;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *albumAssetArray;

@property (nonatomic, assign) BOOL isSelectedImage;

@property (nonatomic, strong) MBProgressHUD *HUD;
@end



static NSString* const dnAssetsViewCellReuseIdentifier = @"DNAssetsViewCell";

@implementation DNImageFlowViewController

- (instancetype)initWithPHFetchResult:(PHFetchResult *)result {
    if (self = [super init]) {
        self.result = result;
    }
    return  self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setNav];
    [self setupView];
    
    [self setupData];
    [self scrollerToBottom:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[[UIColor blackColor] colorWithAlphaComponent:0.0]] forBarMetrics:UIBarMetricsDefault];
    
    if (self.filterType != DNImagePickerFilterTypeVideos) {
        self.navigationController.toolbarHidden = NO;
    } else {
        self.navigationController.toolbarHidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    self.navigationController.toolbarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - setup view and data
- (void)setupData {
    //根据 filterType 筛选当前展示内容
    for (PHAsset *asset in self.result) {
        switch (self.filterType) {
            case DNImagePickerFilterTypePhotos: {
                if (asset.mediaType == PHAssetMediaTypeImage) {
                    [self.albumAssetArray addObject:asset];
                }
            }
                break;
            case DNImagePickerFilterTypeVideos: {
                //这里过滤掉 高帧视频,和 比设定时长大的视频
                if (asset.mediaType == PHAssetMediaTypeVideo && asset.mediaSubtypes != PHAssetMediaSubtypeVideoHighFrameRate && asset.duration <= VideoMaxTimeInterval) {
                    [self.albumAssetArray addObject:asset];
                }
            }
            default:
                break;
        }
    }
    
    [_imageFlowCollectionView reloadData];
}


- (void)setupView {
    
    
    [self imageFlowCollectionView];
    
    if (self.filterType != DNImagePickerFilterTypeVideos) {
        //如果是视频，不加载下面的toolBars
        [self createBarButtonItemAtPosition:DNImagePickerNavigationBarPositionLeft
                          statusNormalImage:[UIImage imageNamed:@"back_normal"]
                       statusHighlightImage:[UIImage imageNamed:@"back_highlight"]
                                     action:@selector(backButtonAction)];
        [self createBarButtonItemAtPosition:DNImagePickerNavigationBarPositionRight
                                       text:NSLocalizedStringFromTable(@"cancel", @"DNImagePicker", @"取消")
                                     action:@selector(cancelAction)];
        
        UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"preview", @"DNImagePicker", @"预览") style:UIBarButtonItemStylePlain target:self action:@selector(previewAction)];
        [item1 setTintColor:[UIColor blackColor]];
        item1.enabled = NO;
        
        UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithCustomView:self.sendButton];
        
        UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        item4.width = -10;
        
        [self setToolbarItems:@[item1,item2,item3,item4] animated:NO];
    }
    
}

- (void)setNav {
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
    if (self.filterType == DNImagePickerFilterTypeVideos) {
        titleLabel.text = @"视频";
    } else {
        titleLabel.text = @"相册";
    }
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:17];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.navigationItem.titleView = titleLabel;
    
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor blackColor]] forBarMetrics:UIBarMetricsDefault];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    backBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [backBtn setImage:[UIImage imageNamed:@"NewCircle_Nav_Back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backItem;
    
}



#pragma mark - helpmethods
- (void)scrollerToBottom:(BOOL)animated {
    if (!self.albumAssetArray.count) {
        return;
    }
    NSInteger rows = [self.imageFlowCollectionView numberOfItemsInSection:0] - 1;
    rows = rows < 0 ? 0 : rows;
    [self.imageFlowCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:rows inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:animated];
}

- (DNImagePickerController *)dnImagePickerController {
    
    if (nil == self.navigationController
        ||
        NO == [self.navigationController isKindOfClass:[DNImagePickerController class]])
    {
        NSAssert(false, @"check the navigation controller");
    }
    return (DNImagePickerController *)self.navigationController;
}

- (BOOL)assetIsSelected:(PHAsset *)targetAsset {
    for (PHAsset *asset in self.selectedAssetsArray) {
        if (asset == targetAsset) {
            return YES;
        }
    }
    return NO;
}

- (void)removeAssetsObject:(PHAsset *)asset {
    if ([self assetIsSelected:asset]) {
        [self.selectedAssetsArray removeObject:asset];
    }
    if (self.selectedAssetsArray.count == 0) { //如果选择的图片为0，需要把置灰的视频类型点亮
        _isSelectedImage = NO;
        [_imageFlowCollectionView reloadData];
    }
}

- (void)addAssetsObject:(PHAsset *)asset {
    [self.selectedAssetsArray addObject:asset];
    if (self.selectedAssetsArray.count == 1) { //如果选择的图片为1，需要把点亮的视频类型置灰
        _isSelectedImage = YES;
        [_imageFlowCollectionView reloadData];
    }
}

- (DNAsset *)dnassetFromALAsset:(ALAsset *)ALAsset {
    DNAsset *asset = [[DNAsset alloc] init];
    asset.url = [ALAsset valueForProperty:ALAssetPropertyAssetURL];
    return asset;
}

- (NSArray *)seletedDNAssetArray {
    NSMutableArray *seletedArray = [NSMutableArray new];
    for (PHAsset *asset in self.selectedAssetsArray) {
        [seletedArray addObject:asset];
    }
    return seletedArray;
}

#pragma mark - priviate methods 
#pragma mark 发送照片
- (void)sendImages {
    DNImagePickerController *imagePicker = [self dnImagePickerController];
    if (imagePicker && [imagePicker.imagePickerDelegate respondsToSelector:@selector(dnImagePickerController:sendImages:isFullImage:)]) {
        [imagePicker.imagePickerDelegate dnImagePickerController:imagePicker sendImages:[self seletedDNAssetArray] isFullImage:self.isFullImage];
    }
}

#pragma mark 预览选中照片
- (void)browserPhotoAsstes:(NSArray *)assets pageIndex:(NSInteger)page {
    DNPhotoBrowser *browser = [[DNPhotoBrowser alloc] initWithPHPhotosArray:self.selectedAssetsArray
                                                        currentIndex:page
                                                           fullImage:self.isFullImage];
    
    browser.delegate = self;
    browser.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:browser animated:YES];
}

- (BOOL)seletedAssets:(PHAsset *)asset {
    if ([self assetIsSelected:asset]) {
        return NO;
    }
    UIBarButtonItem *firstItem = self.toolbarItems.firstObject;
    firstItem.enabled = YES;
    if (self.selectedAssetsArray.count >= self.kDNImageFlowMaxSeletedNumber) {
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"只能选这么多了" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        
        return NO;
    }else
    {
        [self addAssetsObject:asset];
        self.sendButton.badgeValue = [NSString stringWithFormat:@"%@",@(self.selectedAssetsArray.count)];
        return YES;
    }
}

- (void)deseletedAssets:(PHAsset *)asset {
    [self removeAssetsObject:asset];
    self.sendButton.badgeValue = [NSString stringWithFormat:@"%@",@(self.selectedAssetsArray.count)];
    if (self.selectedAssetsArray.count < 1) {
        UIBarButtonItem *firstItem = self.toolbarItems.firstObject;
        firstItem.enabled = NO;
    }
}

#pragma mark - 选择了视频
- (void)videoEditingView:(PHAsset *)videoAsset {
    
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        NSLog(@"下载进度%f",progress);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.HUD) {
                self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:self.HUD];
                self.HUD.mode = MBProgressHUDModeAnnularDeterminate;
                self.HUD.label.text = @"下载中";
                [self.HUD showAnimated:YES];
                self.HUD.progress = 0.05;
            }
            self.HUD.label.text = [NSString stringWithFormat:@"%.0f%%",progress*100];
            self.HUD.progress = progress;
        });
        
        //从iCloud下载视频
        if (progress == 1) {
            NSLog(@"下载完成%@",info);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.HUD hideAnimated:YES];
            });
        }
    };
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    
    PHImageManager *manager = [PHImageManager defaultManager];
    
    [manager requestAVAssetForVideo:videoAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        NSURL *url;
        if (!asset) {
            //无法正常解析视频 or 视频从icloud等待下载
            return ;
        }
        
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            url = urlAsset.URL;
        } else if ([asset isKindOfClass:[AVComposition class]]) {
            AVComposition *urlAsset = (AVComposition *)asset;
            NSLog(@"%@",urlAsset.URLAssetInitializationOptions);
            url = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self jumpToVideoEditingWithURL:url];
        });
    }];
}


//跳转到视频裁剪页面
- (void)jumpToVideoEditingWithURL:(NSURL *)url {
    NSLog(@"解析出来的视频本地路径 -- %@",url);
    VideoEditController *videoEditing = [[VideoEditController alloc] init];
    videoEditing.path = url;
    videoEditing.hidesBottomBarWhenPushed = YES;
    videoEditing.enableEditSeconds = self.enableEditSeconds;
    [self.navigationController pushViewController:videoEditing animated:YES];
}



#pragma mark - ui action
- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)sendButtonAction:(id)sender {
    if (self.selectedAssetsArray.count > 0) {
        [self sendImages];
    }
}

- (void)previewAction {
    [self browserPhotoAsstes:self.selectedAssetsArray pageIndex:0];
}

- (void)cancelAction {
    DNImagePickerController *navController = [self dnImagePickerController];
    if (navController && [navController.imagePickerDelegate respondsToSelector:@selector(dnImagePickerControllerDidCancel:)]) {
        [navController.imagePickerDelegate dnImagePickerControllerDidCancel:navController];
    }
}

#pragma mark - DNAssetsViewCellDelegate
- (void)didSelectItemAssetsViewCell:(DNAssetsViewCell *)assetsCell {
    assetsCell.isSelected = [self seletedAssets:assetsCell.phAsset];
}

- (void)didDeselectItemAssetsViewCell:(DNAssetsViewCell *)assetsCell {
    assetsCell.isSelected = NO;
    [self deseletedAssets:assetsCell.phAsset];
}

#pragma mark - UICollectionView delegate and Datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.albumAssetArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DNAssetsViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:dnAssetsViewCellReuseIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.isSelectedImage = self.isSelectedImage;
    [cell fillWithImage:self.albumAssetArray[indexPath.row] isSelected:[self assetIsSelected:self.albumAssetArray[indexPath.row]]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.albumAssetArray[indexPath.row];
    //判断第一张选中的是什么
    if (asset.mediaType == PHAssetMediaTypeVideo && !_selectedAssetsArray.count) {
        NSLog(@"你点击的是视频");
        [self videoEditingView:asset];
        return;
    }
    
    
    
    DNPhotoBrowser *browser = [[DNPhotoBrowser alloc] initWithPHPhotosArray:self.albumAssetArray
                                                               currentIndex:indexPath.row
                                                                  fullImage:self.isFullImage];
    
    browser.delegate = self;
    browser.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:browser animated:YES];

}


#pragma mark - DNPhotoBrowserDelegate
- (void)sendImagesFromPhotobrowser:(DNPhotoBrowser *)photoBrowser currentAsset:(PHAsset *)asset {
    if (self.selectedAssetsArray.count <= 0) {
        [self seletedAssets:asset];
        [self.imageFlowCollectionView reloadData];
    }
    [self sendImages];
}

- (NSUInteger)seletedPhotosNumberInPhotoBrowser:(DNPhotoBrowser *)photoBrowser {
    return self.selectedAssetsArray.count;
}

- (BOOL)photoBrowser:(DNPhotoBrowser *)photoBrowser currentPhotoAssetIsSeleted:(PHAsset *)asset{
    return [self assetIsSelected:asset];
}

- (BOOL)photoBrowser:(DNPhotoBrowser *)photoBrowser seletedAsset:(PHAsset *)asset {
    BOOL seleted = [self seletedAssets:asset];
    [self.imageFlowCollectionView reloadData];
    return seleted;
}

- (void)photoBrowser:(DNPhotoBrowser *)photoBrowser deseletedAsset:(PHAsset *)asset {
    [self deseletedAssets:asset];
    [self.imageFlowCollectionView reloadData];
}

- (void)photoBrowser:(DNPhotoBrowser *)photoBrowser seleteFullImage:(BOOL)fullImage {
    self.isFullImage = fullImage;
}

#pragma mark - getter/setter
#define kSizeThumbnailCollectionView  ([UIScreen mainScreen].bounds.size.width-10)/4
- (UICollectionView *)imageFlowCollectionView {
    if (!_imageFlowCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 2.0;
        layout.minimumInteritemSpacing = 2.0;
        layout.sectionInset = UIEdgeInsetsMake(2, 2, 2, 2);
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.itemSize = CGSizeMake(kSizeThumbnailCollectionView, kSizeThumbnailCollectionView);
        
        CGFloat collectionHeight;
        if (self.filterType != DNImagePickerFilterTypeVideos) {
            collectionHeight = [UIScreen mainScreen].bounds.size.height - 39 - 69;
        } else {
            collectionHeight = [UIScreen mainScreen].bounds.size.height - 64;
        }
        _imageFlowCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, collectionHeight) collectionViewLayout:layout];
        _imageFlowCollectionView.delegate = self;
        _imageFlowCollectionView.dataSource = self;
        _imageFlowCollectionView.showsHorizontalScrollIndicator = YES;
        _imageFlowCollectionView.alwaysBounceVertical = YES;
        if (self.filterType != DNImagePickerFilterTypeVideos) {
            _imageFlowCollectionView.backgroundColor = [UIColor colorFormHexRGB:@"f7f8f9"];
        } else {
            _imageFlowCollectionView.backgroundColor = [UIColor blackColor];
        }
        
        [_imageFlowCollectionView registerClass:[DNAssetsViewCell class] forCellWithReuseIdentifier:dnAssetsViewCellReuseIdentifier];
        [self.view addSubview:_imageFlowCollectionView];
    }
    
    return _imageFlowCollectionView;
}

- (DNSendButton *)sendButton {
    if (nil == _sendButton) {
        _sendButton = [[DNSendButton alloc] initWithFrame:CGRectZero];
        [_sendButton addTaget:self action:@selector(sendButtonAction:)];
    }
    return  _sendButton;
}

#pragma mark - lazyLoad
- (NSMutableArray<PHAsset *> *)selectedAssetsArray {
    if (!_selectedAssetsArray ) {
        _selectedAssetsArray = [NSMutableArray array];
    }
    return _selectedAssetsArray;
}

- (NSMutableArray<PHAsset *> *)albumAssetArray {
    if (!_albumAssetArray) {
        _albumAssetArray = [NSMutableArray array];
    }
    return _albumAssetArray;
}

- (NSMutableArray<PHAsset *> *)selectedVedioAssetsArray {
    if (!_selectedVedioAssetsArray) {
        _selectedVedioAssetsArray = [NSMutableArray array];
    }
    return _selectedVedioAssetsArray;
}
@end
