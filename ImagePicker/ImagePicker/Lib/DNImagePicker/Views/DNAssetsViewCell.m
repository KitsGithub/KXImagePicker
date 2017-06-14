//
//  DNAssetsViewCell.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/11.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNAssetsViewCell.h"


@interface DNAssetsViewCell ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *checkButton;
@property (nonatomic, strong) UIImageView *checkImageView;
@property (nonatomic, strong) UIImageView *vedioImage;
@property (nonatomic, strong) UILabel *vedioDurationLabel;
@property (nonatomic, strong) UIView *coverView;
- (IBAction)checkButtonAction:(id)sender;

@end

@implementation DNAssetsViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self imageView];
        [self checkButton];
        [self checkImageView];
        [self vedioView];
        [self vedioDurationLabel];
        [self coverView];
        [self addContentConstraint];
    }
    return self;
}

- (void)addContentConstraint
{
    NSLayoutConstraint *imageConstraintsBottom = [NSLayoutConstraint
                                                  constraintWithItem:self.imageView
                                                  attribute:NSLayoutAttributeBottom 
                                                  relatedBy:NSLayoutRelationEqual
                                                  toItem:self
                                                  attribute:NSLayoutAttributeBottom
                                                  multiplier:1.0f
                                                  constant:0];
    
    NSLayoutConstraint *imageConstraintsleading = [NSLayoutConstraint
                                                   constraintWithItem:self.imageView
                                                   attribute:NSLayoutAttributeLeading
                                                   relatedBy:NSLayoutRelationEqual
                                                   toItem:self
                                                   attribute:NSLayoutAttributeLeading
                                                   multiplier:1.0
                                                   constant:0];
    
    NSLayoutConstraint *imageContraintsTop = [NSLayoutConstraint
                                              constraintWithItem:self.imageView
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:self
                                              attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                              constant:0];
    
    NSLayoutConstraint *imageViewConstraintTrailing = [NSLayoutConstraint
                                                       constraintWithItem:self.imageView
                                                       attribute:NSLayoutAttributeTrailing
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:self
                                                       attribute:NSLayoutAttributeTrailing
                                                       multiplier:1.0
                                                       constant:0];
    
    [self addConstraints:@[imageConstraintsBottom,imageConstraintsleading,imageContraintsTop,imageViewConstraintTrailing]];
    
    NSLayoutConstraint *checkConstraitRight = [NSLayoutConstraint
                                               constraintWithItem:self.checkButton
                                               attribute:NSLayoutAttributeTrailing
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self
                                               attribute:NSLayoutAttributeTrailing
                                               multiplier:1.0f
                                               constant:0];
    
    NSLayoutConstraint *checkConstraitTop = [NSLayoutConstraint
                                             constraintWithItem:self.checkButton
                                             attribute:NSLayoutAttributeTop
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self
                                             attribute:NSLayoutAttributeTop
                                             multiplier:1.0f
                                             constant:0];
    
    NSLayoutConstraint *chekBtViewConsraintWidth = [NSLayoutConstraint
                                                    constraintWithItem:self.checkButton
                                                    attribute:NSLayoutAttributeWidth
                                                    relatedBy:NSLayoutRelationEqual
                                                    toItem:self.imageView
                                                    attribute:NSLayoutAttributeHeight
                                                    multiplier:0.5f
                                                    constant:0];

    NSLayoutConstraint *chekBtViewConsraintHeight = [NSLayoutConstraint
                                                     constraintWithItem:self.checkButton
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                     toItem:self.checkButton
                                                     attribute:NSLayoutAttributeWidth
                                                     multiplier:1.0
                                                     constant:0];
    
    [self addConstraints:@[checkConstraitRight,checkConstraitTop,chekBtViewConsraintWidth,chekBtViewConsraintHeight]];
    
    NSDictionary *checkImageViewMetric = @{@"sideLength":@25};
    NSString *checkImageViewVFLH = @"H:[_checkImageView(sideLength)]-3-|";
    NSString *checkImageVIewVFLV = @"V:|-3-[_checkImageView(sideLength)]";
    NSArray *checkImageConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:checkImageViewVFLH options:0 metrics:checkImageViewMetric views:NSDictionaryOfVariableBindings(_checkImageView)];
    NSArray *checkImageConstraintsV = [NSLayoutConstraint constraintsWithVisualFormat:checkImageVIewVFLV options:0 metrics:checkImageViewMetric views:NSDictionaryOfVariableBindings(_checkImageView)];

    [self addConstraints:checkImageConstraintsH];
    [self addConstraints:checkImageConstraintsV];
}


