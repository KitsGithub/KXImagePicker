//
//  DNAlbumTableViewCell.h
//  ZhiMaBaoBao
//
//  Created by mac on 17/4/10.
//  Copyright © 2017年 liugang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DNImageCollectionModel.h"
#import "DNImagePickerHeader.h"

@interface DNAlbumTableViewCell : UITableViewCell

@property (nonatomic, assign) DNImagePickerFilterType filterType;

@property (nonatomic, weak) DNImageCollectionModel *model;

@end
