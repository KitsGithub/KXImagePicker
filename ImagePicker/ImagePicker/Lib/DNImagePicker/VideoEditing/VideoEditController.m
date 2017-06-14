//
//  VideoEditController.m
//  ZhiMaBaoBao
//
//  Created by liugang on 2017/6/2.
//  Copyright © 2017年 liugang. All rights reserved.
//

#define margin 10
#define padding 1
#define maxSeconds 20.0   //视频剪裁最大秒数
#define sliderWidth 25    //左右侧滑块宽度
#define editMinSeconds 3.0   //截取视频最短时长限制s
#define btnPadding 6         //左右测滑块切图内边距
#define kscale kScreenWidth/375.0
//#define imageHeight kScreenWidth<375?60*kscale:60
#define imageHeight 60*kscale

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#define DocumentPATH  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define AUDIOPATH   [NSString stringWithFormat:@"%@/10086",DocumentPATH]

#import "VideoEditController.h"
#import "DNImagePickerController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+DNImagePicker.h"

@interface VideoEditController ()<UIScrollViewDelegate>{
    id _playTimeObserver;               //视频播放观察者
    BOOL _isSliding;        //底部图片帧是否滑动
    CGFloat originalX;      //编辑框初始x位置
    CGFloat originalMaxX;   //右侧滑块初始最大x位置
    CGFloat rangeViewMaxWidth;   //rangeView最大宽度
    CGFloat rangeViewMinWidth;   //rangeView最小宽度
    CGFloat rangeViewLastWidth;  //rangeView上一次宽度
    CGFloat rangeViewMaxX;       //rangeView最大X值
    CGFloat rangeViewMinX;       //rangeView最小值
    CGFloat rightLastOffset;    //右侧上一次的偏移量
    CGFloat adjustTime;     //滑动底部scrollView调整的时间
    CGFloat leftAdjustTime;     //滑动底部左侧滑块调整的时间
    CGFloat rightAdjustTime;    //滑动底部右侧滑块调整的时间
    CGFloat leftLastX;          //左侧滑块上一次x位置
    CGFloat rightLastX;         //右侧滑块上一次x位置
    CGFloat scrollMaxOffsetX;   //scrollView x方向最大偏移量
    CGFloat rate;               //播放速率
    CGFloat actualTime;         //编辑区域时间

}

typedef void(^Completion)(NSArray *images);


@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, assign) CGFloat videoDurtion;   //视频总时长
@property (nonatomic, assign) NSInteger imagesCount;  //图片帧张数


@property (nonatomic, strong) UIView *editView;     //编辑试图
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) UIView *rangeView;    //编辑区域
@property (nonatomic, strong) UILabel *timeLabel;   //已选时间
@property (nonatomic, strong) UIView *rateCover;    //蒙板2
@property (nonatomic, strong) UIButton *lastSelectedBtn;    //上次选择速率按钮

@end

@implementation VideoEditController

