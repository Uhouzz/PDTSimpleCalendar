//
//  NSDate+PDTCompare.h
//  PDTSimpleCalendarDemo
//
//  Created by Tony on 16/11/29.
//  Copyright © 2016年 Producteev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (PDTCompare)
- (NSComparisonResult)compareDateByDay:(NSDate *)date;

- (BOOL)isLaterThanOrEqual:(NSDate *)date;

- (BOOL)isLaterThan:(NSDate *)date;

- (BOOL)isEarlierOrEqual:(NSDate *)date;

- (BOOL)isEarlierThan:(NSDate *)date;

- (BOOL)isEqualTo:(NSDate *)date;

- (BOOL)currentDateIsBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;

- (NSArray *)dateArrayBeetwenEndDate:(NSDate *)endDate;
@end
