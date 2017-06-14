//
//  ViewController.m
//  ImagePicker
//
//  Created by mac on 2017/6/13.
//  Copyright © 2017年 kit. All rights reserved.
//

#import "ViewController.h"
#import "DNImagePickerController.h"

@interface ViewController () <DNImagePickerControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *sender1 = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 200, 100)];
    sender1.backgroundColor = [UIColor redColor];
    [sender1 setTitle:@"打开相册图片" forState:UIControlStateNormal];
    [sender1 addTarget:self action:@selector(openAlbumPhotos) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sender1];
    
    UIButton *sender2 = [[UIButton alloc] initWithFrame:CGRectMake(100, 300, 200, 100)];
    sender2.backgroundColor = [UIColor redColor];
    [sender2 setTitle:@"打开相册视频" forState:UIControlStateNormal];
    [sender2 addTarget:self action:@selector(openAlbumVideos) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sender2];
}

- (void)openAlbumPhotos {
    DNImagePickerController *picker = [[DNImagePickerController alloc] init];
    picker.kDNImageFlowMaxSeletedNumber = 9;
    picker.imagePickerDelegate = self;
    picker.filterType = DNImagePickerFilterTypePhotos;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)openAlbumVideos {
    DNImagePickerController *picker = [[DNImagePickerController alloc] init];
    picker.imagePickerDelegate = self;
    picker.filterType = DNImagePickerFilterTypeVideos;
    picker.enableEditSeconds = 180;
    [self presentViewController:picker animated:YES completion:nil];
}


- (void)dnImagePickerController:(DNImagePickerController *)imagePicker sendVideo:(NSString *)videoLoaclURLStr {
    NSLog(@"%@",videoLoaclURLStr);
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)dnImagePickerController:(DNImagePickerController *)imagePicker sendImages:(NSArray *)imageAssets isFullImage:(BOOL)fullImage {
    
    NSLog(@"%@",imageAssets);
    
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)dnImagePickerControllerDidCancel:(DNImagePickerController *)imagePicker {
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
