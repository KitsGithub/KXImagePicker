//
//  NSDate+TimeCategory.m
//  ZhiMaBaoBao
//
//  Created by liugang on 16/9/27.
//  Copyright © 2016年 liugang. All rights reserved.
//

#import "NSDate+TimeCategory.h"

static NSDateFormatter *dateFormatter;

@implementation NSDate (TimeCategory)

+(NSDateFormatter *)defaultFormatter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc]init];
    });
    return dateFormatter;
}

+ (NSDate *)dateFromString:(NSString *)timeStr
                    format:(NSString *)format
{
    NSDateFormatter *dateFormatter = [NSDate defaultFormatter];
    [dateFormatter setDateFormat:format];
    NSDate *date = [dateFormatter dateFromString:timeStr];
    return date;
}

+ (long long)cTimestampFromDate:(NSDate *)date
{
    long long recordTime = [date timeIntervalSince1970]*1000;
    return recordTime;
}


+(long long)cTimestampFromString:(NSString *)timeStr
                          format:(NSString *)format
{
    NSDate *date = [NSDate dateFromString:timeStr format:format];
    return [NSDate cTimestampFromDate:date];
}

+ (NSString *)dateStrFromCstampTime:(long long)timeStamp
                     withDateFormat:(NSString *)format
{
    long time = 0;
    if ([NSString stringWithFormat:@"%lld",timeStamp].length == 10) {
        time = timeStamp;
    }else{
        time = timeStamp/1000;
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    return [NSDate datestrFromDate:date withDateFormat:format];
}

+ (NSString *)datestrFromDate:(NSDate *)date
               withDateFormat:(NSString *)format
{
    NSDateFormatter* dateFormat = [NSDate defaultFormatter];
    [dateFormat setDateFormat:format];
    return [dateFormat stringFromDate:date];
}

+ (long long)currentTimeStamp{
    NSDate *date = [NSDate date];
    return [NSDate cTimestampFromDate:date];
}

//计算时间
+ (NSString *)fullDescription:(long long)timeStamp{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp/1000];
    NSDate *currentDate = [NSDate date];
    //今天
    if ([calendar isDateInToday:date]) {
        int delta = [currentDate timeIntervalSinceDate:date];
        if (delta < 60) {
            return @"刚刚";
        }
        if (delta < 3600) {
            return [NSString stringWithFormat:@"%d分钟前",(delta/60)];
        }
        return [NSString stringWithFormat:@"%d小时前",(delta/3600)];
    }
    
    //昨天
    if ([calendar isDateInYesterday:currentDate]) {
        df.dateFormat = @"昨天 HH:mm";
        return [df stringFromDate:currentDate];
    }
    
    NSDateComponents *component = [calendar components:NSCalendarUnitYear fromDate:currentDate toDate:date options:NSCalendarWrapComponents];
    
    if (component.year == 0) {
        df.dateFormat = @"MM-dd";
        return [df stringFromDate:date];
    }
    
    df.dateFormat = @"yyyy-MM-dd HH:mm";
    return [df stringFromDate:date];
}

@end