- (instancetype)init{
    if (self = [super init]) {
        self.enableEditSeconds = maxSeconds;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self initViews];
    [self splitVideo:self.path];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    
    //禁止侧滑手势
    if([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    [self.player pause];
    self.player = nil;
    
    //打开侧滑手势
    if([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

#pragma mark - set UI
- (void)initViews{
    adjustTime = 0;
    rightLastOffset = 0;
    rate = 1.0;
    
    //初始化播放器
    self.asset = [AVURLAsset URLAssetWithURL:_path options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:_asset];
    self.player = [AVPlayer playerWithPlayerItem:_playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    self.playerLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    [self.view.layer addSublayer:_playerLayer];
    [self play];
    
    //获取视频长度
    self.videoDurtion = CMTimeGetSeconds(_asset.duration);
    //实际可截取长度
    actualTime = self.videoDurtion<self.enableEditSeconds?self.videoDurtion:self.enableEditSeconds;
    
    NSLog(@"self.videoDurtion:%f   actualTime:%f",self.videoDurtion,actualTime);
    
    //添加观察者
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    //监听播放
    [self monitoringPlayback:_playerItem];
    
    //底部编辑视频view
    self.editView = [[UIView alloc] init];
    [self.view addSubview:self.editView];
    //半透明遮盖层
    UIView *cover = [[UIView alloc] init];
    cover.backgroundColor = [UIColor blackColor];
    cover.alpha = 0.4;
    [self.editView addSubview:cover];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    [self.editView addSubview:self.scrollView];
    
    //最后一张图片按比例剪裁处理
//    NSInteger lastIndex = MAXFLOAT;
//    NSInteger duration = ceil(self.videoDurtion);
//    lastIndex = duration/4;
//    CGFloat widthScale = (duration%4)/4.0;
//    CGFloat imageW = imageHeight;
//    for (int i = 0; i<self.imagesCount; i++) {
//        UIImageView *imageView = [[UIImageView alloc] init];
//        imageView.contentMode = UIViewContentModeScaleToFill;
//        imageView.clipsToBounds = YES;
////        imageView.image = self.images[i];
//        imageView.frame = CGRectMake(i*(imageW+padding), 0, imageW, imageHeight);
//        imageView.userInteractionEnabled = YES;
//        imageView.tag = i;
//        imageView.contentMode = UIViewContentModeScaleAspectFill;
//        if (i == lastIndex && self.videoDurtion>maxSeconds) {
//            imageView.width = widthScale*imageW;
//        }
//        [self.scrollView addSubview:imageView];
//    }
    
    //根据图片宽度设置frame
    self.editView.frame = CGRectMake(0, kScreenHeight - (imageHeight+2*padding + margin), kScreenWidth, imageHeight+2*padding);
    cover.frame = CGRectMake(0, padding, kScreenWidth, imageHeight);
    self.scrollView.frame = CGRectMake(0, padding, kScreenWidth, imageHeight);
    
    
    //计算编辑区域的最大宽度
    rangeViewMaxWidth = imageHeight*5 + 4*padding;
    rangeViewMinWidth = rangeViewMaxWidth * (editMinSeconds/maxSeconds);
    originalX = (kScreenWidth - rangeViewMaxWidth)/2;
    
    //可剪裁区域判断
    if (self.enableEditSeconds < maxSeconds) {
        rangeViewMaxWidth = rangeViewMaxWidth * (self.enableEditSeconds/maxSeconds);
    }
    
    //视频时长小余最大时长、重设置scrollview的宽度
    if (self.videoDurtion < self.enableEditSeconds) {
        rangeViewMaxWidth = (imageHeight*5 + 4*padding) * (self.videoDurtion/maxSeconds);
        self.scrollView.width = rangeViewMaxWidth+originalX;
        self.scrollView.userInteractionEnabled = NO;
    }
    
    //视频时长小余默认可编辑最小时长
    if (self.videoDurtion < editMinSeconds) {
        rangeViewMaxWidth = (imageHeight*5 + 4*padding) * (editMinSeconds/maxSeconds);
        self.scrollView.width = rangeViewMaxWidth+originalX;
        self.scrollView.userInteractionEnabled = NO;
        
    }
    
    rangeViewMaxX = originalX + rangeViewMaxWidth;
    rangeViewMinX = originalX;
    
    //设置图片帧初始位置为第一帧  (初始宽度 + 图片总宽度 - rangeview宽度)
    self.scrollView.contentSize = CGSizeMake(kScreenWidth - originalX + (imageHeight + padding)*self.imagesCount - rangeViewMaxWidth, 0);
    if (self.videoDurtion > maxSeconds) {
        self.scrollView.contentSize = CGSizeMake(kScreenWidth - originalX + (imageHeight + padding)*ceil(self.videoDurtion)/4.0 - rangeViewMaxWidth, 0);
    }
    self.scrollView.contentOffset = CGPointMake(-originalX, 0);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, originalX, 0, 0);
    //scrollView可滑动区域x最大变化值
    CGFloat totalWidth = self.scrollView.contentSize.width + originalX;
    scrollMaxOffsetX = totalWidth - CGRectGetWidth(self.scrollView.frame);
    
    NSLog(@"self.videoDurtion:%f",self.videoDurtion);
    //视频区域框
    self.rangeView = [[UIView alloc] initWithFrame:CGRectMake(originalX, 0, rangeViewMaxWidth, imageHeight+2*padding)];
    self.rangeView.layer.borderWidth = padding;
    self.rangeView.layer.borderColor = [UIColor redColor].CGColor;
    self.rangeView.userInteractionEnabled = NO;
    [self.editView addSubview:self.rangeView];
    
    //选取时间
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.editView.frame), CGRectGetMinY(self.editView.frame) - 14 - 15, CGRectGetWidth(self.editView.frame), 14)];
    self.timeLabel.font = [UIFont systemFontOfSize:13];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.text = [NSString stringWithFormat:@"已选取%.0fs",ceil(actualTime)];
    [self.view addSubview:self.timeLabel];
    
    //视频编辑框左右两侧滑动按钮
    UIButton *left = [[UIButton alloc] initWithFrame:CGRectMake(originalX - sliderWidth + btnPadding, 0, sliderWidth, imageHeight+2*padding)];
    [left setImage:[UIImage imageNamed:@"videoEdit_left"] forState:UIControlStateNormal];
    [left setImage:[UIImage imageNamed:@"videoEdit_left"] forState:UIControlStateHighlighted];
    [left addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(leftPanAction:)]];
    [self.editView addSubview:left];
    leftLastX = CGRectGetMinX(left.frame);
    
    UIButton *right = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.rangeView.frame) - btnPadding, 0, sliderWidth, imageHeight+2*padding)];
    [right setImage:[UIImage imageNamed:@"videoEdit_right"] forState:UIControlStateNormal];
    [right setImage:[UIImage imageNamed:@"videoEdit_right"] forState:UIControlStateHighlighted];
    [right addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rightPanAction:)]];
    [self.editView addSubview:right];
    originalMaxX = CGRectGetMaxX(self.rangeView.frame);
    rangeViewLastWidth = CGRectGetWidth(self.rangeView.frame);
    rightLastX = originalMaxX - btnPadding;
    
    //视频时长小余默认可编辑最小时长 左右滑块禁止滑动
    if (self.videoDurtion < editMinSeconds) {
        left.userInteractionEnabled = NO;
        right.userInteractionEnabled = NO;
    }

    
    //顶部返回确定栏
    UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, 20, kScreenWidth, 40)];
    [self.view addSubview:bottomBar];
    UIButton *confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth - 7 - 40, 0, 43, 40)];
    [confirmBtn setImage:[UIImage imageNamed:@"videoEdit_ok"] forState:UIControlStateNormal];
    [confirmBtn addTarget:self action:@selector(confirmAction) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:confirmBtn];
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(7, 0, 40, 40)];
    [cancelBtn setImage:[UIImage imageNamed:@"videoEdit_cancel"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:cancelBtn];
    
    //播放速率控制栏
    CGFloat width = kScreenWidth - 60;
    UIView *rateView = [[UIView alloc] initWithFrame:CGRectMake(30, CGRectGetMinY(self.timeLabel.frame) - 20 - 40, width, 40)];
    rateView.layer.cornerRadius = 20;
    rateView.clipsToBounds = YES;
//    [self.view addSubview:rateView];
    
    UIView *cover11 = [[UIView alloc] initWithFrame:rateView.bounds];
    cover11.backgroundColor = [UIColor blackColor];
    cover11.alpha = 0.4;
    [rateView addSubview:cover11];
    
    self.rateCover = [[UIView alloc] initWithFrame:CGRectMake(2*width/5.0, 0, width/5.0, 40)];
    self.rateCover.backgroundColor = [UIColor yellowColor];
    [rateView addSubview:self.rateCover];
    
    NSArray *titles = @[@"极慢",@"慢",@"标准",@"快",@"极快"];
    for (int i=0; i<5; i++) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(i*width/5.0, 0, width/5.0, 40)];
        btn.tag = i;
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateSelected];
        btn.titleLabel.font = [UIFont systemFontOfSize:15];
        [btn addTarget:self action:@selector(changeVideoRate:) forControlEvents:UIControlEventTouchUpInside];
        [rateView addSubview:btn];
        if (i == 2) {
            btn.selected = YES;
            self.lastSelectedBtn = btn;
        }
    }
}

