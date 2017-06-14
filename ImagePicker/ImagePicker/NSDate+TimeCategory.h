//
//  NSDate+TimeCategory.h
//  ZhiMaBaoBao
//
//  Created by liugang on 16/9/27.
//  Copyright © 2016年 liugang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (TimeCategory)

/**
 *  字符串转NSDate
 *
 *  @param theTime 字符串时间
 *  @param format  转化格式 如yyyy-MM-dd HH:mm:ss,即2015-07-15 15:00:00
 *
 *  @return <#return value description#>
 */
+ (NSDate *)dateFromString:(NSString *)timeStr
                    format:(NSString *)format;

/**
 *  NSDate转时间戳
 *
 *  @param date 字符串时间
 *
 *  @return 返回时间戳
 */
+ (long long)cTimestampFromDate:(NSDate *)date;

/**
 *  字符串转时间戳
 *
 *  @param theTime 字符串时间
 *  @param format  转化格式 如yyyy-MM-dd HH:mm:ss,即2015-07-15 15:00:00
 *
 *  @return 返回时间戳的字符串
 */
+(long long)cTimestampFromString:(NSString *)timeStr
                          format:(NSString *)format;


/**
 *  时间戳转字符串
 *
 *  @param timeStamp 时间戳
 *  @param format    转化格式 如yyyy-MM-dd HH:mm:ss,即2015-07-15 15:00:00
 *
 *  @return 返回字符串格式时间
 */
+ (NSString *)dateStrFromCstampTime:(long long)timeStamp
                     withDateFormat:(NSString *)format;

/**
 *  NSDate转字符串
 *
 *  @param date   NSDate时间
 *  @param format 转化格式 如yyyy-MM-dd HH:mm:ss,即2015-07-15 15:00:00
 *
 *  @return 返回字符串格式时间
 */
+ (NSString *)datestrFromDate:(NSDate *)date
               withDateFormat:(NSString *)format;

/**
 *  获取当前时间戳
 */
+ (long long)currentTimeStamp;

//计算时间
+ (NSString *)fullDescription:(long long)timeStamp;


@end
