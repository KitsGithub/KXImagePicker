//
//  DNAlbumTableViewController.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNAlbumTableViewController.h"
#import "DNImagePickerController.h"
#import "DNImageFlowViewController.h"
#import "UIViewController+DNImagePicker.h"
#import "DNUnAuthorizedTipsView.h"

#import "DNAlbumTableViewCell.h"

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

static NSString* const dnalbumTableViewCellReuseIdentifier = @"dnalbumTableViewCellReuseIdentifier";

@interface DNAlbumTableViewController ()
@property (nonatomic, strong) NSArray *groupTypes;

#pragma mark - dataSources
@property (nonatomic, strong) PHFetchResult *smartAlbums;


@property (nonatomic, strong) NSMutableArray<DNImageCollectionModel *> *modelArray;


@end

@implementation DNAlbumTableViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    //判断相册权限状态
    [self getAblumJurisdiction];
    
    //布局 - 数据获取
    [self setupView];
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//监听相册权限的改变
- (void)getAblumJurisdiction {
    if (isIOS8) {
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
            
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            
            [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                
                if (*stop) {
                    
                    // TODO:...
                    [self loadData];
                    return;
                }
                *stop = TRUE;//不能省略
                
            } failureBlock:^(NSError *error) {
                
                NSLog(@"failureBlock");
            }];
        }
        
    } else {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
            
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
                if (status == PHAuthorizationStatusAuthorized) {
                    
                    // TODO:...
                    [self loadData];
                }
            }];
        }
    }
}



#pragma mark - mark setup Data and View
- (void)loadData
{
    //获取所有相册数据
    self.smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    
        PHFetchResult *album = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        
    for (NSInteger index = 0; index < album.count; index++) {
        PHAssetCollection *collection = album[index];
        //过滤掉视频和最近删除
        if (!(
              collection.assetCollectionSubtype == 1000000201  || //最近删除
              collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden ||//已隐藏
              collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumSlomoVideos ||//慢动作
              collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumPanoramas //全景照片
              )) {
            
            DNImageCollectionModel *albumModel = [DNImageCollectionModel new];
            albumModel.collection = collection;
            albumModel.collectionTitle = collection.localizedTitle;
            
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            //从相册中取出第一张图片
            PHAsset *asset = fetchResult.firstObject;
            if (!asset) {
                continue ;
            }
            
            if (self.filterType == DNImagePickerFilterTypePhotos && [collection.localizedTitle isEqualToString:@"相机胶卷"]) { //防止由于asset取出的是一个视频而导致的相机胶卷不可选的问题
                [self.modelArray addObject:albumModel];
            } else if ((int)asset.mediaType == (int)self.filterType) {
                [self.modelArray addObject:albumModel];
            }
            
        }
        
        [self.tableView reloadData];
    }
}



- (void)setupView
{
    self.title = NSLocalizedStringFromTable(@"albumTitle", @"DNImagePicker", @"photos");
    [self createBarButtonItemAtPosition:DNImagePickerNavigationBarPositionRight
                                   text:NSLocalizedStringFromTable(@"cancel", @"DNImagePicker", @"取消")
                                 action:@selector(cancelAction:)];
    
    [self.tableView registerClass:[DNAlbumTableViewCell class] forCellReuseIdentifier:dnalbumTableViewCellReuseIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = view;
}


#pragma mark - ui actions
- (void)cancelAction:(id)sender
{
    DNImagePickerController *navController = [self dnImagePickerController];
    if (navController && [navController.imagePickerDelegate respondsToSelector:@selector(dnImagePickerControllerDidCancel:)]) {
        [navController.imagePickerDelegate dnImagePickerControllerDidCancel:navController];
    }
}


- (DNImagePickerController *)dnImagePickerController
{
    
    if (nil == self.navigationController
        ||
        ![self.navigationController isKindOfClass:[DNImagePickerController class]])
    {
        NSAssert(false, @"check the navigation controller");
    }
    return (DNImagePickerController *)self.navigationController;
}


- (void)showUnAuthorizedTipsView
{
    DNUnAuthorizedTipsView *view  = [[DNUnAuthorizedTipsView alloc] initWithFrame:self.tableView.frame];
    self.tableView.backgroundView = view;
//    [self.tableView addSubview:view];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DNAlbumTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:dnalbumTableViewCellReuseIdentifier forIndexPath:indexPath];
    cell.model = self.modelArray[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

#pragma mark - tableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DNImageCollectionModel *model = self.modelArray[indexPath.row];
    
    //获取所有的图片
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:model.collection options:nil];
    
    DNImageFlowViewController *imageFlowViewController = [[DNImageFlowViewController alloc] initWithPHFetchResult:fetchResult];
    imageFlowViewController.filterType = self.filterType;
    imageFlowViewController.enableEditSeconds = self.enableEditSeconds;
    imageFlowViewController.kDNImageFlowMaxSeletedNumber = self.kDNImageFlowMaxSeletedNumber;
    [self.navigationController pushViewController:imageFlowViewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}





- (NSMutableArray<DNImageCollectionModel *> *)modelArray {
    if (!_modelArray) {
        _modelArray = [NSMutableArray array];
    }
    return _modelArray;
}
@end