- (void)changeVideoRate:(UIButton *)sender{
    switch (sender.tag) {
        case 0:
            rate = 0.5;
            break;
        case 1:
            rate = 0.75;
            break;
        case 2:
            rate = 1.0;
            break;
        case 3:
            rate = 1.5;
            break;
        case 4:
            rate = 2.0;
            break;
            
        default:
            break;
    }
    
    self.lastSelectedBtn.selected = NO;
    sender.selected = YES;
    self.lastSelectedBtn = sender;
    [UIView animateWithDuration:0.3 animations:^{
        self.rateCover.x = sender.tag*sender.size.width;
    }];
    [_playerItem seekToTime:kCMTimeZero];
    [self play];
}

#pragma mark - 左滑块滑动方法
//左测滑块滑动方法
- (void)leftPanAction:(UIPanGestureRecognizer *)ges{
    
    UIView *left = ges.view;
    //x方向偏移量
    CGFloat transX = [ges translationInView:left].x;
    //偏移时间
    static CGFloat offTime = 0;
    //左侧滑块初始x
    CGFloat leftSliderOriginalX = originalX - sliderWidth + btnPadding;
    
    //手指接触滑块
    if (ges.state == UIGestureRecognizerStateBegan) {
        _isSliding = YES;
        leftLastX = left.frame.origin.x;
    }
    
    //滑动中
    if (ges.state == UIGestureRecognizerStateChanged) {
        [self pause];
        
        //设置滑块frame
        CGFloat x = leftLastX + transX;
        //最小边时长界判断
        //调整后rangeView的宽度
        CGFloat rangeWidth = rangeViewMaxWidth - (x - leftSliderOriginalX) - rightLastOffset;   //原始宽度 - 左侧偏移量 - 右侧偏移量
        if (rangeWidth <= rangeViewMinWidth) {
            x = rangeViewMaxX - rangeViewMinWidth - sliderWidth + btnPadding;
            rangeWidth = rangeViewMinWidth;
        }
        //左侧边界判断
        if (leftLastX + transX <= leftSliderOriginalX) {
            x = leftSliderOriginalX;
            rangeWidth = rightLastX+btnPadding - (leftSliderOriginalX +sliderWidth-btnPadding);
        }
        //最大时长边界判断
        if ((rightLastX+btnPadding) - (x+sliderWidth - btnPadding) > rangeViewMaxWidth) {
            x = (rightLastX+btnPadding) - rangeViewMaxWidth - sliderWidth + btnPadding;
            rangeWidth = rangeViewMaxWidth;
        }
        
        NSLog(@"right %f  -----  left %f   ------- maxWidth %f",rightLastX+btnPadding,x+sliderWidth - btnPadding,rangeViewMaxWidth);
        
        //x方向比较x初始位置偏移量
        CGFloat xx = x - leftSliderOriginalX;
        
        CGFloat offsetScale = xx/rangeViewMaxWidth;
        //3.换算偏移成时间
        offTime = actualTime * offsetScale;
        if (xx < 0) {
            offTime = 0;
        }
        
//        NSLog(@"xx:%f maxWidth:%f offTime:%f",xx,rangeViewMaxWidth,offTime);
        
        //刷新控件位置
        left.x = x;
        self.rangeView.x = x + sliderWidth - btnPadding;
        self.rangeView.width = rangeWidth;
        
        //设置播放时间
        CMTime changedTime = CMTimeMakeWithSeconds(offTime+adjustTime, 1 *NSEC_PER_SEC);
        [_playerItem seekToTime:changedTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        }];
        
        //设置选取时间
        [self setDisplayTime:offTime+rightAdjustTime];
        
        NSLog(@"offtime;%f",offTime);
        
    }
    
    //手指滑动结束
    if (ges.state == UIGestureRecognizerStateEnded) {
        
        _isSliding = NO;
        leftLastX = left.frame.origin.x;
        rangeViewLastWidth = CGRectGetWidth(self.rangeView.frame);
        rangeViewMinX = CGRectGetMinX(self.rangeView.frame);
        leftAdjustTime = offTime;
        //设置播放时间
        CMTime changedTime = CMTimeMakeWithSeconds(leftAdjustTime+adjustTime, 1 *NSEC_PER_SEC);
        [_playerItem seekToTime:changedTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        }];
        [self play];
    }
}

