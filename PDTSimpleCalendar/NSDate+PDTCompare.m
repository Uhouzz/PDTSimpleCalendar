//
//  NSDate+PDTCompare.m
//  PDTSimpleCalendarDemo
//
//  Created by Tony on 16/11/29.
//  Copyright © 2016年 Producteev. All rights reserved.
//

#import "NSDate+PDTCompare.h"

@implementation NSDate (PDTCompare)
-(NSComparisonResult)compareDateByDay:(NSDate *)date{
    
    NSDate *fromDate=[self formatDateByComponent:self];
    NSDate *toDate=[self formatDateByComponent:date];
    
    NSComparisonResult result=[fromDate compare:toDate];
    switch (result) {
        case NSOrderedAscending: {
            return NSOrderedAscending;
            break;
        }
        case NSOrderedSame: {
            return NSOrderedSame;
            break;
        }
        case NSOrderedDescending: {
            return NSOrderedDescending;
            break;
        }
    }
}

-(BOOL)isLaterThanOrEqual:(NSDate *)date{
    NSDate *fromDate=[self formatDateByComponent:self];
    NSDate *toDate=[self formatDateByComponent:date];
    return !([fromDate compare:toDate]==NSOrderedAscending);
}

-(BOOL)isLaterThan:(NSDate *)date{
    NSDate *fromDate=[self formatDateByComponent:self];
    NSDate *toDate=[self formatDateByComponent:date];
    return ([fromDate compare:toDate]==NSOrderedDescending);
}

-(BOOL)isEarlierOrEqual:(NSDate *)date{
    NSDate *fromDate=[self formatDateByComponent:self];
    NSDate *toDate=[self formatDateByComponent:date];
    return !([fromDate compare:toDate]==NSOrderedDescending);
}

-(BOOL)isEarlierThan:(NSDate *)date{
    NSDate *fromDate=[self formatDateByComponent:self];
    NSDate *toDate=[self formatDateByComponent:date];
    return ([fromDate compare:toDate]==NSOrderedAscending);
}

-(BOOL)isEqualTo:(NSDate *)date{
    NSDate *fromDate=[self formatDateByComponent:self];
    NSDate *toDate=[self formatDateByComponent:date];
    return ([fromDate compare:toDate]==NSOrderedSame);
}

- (BOOL)isBeetwenEndDate:(NSDate *)endDate{
    if ([endDate compare:self] == NSOrderedAscending)
        return NO;
    
    if ([self compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

- (BOOL)currentDateIsBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([self compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([self compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

- (NSArray *)dateArrayBeetwenEndDate:(NSDate *)endDate{
    NSMutableArray *dateArray = [NSMutableArray array];
    NSDate *curDate = self;
    while([curDate timeIntervalSince1970] <= [endDate timeIntervalSince1970]) //you can also use the earlier-method
    {
        [dateArray addObject:curDate];
        curDate = [NSDate dateWithTimeInterval:86400 sinceDate:curDate]; //86400 = 60*60*24
    }
    return [dateArray copy];
}

#pragma mark - private

-(NSDate *)formatDateByComponent:(NSDate *)date{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    return [cal dateFromComponents:components];
}

@end
