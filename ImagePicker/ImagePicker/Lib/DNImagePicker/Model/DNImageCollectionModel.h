//
//  DNImageCollectionModel.h
//  ZhiMaBaoBao
//
//  Created by mac on 17/4/10.
//  Copyright © 2017年 liugang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface DNImageCollectionModel : NSObject

@property (nonatomic, strong) PHAssetCollection *collection;

@property (nonatomic, copy) NSString *collectionTitle;


@end