#pragma mark - 右侧滑块滑动方法
- (void)rightPanAction:(UIPanGestureRecognizer *)ges{
    UIView *right = ges.view;
    //x方向偏移量
    CGFloat transX = [ges translationInView:right].x;

    //偏移时间
    static CGFloat offTime1 = 0;
    //手指接触滑块
    if (ges.state == UIGestureRecognizerStateBegan) {
        _isSliding = YES;
        rightLastX = right.frame.origin.x;
    }
    
    //滑动中
    if (ges.state == UIGestureRecognizerStateChanged) {
        [self pause];
        
        //右侧滑块x值
        CGFloat x = rightLastX + transX;
        
        //最短时长边界判断
        CGFloat rangeWidth = rangeViewLastWidth + transX;   //上一次宽度 + 偏移量
        if (rangeWidth <= rangeViewMinWidth) {
            x = rangeViewMinX + rangeViewMinWidth - btnPadding;
            rangeWidth = rangeViewMinWidth;
        }
        
        //右侧边界判断 （区分两种情况）
        if (self.enableEditSeconds >= self.videoDurtion) {
            if (rightLastX + transX + btnPadding >= originalMaxX) {
                x = originalMaxX - btnPadding;
                rangeWidth = rangeViewMaxWidth - rangeViewMinX + originalX;
            }
        }else{
            //图片帧总宽度
            CGFloat scrollWidth = self.imagesCount*(imageHeight) - padding;
            //左侧滑块偏移量 (结束位置 - 初始位置)
            CGFloat leftOffset = leftLastX - (originalX - sliderWidth + btnPadding);
            static BOOL judge1 = YES;
            static BOOL judge2 = YES;

            //右侧边界判断
            if ((rightLastX-originalX+transX+btnPadding >= scrollWidth) && judge1) {
                x = originalX + scrollWidth - btnPadding;
                rangeWidth = scrollWidth - (leftLastX - sliderWidth + btnPadding);
                judge2 = NO;
            }else{
                judge2 = YES;
            }
            //最大时长判断
            if ((rightLastX + transX + btnPadding >= originalMaxX + leftOffset) && judge2) {
                x = leftLastX + sliderWidth -2*btnPadding + rangeViewMaxWidth;
                rangeWidth = rangeViewMaxWidth;
                judge1 = NO;
            }else{
                judge1 = YES;
            }
        }

        
        right.x = x;
        self.rangeView.width = rangeWidth;
        
        //x方向偏移量(滑块最大位置 - 结束位置)
        CGFloat xx = originalMaxX - btnPadding - x;
        rightLastOffset = xx;
        
        //2.换算成比例
        CGFloat offsetScale = xx/rangeViewMaxWidth;
        //3.换算偏移成时间
        offTime1 = actualTime * offsetScale;
        if (self.enableEditSeconds >= self.videoDurtion) {
            if (xx < 0) {
                offTime1 = 0;
            }
        }
        //设置选取时间
        [self setDisplayTime:offTime1+leftAdjustTime];
        NSLog(@"maxWidth:%f xx:%f totalTime:%f offtime1:%f---- playTime:%f",rangeViewMaxWidth,xx,actualTime,offTime1,actualTime+adjustTime - offTime1);
        //设置播放时间
        CMTime changedTime = CMTimeMakeWithSeconds(actualTime+adjustTime - offTime1, 1 *NSEC_PER_SEC);
        [_playerItem seekToTime:changedTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        }];
        
    }
    
    //手指滑动结束
    if (ges.state == UIGestureRecognizerStateEnded) {
        
        _isSliding = NO;
        rangeViewLastWidth = CGRectGetWidth(self.rangeView.frame);
        rangeViewMaxX = CGRectGetMaxX(self.rangeView.frame);
        rightAdjustTime = offTime1;
        rightLastX = right.frame.origin.x;
        CMTime changedTime = CMTimeMakeWithSeconds(leftAdjustTime + adjustTime, 1 *NSEC_PER_SEC);
        [_playerItem seekToTime:changedTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        }];
        [self play];
    }
    
}