#define kSizeThumbnailCollectionView  ([UIScreen mainScreen].bounds.size.width-10)/4
- (void)fillWithImage:(PHAsset *)asset isSelected:(BOOL)seleted {
    self.phAsset = asset;
    self.isSelected = seleted;
    
    PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
    opt.resizeMode = PHImageRequestOptionsResizeModeFast;
    opt.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    opt.synchronous = YES;
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(kSizeThumbnailCollectionView, kSizeThumbnailCollectionView) contentMode:PHImageContentModeAspectFill options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            self.imageView.image = result;
        }
    }];
    
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        [self setVedioViewHiden:NO];
        _checkButton.hidden = _checkImageView.hidden = YES;
        NSString *duration = [NSString string];
        double time = ceilf(asset.duration);
        NSInteger min = time / 60;
        NSInteger second = (int)time % 60;
        NSString *minStr = [NSString string];
        if (min < 10) {
            minStr = [NSString stringWithFormat:@"0%zd",min];
        } else {
            minStr = [NSString stringWithFormat:@"%zd",min];
        }
        if (second < 10) {
            duration = [NSString stringWithFormat:@"%@:0%zd",minStr,second];
        } else {
            duration = [NSString stringWithFormat:@"%@:%zd",minStr,second];
        }
        _vedioDurationLabel.text = duration;
    } else {
        [self setVedioViewHiden:YES];
        _checkButton.hidden = _checkImageView.hidden = NO;
    }
}

- (void)setVedioViewHiden:(BOOL)hiden {
    if (_vedioImage) {
        _vedioImage.hidden = hiden;
        _vedioDurationLabel.hidden = hiden;
    }
}



- (void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    self.checkButton.selected = _isSelected;
    [self updateCheckImageView];
}

- (void)setIsSelectedImage:(BOOL)isSelectedImage {
    _isSelectedImage = isSelectedImage;
//    if (self.phAsset.mediaType == PHAssetMediaTypeImage) {
//        _coverView.hidden = YES;
//        return;
//    }
//    
//    if (isSelectedImage) {
//        _coverView.hidden = NO;
//    } else {
//        _coverView.hidden = YES;
//    }
}

- (void)updateCheckImageView
{
    if (self.checkButton.selected) {
        self.checkImageView.image = [UIImage imageNamed:@"photo_check_selected"];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.checkImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:0.2 animations:^{
                                 self.checkImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                             }];
                         }];
    } else {
        self.checkImageView.image = [UIImage imageNamed:@"photo_check_default"];
    }
}

- (void)checkButtonAction:(id)sender
{
    if (self.checkButton.selected) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didDeselectItemAssetsViewCell:)]) {
            [self.delegate didDeselectItemAssetsViewCell:self];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectItemAssetsViewCell:)]) {
            [self.delegate didSelectItemAssetsViewCell:self];
        }
    }
}

- (void)prepareForReuse
{
    _isSelected = NO;
    _delegate = nil;
    _imageView.image = nil;
}

- (void)layoutSubviews {
    CGSize durationSize = [_vedioDurationLabel.text sizeWithFont:[UIFont systemFontOfSize:13] maxSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    _vedioDurationLabel.frame = CGRectMake(CGRectGetWidth(self.frame) - durationSize.width , CGRectGetHeight(self.frame) - durationSize.height, durationSize.width, durationSize.height);
    
    _coverView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}

#pragma mark - Getter
- (UIImageView *)imageView
{
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [_imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        _imageView.image = [UIImage imageNamed:@"Image_placeHolder"];
        [self addSubview:_imageView];
    }
    return _imageView;
}

- (UIButton *)checkButton
{
    if (_checkButton == nil) {
        _checkButton = [UIButton buttonWithType:UIButtonTypeCustom];

        [_checkButton addTarget:self action:@selector(checkButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_checkButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:_checkButton];
    }
    return _checkButton;
}

- (UIImageView *)checkImageView
{
    if (_checkImageView == nil) {
        _checkImageView = [UIImageView new];
        _checkImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_checkImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:_checkImageView];
    }
    return _checkImageView;
}

- (UIView *)vedioView {
    if (!_vedioImage) {
        CGFloat width = ([UIScreen mainScreen].bounds.size.width-10)/4;
        _vedioImage = [[UIImageView alloc] initWithFrame:CGRectMake((width - 35) * 0.5, (width - 35) * 0.5, 35, 35)];
        _vedioImage.image = [UIImage imageNamed:@"Discover_Vedio_PlayBtn"];
//        [self addSubview:_vedioImage];
    }
    return _vedioImage;
}

- (UILabel *)vedioDurationLabel {
    if (!_vedioDurationLabel) {
        _vedioDurationLabel = [[UILabel alloc] init];
        _vedioDurationLabel.textColor = [UIColor whiteColor];
        _vedioDurationLabel.font = [UIFont systemFontOfSize:13];
        _vedioDurationLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_vedioDurationLabel];
    }
    return _vedioDurationLabel;
}

- (UIView *)coverView {
    if (!_coverView) {
        _coverView = [UIView new];
        _coverView.hidden = YES;
        _coverView.backgroundColor = [UIColor clearColor];
        [self addSubview:_coverView];
    }
    return _coverView;
}

@end
