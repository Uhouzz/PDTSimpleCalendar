//
//  PDTSimpleCalendarViewFlowLayout.m
//  PDTSimpleCalendar
//
//  Created by Jerome Miglino on 10/7/13.
//  Copyright (c) 2013 Producteev. All rights reserved.
//

#import "PDTSimpleCalendarViewFlowLayout.h"

const CGFloat PDTSimpleCalendarFlowLayoutMinInterItemSpacing = 0.0f;
const CGFloat PDTSimpleCalendarFlowLayoutMinLineSpacing = 0.0f;
const CGFloat PDTSimpleCalendarFlowLayoutInsetTop = 5.0f;
const CGFloat PDTSimpleCalendarFlowLayoutInsetLeft = 2.0f;
const CGFloat PDTSimpleCalendarFlowLayoutInsetBottom = 5.0f;
const CGFloat PDTSimpleCalendarFlowLayoutInsetRight = 2.0f;
const CGFloat PDTSimpleCalendarFlowLayoutHeaderHeight = 50.0f;

@implementation PDTSimpleCalendarViewFlowLayout

-(id)init
{
    self = [super init];
    if (self) {
        self.minimumInteritemSpacing = PDTSimpleCalendarFlowLayoutMinInterItemSpacing;
        self.minimumLineSpacing = PDTSimpleCalendarFlowLayoutMinLineSpacing;
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.sectionInset = UIEdgeInsetsMake(PDTSimpleCalendarFlowLayoutInsetTop,
                                             PDTSimpleCalendarFlowLayoutInsetLeft,
                                             PDTSimpleCalendarFlowLayoutInsetBottom,
                                             PDTSimpleCalendarFlowLayoutInsetRight);
        self.headerReferenceSize = CGSizeMake(0, PDTSimpleCalendarFlowLayoutHeaderHeight);
        
        //Note: Item Size is defined using the delegate to take into account the width of the view and calculate size dynamically
    }

    return self;
}

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *answer = [super layoutAttributesForElementsInRect:rect];
    
    for(int i = 1; i < [answer count]; ++i) {
        UICollectionViewLayoutAttributes *currentLayoutAttributes = answer[i];
        UICollectionViewLayoutAttributes *prevLayoutAttributes = answer[i - 1];
        NSInteger maximumSpacing = 0.0;
        NSInteger origin = CGRectGetMaxX(prevLayoutAttributes.frame);
        
        if(origin + maximumSpacing + currentLayoutAttributes.frame.size.width < self.collectionViewContentSize.width) {
            CGRect frame = currentLayoutAttributes.frame;
            frame.origin.x = origin + maximumSpacing;
            currentLayoutAttributes.frame = frame;
        }
    }
    return answer;
}

@end