#pragma mark - scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    //scrollView总宽度
    CGFloat totalWidth = self.scrollView.contentSize.width - originalX;
    //结束偏移量
    CGFloat endOffsetX = self.scrollView.contentOffset.x;
    //偏移量差值
    CGFloat offsetX = endOffsetX - (-originalX);
    //左右边界判断
    if (offsetX < 0) {
        offsetX = 0;
    }
    if (offsetX > scrollMaxOffsetX) {
        offsetX = scrollMaxOffsetX;
    }
    //偏移比例
    CGFloat offsetScale = offsetX/totalWidth;
    //换算成时间
    CGFloat time = self.videoDurtion * offsetScale;
    
    //    NSLog(@"endOffsetX:%.2f    offsetX:%.2f   scrollMaxOffsetX:%.2f",endOffsetX,offsetX,scrollMaxOffsetX);
    
    //设置播放时间
    CMTime changedTime = CMTimeMakeWithSeconds(time+leftAdjustTime, 1 *NSEC_PER_SEC);
    if (_isSliding) {
        [_playerItem seekToTime:changedTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        }];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _isSliding = YES;
    [self pause];
}

//滑动结束
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    _isSliding = NO;
    
    //scrollView总宽度
    CGFloat totalWidth = self.scrollView.contentSize.width - originalX;
    //结束偏移量
    CGFloat endOffsetX = self.scrollView.contentOffset.x;
    //偏移量差值
    CGFloat offsetX = endOffsetX - (-originalX);
    //左右边界判断
    if (offsetX < 0) {
        offsetX = 0;
    }
    if (offsetX > scrollMaxOffsetX) {
        offsetX = scrollMaxOffsetX;
    }
    //偏移比例
    CGFloat offsetScale = offsetX/totalWidth;
    //换算成时间
    CGFloat time = self.videoDurtion * offsetScale;
    
    //偏移为正设置调整时间
    adjustTime = time;
    if (endOffsetX <= -originalX) {
        adjustTime = 0;
    }
    [self play];
}

#pragma mark - 设置视频截取时间
- (void)setDisplayTime:(CGFloat)totalAdjustTime{
    int displayTime = (actualTime - totalAdjustTime) > 3.001 ? ceil(actualTime - totalAdjustTime) : 3;
    NSLog(@"time:%f --- displayTime:%d",actualTime - totalAdjustTime,displayTime);
    //    NSLog(@"time%f totalTime:%f  ------  totalAdjustTime:%f",time,(time - totalAdjustTime),totalAdjustTime);
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"已选取%ds",displayTime]];
    [attributeStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13] range:NSMakeRange(0, attributeStr.string.length)];
    [attributeStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attributeStr.string.length)];
    if (displayTime == 3) {
        [attributeStr addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(3, 1)];
    }
    self.timeLabel.attributedText = attributeStr;
}
#pragma mark - 完成剪裁
- (void)confirmAction{
    
//    [MBProgressHUD  showLoadText:@"处理中..."];

    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:_asset presetName:AVAssetExportPresetPassthrough];
    exportSession.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(adjustTime+leftAdjustTime, 1 *NSEC_PER_SEC), CMTimeMakeWithSeconds(actualTime - rightAdjustTime - leftAdjustTime, 1 *NSEC_PER_SEC));
    NSLog(@"startTIme:%f    range:%f",adjustTime+leftAdjustTime,actualTime - rightAdjustTime - leftAdjustTime);
    exportSession.outputFileType = AVFileTypeMPEG4;
    NSString *path = [AUDIOPATH stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld.mp4",[NSDate currentTimeStamp]]];
    
    exportSession.outputURL =  [NSURL fileURLWithPath:path];
    exportSession.shouldOptimizeForNetworkUse = YES;
    NSLog(@"exporting to %@",path);
    //开始剪裁
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSString *status = @"";
        if( exportSession.status == AVAssetExportSessionStatusCompleted ) status = @"AVAssetExportSessionStatusCompleted";
        else if( exportSession.status == AVAssetExportSessionStatusFailed ) status = @"AVAssetExportSessionStatusFailed";
    
        dispatch_async(dispatch_get_main_queue(), ^{
            DNImagePickerController *picker = (DNImagePickerController *)self.navigationController;
            if ([picker.imagePickerDelegate respondsToSelector:@selector(dnImagePickerController:sendVideo:)]) {
                [picker.imagePickerDelegate dnImagePickerController:picker sendVideo:path];
            }
        });
        
        [self.player.currentItem cancelPendingSeeks];
        [self.player.currentItem.asset cancelLoading];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        [self.player pause];
        self.player = nil;
        
        NSLog(@"done exporting to %@ ",path);
    }];
}

#pragma mark - 视频相关观察者方法
// 观察播放进度
- (void)monitoringPlayback:(AVPlayerItem *)item {
    __weak typeof(self)WeakSelf = self;
    
    // 播放进度, 每秒执行30次， CMTime 为30分之一秒
    _playTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        //当前播放秒时间
        float currentPlayTime = (double)item.currentTime.value/ item.currentTime.timescale;
        
        //调整后的时间
//        float afterAdjustTime = currentPlayTime - adjustTime - leftAdjustTime;
//        NSLog(@"currentPlayTime:%f  adjustTime:%f leftAdjustTime:%f  afterAdjustTime:%f ",currentPlayTime,adjustTime,leftAdjustTime,afterAdjustTime);
        
        
        if (currentPlayTime - adjustTime > actualTime - rightAdjustTime) {
            //循环播放
            [WeakSelf.playerItem seekToTime:CMTimeMakeWithSeconds(adjustTime+leftAdjustTime, 30.0) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            }];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            
            CMTime duration = playerItem.duration; // 获取视频长度
            self.videoDurtion = CMTimeGetSeconds(duration);
        }
    }
}

#pragma mark - 其它自定义方法
/**
 *  把视频文件拆成图片保存在沙盒中
 *
 *  @param fileUrl        本地视频文件URL
 *  @param fps            拆分时按此帧率进行拆分
 *  @param completedBlock 所有帧被拆完成后回调
 */
- (void)splitVideo:(NSURL *)fileUrl{
    if (!fileUrl) {
        return;
    }
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *avasset = [[AVURLAsset alloc] initWithURL:fileUrl options:optDict];
    
    CMTime cmtime = avasset.duration; //视频时间信息结构体
    Float64 durationSeconds = CMTimeGetSeconds(cmtime); //视频总秒数
    
    NSMutableArray *times = [NSMutableArray array];
    Float64 totalFrames = durationSeconds; //获得视频总帧数
    CMTime timeFrame;
    for (int i = 0; i <= totalFrames; i+=4) {
        timeFrame = CMTimeMake(i+1, 1); //+1是为了防止第0秒帧取不到
        if (i+1>durationSeconds) {
           timeFrame = CMTimeMake(durationSeconds, 1);
        }
        NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
        [times addObject:timeValue];
    }
    
    NSLog(@"------- start");
    AVAssetImageGenerator *imgGenerator = [[AVAssetImageGenerator alloc] initWithAsset:avasset];
    //防止时间出现偏差
    imgGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imgGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    //保证截取图片方向正确性
    imgGenerator.appliesPreferredTrackTransform = YES;
    [imgGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        printf("current-----: %lld\n", requestedTime.value);
        switch (result) {
            case AVAssetImageGeneratorCancelled:
                NSLog(@"Cancelled");
                break;
            case AVAssetImageGeneratorFailed:
                NSLog(@"Failed");
                break;
            case AVAssetImageGeneratorSucceeded: {
                UIImage *imagef = [UIImage imageWithCGImage:image];
                NSInteger index = (requestedTime.value)/4;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshImage:imagef index:index];
                });
                
            }
                break;
        }
    }];
}

//刷新单张图片帧
- (void)refreshImage:(UIImage *)image index:(NSInteger)index{
    NSInteger lastIndex = MAXFLOAT;
    NSInteger duration = ceil(self.videoDurtion);
    lastIndex = duration/4;
    CGFloat widthScale = (duration%4)/4.0;
    CGFloat imageW = imageHeight;
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.clipsToBounds = YES;
    imageView.image = image;
    imageView.frame = CGRectMake(index*(imageW+padding), 0, imageW, imageHeight);
    imageView.userInteractionEnabled = YES;
    imageView.tag = index;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    if (index == lastIndex && self.videoDurtion>maxSeconds) {
        imageView.width = widthScale*imageW;
    }
    [self.scrollView addSubview:imageView];
}

//暂停
- (void)pause{
    [_player pause];
}

//播放
- (void)play{
    [_player play];
    _player.rate = rate;
}

//图片帧张数
- (void)setVideoDurtion:(CGFloat)videoDurtion{
    _videoDurtion = videoDurtion;
    _imagesCount = 0;
    for (int i = 1; i <= videoDurtion; i+=4) {
        _imagesCount++;
    }
}

- (void)cancelAction{
    [self pause];
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - 视频播放完成
- (void)playbackFinished:(NSNotification *)notification {
    NSLog(@"视频播放完成通知");
    _playerItem = [notification object];
    //item 跳转到初始
    [_playerItem seekToTime:CMTimeMakeWithSeconds(adjustTime+leftAdjustTime, 30.0) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
    }];
    [self play]; //循环播放
}

#pragma mark - 隐藏状态栏
// 返回状态栏的样式
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
// 控制状态栏的现实与隐藏
- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)dealloc {
    [_player removeTimeObserver:_playTimeObserver]; // 移除playTimeObserver
    _playTimeObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

@end
