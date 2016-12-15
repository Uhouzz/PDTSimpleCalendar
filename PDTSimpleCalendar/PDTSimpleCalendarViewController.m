//
//  PDTSimpleCalendarViewController.m
//  PDTSimpleCalendar
//
//  Created by Jerome Miglino on 10/7/13.
//  Copyright (c) 2013 Producteev. All rights reserved.
//

#import "PDTSimpleCalendarViewController.h"

#import "PDTSimpleCalendarViewFlowLayout.h"
#import "PDTSimpleCalendarViewCell.h"
#import "PDTSimpleCalendarViewHeader.h"
#import "NSDate+PDTCompare.h"

const CGFloat PDTSimpleCalendarOverlaySize = 14.0f;

static NSString *const PDTSimpleCalendarViewCellIdentifier = @"com.producteev.collection.cell.identifier";
static NSString *const PDTSimpleCalendarViewHeaderIdentifier = @"com.producteev.collection.header.identifier";
static const NSCalendarUnit kCalendarUnitYMD = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;

@interface PDTSimpleCalendarViewController () <PDTSimpleCalendarViewCellDelegate>

@property (nonatomic, strong) NSDateFormatter *headerDateFormatter; //Will be used to format date in header view and on scroll.

@property (nonatomic, strong) PDTSimpleCalendarViewWeekdayHeader *weekdayHeader;

// First and last date of the months based on the public properties first & lastDate
@property (nonatomic) NSDate *firstDateMonth;
@property (nonatomic) NSDate *lastDateMonth;
@property (nonatomic) NSMutableArray *bengEndDateArray;
@property (nonatomic) NSMutableArray *selectedDateArray;

//Number of days per week
@property (nonatomic, assign) NSUInteger daysPerWeek;

@end


@implementation PDTSimpleCalendarViewController

//Explicitly @synthesize the var (it will create the iVar for us automatically as we redefine both getter and setter)
@synthesize firstDate = _firstDate;
@synthesize lastDate = _lastDate;
@synthesize calendar = _calendar;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    //Force the creation of the view with the pre-defined Flow Layout.
    //Still possible to define a custom Flow Layout, if needed by using initWithCollectionViewLayout:
    self = [super initWithCollectionViewLayout:[[PDTSimpleCalendarViewFlowLayout alloc] init]];
    if (self) {
        // Custom initialization
        [self simpleCalendarCommonInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    //Force the creation of the view with the pre-defined Flow Layout.
    //Still possible to define a custom Flow Layout, if needed by using initWithCollectionViewLayout:
    self = [super initWithCollectionViewLayout:[[PDTSimpleCalendarViewFlowLayout alloc] init]];
    if (self) {
        // Custom initialization
        [self simpleCalendarCommonInit];
    }
    
    return self;
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        [self simpleCalendarCommonInit];
    }

    return self;
}

- (void)simpleCalendarCommonInit
{
    self.backgroundColor = [UIColor whiteColor];
    self.daysPerWeek = 7;
    self.weekdayHeaderEnabled = NO;
    self.weekdayTextType = PDTSimpleCalendarViewWeekdayTextTypeVeryShort;
    self.selectedDateArray = [NSMutableArray arrayWithCapacity:0];
    self.bengEndDateArray = [NSMutableArray arrayWithCapacity:0];
}

#pragma mark - View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.selectedDate) {
        [self.collectionViewLayout invalidateLayout];
    }
}

#pragma mark - Accessors

- (NSDateFormatter *)headerDateFormatter;
{
    if (!_headerDateFormatter) {
        _headerDateFormatter = [[NSDateFormatter alloc] init];
        _headerDateFormatter.calendar = self.calendar;
        _headerDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyy LLLL" options:0 locale:self.calendar.locale];
    }
    return _headerDateFormatter;
}

- (NSCalendar *)calendar
{
    if (!_calendar) {
        [self setCalendar:[NSCalendar currentCalendar]];
    }
    return _calendar;
}

-(void)setCalendar:(NSCalendar*)calendar
{
    _calendar = calendar;
    self.headerDateFormatter.calendar = calendar;
    self.daysPerWeek = [_calendar maximumRangeOfUnit:NSCalendarUnitWeekday].length;
}

- (NSDate *)firstDate
{
    if (!_firstDate) {
        NSDateComponents *components = [self.calendar components:kCalendarUnitYMD
                                                        fromDate:[NSDate date]];
        components.day = 1;
        _firstDate = [self.calendar dateFromComponents:components];
    }

    return _firstDate;
}

- (void)setFirstDate:(NSDate *)firstDate
{
    _firstDate = [self clampDate:firstDate toComponents:kCalendarUnitYMD];
}

- (NSDate *)firstDateMonth
{
    if (_firstDateMonth) { return _firstDateMonth; }

    NSDateComponents *components = [self.calendar components:kCalendarUnitYMD
                                                    fromDate:self.firstDate];
    components.day = 1;

    _firstDateMonth = [self.calendar dateFromComponents:components];

    return _firstDateMonth;
}

- (NSDate *)lastDate
{
    if (!_lastDate) {
        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
        offsetComponents.year = 1;
        offsetComponents.day = -1;
        [self setLastDate:[self.calendar dateByAddingComponents:offsetComponents toDate:self.firstDateMonth options:0]];
    }

    return _lastDate;
}

- (void)setLastDate:(NSDate *)lastDate
{
    _lastDate = [self clampDate:lastDate toComponents:kCalendarUnitYMD];
}

- (NSDate *)lastDateMonth
{
    if (_lastDateMonth) { return _lastDateMonth; }

    NSDateComponents *components = [self.calendar components:kCalendarUnitYMD
                                                    fromDate:self.lastDate];
    components.month++;
    components.day = 0;

    _lastDateMonth = [self.calendar dateFromComponents:components];

    return _lastDateMonth;
}


- (void)removeSelectedDate{
    NSDate *startDate = [self.bengEndDateArray firstObject];
    NSDate *endDate = [self.bengEndDateArray lastObject];
    for (NSDate *date in self.selectedDateArray ) {
        PDTSimpleCalendarViewCell * cell = [self cellForItemAtDate:date];
        [cell setSelected:NO];
        if (![startDate isEqualToDate:endDate]) {
            [self.bengEndDateArray removeAllObjects];
        }
    }
}

- (void)setSelectedDate:(NSDate *)newSelectedDate
{
    //if newSelectedDate is nil, unselect the current selected cell
    if (!newSelectedDate) {
        [[self cellForItemAtDate:_selectedDate] setSelected:NO];
        _selectedDate = newSelectedDate;

        return;
    }

    //Test if selectedDate between first & last date
    NSDate *startOfDay = [self clampDate:newSelectedDate toComponents:kCalendarUnitYMD];
    if (([startOfDay compare:self.firstDateMonth] == NSOrderedAscending) || ([startOfDay compare:self.lastDateMonth] == NSOrderedDescending)) {
        //the newSelectedDate is not between first & last date of the calendar, do nothing.
        return;
    }

    PDTSimpleCalendarViewCell * cell = [self cellForItemAtDate:_selectedDate];
    if (_selectedDate && [_selectedDate isLaterThan:newSelectedDate]) {
        [self.bengEndDateArray removeAllObjects];
        [cell setSelected:NO];
    }

    [self removeSelectedDate];

    
    _selectedDate = startOfDay;
    
    [self.bengEndDateArray addObject:_selectedDate];
    NSDate *startDate = [self.bengEndDateArray firstObject];
    NSDate *endDate = [self.bengEndDateArray lastObject];
    
    self.selectedDateArray = [NSMutableArray arrayWithArray:[startDate dateArrayBeetwenEndDate:endDate]];
    
    
    if (![endDate isEqual:startDate] && [endDate isEarlierThan:startDate]) {
        [[self cellForItemAtDate:startDate] setSelected:NO];
    }
    
    for (NSDate *date in self.selectedDateArray ) {
        PDTSimpleCalendarViewCell * cell = [self cellForItemAtDate:date];
        cell.isEndday = [date isEqualToDate:endDate];
        cell.isSameday = [endDate isEqualToDate:startDate];
        cell.isStarday = [date isEqualToDate:startDate];
        [cell setSelected:YES];
    }
    
    NSIndexPath *indexPath = [self indexPathForCellAtDate:_selectedDate];
    [self.collectionView reloadItemsAtIndexPaths:@[ indexPath ]];

    BOOL isBegin = self.selectedDateArray.count == 1 ? YES : NO;
    
    //Notify the delegate
    if ([self.delegate respondsToSelector:@selector(simpleCalendarViewController:didSelectDate:beginDate:)]) {
        [self.delegate simpleCalendarViewController:self didSelectDate:self.selectedDate beginDate:isBegin];
    }
}

- (void) setupDefaultSelectedData {
    
    if (!self.selectedBeginDate || !self.selectedEndDate) {
        return;
    }
    
    _selectedDate = self.selectedEndDate;
    
    [self.bengEndDateArray removeAllObjects];
    [self.bengEndDateArray addObject:self.selectedBeginDate];
    [self.bengEndDateArray addObject:self.selectedEndDate];
    
    self.selectedDateArray = [NSMutableArray arrayWithArray:[self.selectedBeginDate dateArrayBeetwenEndDate:self.selectedEndDate]];
    
    for (NSDate *date in self.selectedDateArray ) {
        PDTSimpleCalendarViewCell * cell = [self cellForItemAtDate:date];
        cell.isEndday = [date isEqualToDate:self.selectedEndDate];
        cell.isSameday = [self.selectedEndDate isEqualToDate:self.selectedBeginDate];
        cell.isStarday = [date isEqualToDate:self.selectedBeginDate];
        [cell setSelected:YES];
    }

    NSIndexPath *indexPath = [self indexPathForCellAtDate:_selectedDate];
    [self.collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
    
    if ([self.delegate respondsToSelector:@selector(simpleCalendarViewController:didSelectDate:beginDate:)]) {
        [self.delegate simpleCalendarViewController:self didSelectDate:self.selectedBeginDate beginDate:YES];
        [self.delegate simpleCalendarViewController:self didSelectDate:self.selectedEndDate beginDate:NO];
    }
    
    [self scrollToDate:self.selectedBeginDate animated:NO];
}

#pragma mark - Scroll to a specific date

- (void)scrollToSelectedDate:(BOOL)animated
{
    if (_selectedDate) {
        [self scrollToDate:_selectedDate animated:animated];
    }
}

- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated
{
    @try {
        NSIndexPath *selectedDateIndexPath = [self indexPathForCellAtDate:date];

        if (![[self.collectionView indexPathsForVisibleItems] containsObject:selectedDateIndexPath]) {
            //First, tried to use [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:selectedDateIndexPath]; but it causes the header to be redraw multiple times (X each time you use scrollToDate:)
            //TODO: Investigate & eventually file a radar.

            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathForItem:0 inSection:selectedDateIndexPath.section];
            UICollectionViewLayoutAttributes *sectionLayoutAttributes = [self.collectionView layoutAttributesForItemAtIndexPath:sectionIndexPath];
            CGPoint origin = sectionLayoutAttributes.frame.origin;
            origin.x = 0;
            origin.y -= (PDTSimpleCalendarFlowLayoutHeaderHeight + PDTSimpleCalendarFlowLayoutInsetTop + self.collectionView.contentInset.top);
            [self.collectionView setContentOffset:origin animated:animated];
        }
    }
    @catch (NSException *exception) {
        //Exception occured (it should not according to the documentation, but in reality...) let's scroll to the IndexPath then
        NSInteger section = [self sectionForDate:date];
        NSIndexPath *sectionIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        [self.collectionView scrollToItemAtIndexPath:sectionIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:animated];
    }
}

#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //Configure the Collection View
    [self.collectionView registerClass:[PDTSimpleCalendarViewCell class] forCellWithReuseIdentifier:PDTSimpleCalendarViewCellIdentifier];
    [self.collectionView registerClass:[PDTSimpleCalendarViewHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PDTSimpleCalendarViewHeaderIdentifier];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView setBackgroundColor:self.backgroundColor];
    
    //Configure the Weekday Header
    self.weekdayHeader = [[PDTSimpleCalendarViewWeekdayHeader alloc] initWithCalendar:self.calendar weekdayTextType:self.weekdayTextType];
    
    [self.view addSubview:self.weekdayHeader];
    [self.weekdayHeader setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSInteger weekdayHeaderHeight = self.weekdayHeaderEnabled ? PDTSimpleCalendarWeekdayHeaderHeight : 0;
    self.weekdayHeader.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), weekdayHeaderHeight);
    
    NSDictionary *viewsDic = @{@"weekdayHeader": self.weekdayHeader};
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerViewWithSimpleCalendarViewController:)]) {
        UIView *headerView = [self.delegate headerViewWithSimpleCalendarViewController:self];
        if (headerView) {
            [self.view addSubview:headerView];
            headerView.frame = CGRectMake(0, 0, CGRectGetWidth(headerView.frame), CGRectGetHeight(headerView.frame));
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[weekdayHeader]|" options:NSLayoutFormatAlignAllTop metrics:nil views:viewsDic]];
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topHeight-[weekdayHeader(weekdayHeaderHeight)]"
                                                                              options:NSLayoutFormatAlignAllTop metrics:@{@"topHeight":@(CGRectGetMaxY(headerView.frame)),@"weekdayHeaderHeight": @(weekdayHeaderHeight)}
                                                                                views:viewsDic]];
            
            [self.collectionView setContentInset:UIEdgeInsetsMake(CGRectGetHeight(headerView.frame) + weekdayHeaderHeight, 0, 0, 0)];
        }
    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[weekdayHeader]|" options:NSLayoutFormatAlignAllTop metrics:nil views:viewsDic]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[weekdayHeader(weekdayHeaderHeight)]"
                                                                          options:NSLayoutFormatAlignAllTop metrics:@{@"weekdayHeaderHeight": @(weekdayHeaderHeight)}
                                                                            views:viewsDic]];
        [self.collectionView setContentInset:UIEdgeInsetsMake(weekdayHeaderHeight, 0, 0, 0)];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(bottomViewWithSimpleCalendarViewController:)]) {
        UIView *bottomView = [self.delegate bottomViewWithSimpleCalendarViewController:self];
        
        if (bottomView) {
            [self.view addSubview:bottomView];
            bottomView.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - CGRectGetHeight(bottomView.frame), CGRectGetWidth(bottomView.frame), CGRectGetHeight(bottomView.frame));
            [self.collectionView setContentInset:UIEdgeInsetsMake(self.collectionView.contentInset.top, 0, CGRectGetHeight(bottomView.frame) + 30, 0)];
        }
    }
    
    [self setupDefaultSelectedData];
}

- (void)resetSelectedDate {
    [self removeSelectedDate];
    self.selectedDate = nil;
    [self.selectedDateArray removeAllObjects];
    [self.bengEndDateArray removeAllObjects];
}

#pragma mark - Rotation Handling

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.collectionView.collectionViewLayout invalidateLayout];
}


#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    //Each Section is a Month
    return [self.calendar components:NSCalendarUnitMonth fromDate:self.firstDateMonth toDate:self.lastDateMonth options:0].month + 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSDate *firstOfMonth = [self firstOfMonthForSection:section];
    NSCalendarUnit weekCalendarUnit = [self weekCalendarUnitDependingOniOSVersion];
    NSRange rangeOfWeeks = [self.calendar rangeOfUnit:weekCalendarUnit inUnit:NSCalendarUnitMonth forDate:firstOfMonth];

    //We need the number of calendar weeks for the full months (it will maybe include previous month and next months cells)
    return (rangeOfWeeks.length * self.daysPerWeek);
}

/**
 * https://github.com/jivesoftware/PDTSimpleCalendar/issues/69
 * On iOS7, using NSCalendarUnitWeekOfMonth (or WeekOfYear) in rangeOfUnit:inUnit is returning NSNotFound, NSNotFound
 * Fun stuff, definition of NSNotFound is enum {NSNotFound = NSIntegerMax};
 * So on iOS7, we're trying to allocate NSIntegerMax * 7 cells per Section
 *
 * //TODO: Remove when removing iOS7 Support
 *
 *  @return the proper NSCalendarUnit to use in rangeOfUnit:inUnit
 */
- (NSCalendarUnit)weekCalendarUnitDependingOniOSVersion {
    //isDateInToday is a new (awesome) method available on iOS8 only.
    if ([self.calendar respondsToSelector:@selector(isDateInToday:)]) {
        return NSCalendarUnitWeekOfMonth;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return NSWeekCalendarUnit;
#pragma clang diagnostic pop
    }
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDTSimpleCalendarViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:PDTSimpleCalendarViewCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.delegate = self;
    
    NSDate *firstOfMonth = [self firstOfMonthForSection:indexPath.section];
    NSDate *cellDate = [self dateForCellAtIndexPath:indexPath];
    NSDate *startDate = [self.bengEndDateArray firstObject];
    NSDate *endDate = [self.bengEndDateArray lastObject];

    NSDateComponents *cellDateComponents = [self.calendar components:kCalendarUnitYMD fromDate:cellDate];
    NSDateComponents *firstOfMonthsComponents = [self.calendar components:kCalendarUnitYMD fromDate:firstOfMonth];

    BOOL isToday = NO;
    BOOL isSelected = NO;
    BOOL isCustomDate = NO;
    BOOL isStartday = NO;
    BOOL isEndday = NO;

    if (cellDateComponents.month == firstOfMonthsComponents.month) {
        isSelected = ([self isSelectedDate:cellDate] && (indexPath.section == [self sectionForDate:cellDate]));
//        isToday = [self isTodayDate:cellDate];
        isStartday = [cellDate isEqualToDate:startDate];
        isEndday = [cellDate isEqualToDate:endDate];
        [cell setDate:cellDate calendar:self.calendar];

        //Ask the delegate if this date should have specific colors.
        if ([self.delegate respondsToSelector:@selector(simpleCalendarViewController:shouldUseCustomColorsForDate:)]) {
            isCustomDate = [self.delegate simpleCalendarViewController:self shouldUseCustomColorsForDate:cellDate];
        }


    } else {
        [cell setDate:nil calendar:nil];
    }
    
    if (isToday) {
        [cell setIsToday:isToday];
    }
    
    if (isStartday) {
        [cell setIsStarday:isStartday];
    }
    
    if (isEndday) {
        [cell setIsEndday:isEndday];
    }
    
    [cell setIsSameday:[startDate isEqualToDate:endDate]];

    if (isSelected) {
        [cell setSelected:isSelected];
    }
    
    [cell setSelected:[self.selectedDateArray containsObject:cellDate]];
    
    if (cellDateComponents.month != firstOfMonthsComponents.month) {
        [cell setSelected:NO];
    }
    //If the current Date is not enabled, or if the delegate explicitely specify custom colors
    if (![self isEnabledDate:cellDate] || isCustomDate) {
        [cell refreshCellColors];
    }

    //We rasterize the cell for performances purposes.
    //The circle background is made using roundedCorner which is a super expensive operation, specially with a lot of items on the screen to display (like we do)
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *firstOfMonth = [self firstOfMonthForSection:indexPath.section];
    NSDate *cellDate = [self dateForCellAtIndexPath:indexPath];

    //We don't want to select Dates that are "disabled"
    if (![self isEnabledDate:cellDate]) {
        return NO;
    }

    NSDateComponents *cellDateComponents = [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth fromDate:cellDate];
    NSDateComponents *firstOfMonthsComponents = [self.calendar components:NSCalendarUnitMonth fromDate:firstOfMonth];

    return (cellDateComponents.month == firstOfMonthsComponents.month);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedDate = [self dateForCellAtIndexPath:indexPath];
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        PDTSimpleCalendarViewHeader *headerView = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PDTSimpleCalendarViewHeaderIdentifier forIndexPath:indexPath];

        headerView.titleLabel.text = [self.headerDateFormatter stringFromDate:[self firstOfMonthForSection:indexPath.section]].uppercaseString;

        headerView.layer.shouldRasterize = YES;
        headerView.layer.rasterizationScale = [UIScreen mainScreen].scale;

        return headerView;
    }

    return nil;
}

#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat itemWidth = floorf(CGRectGetWidth(self.collectionView.bounds) / self.daysPerWeek);

    return CGSizeMake(itemWidth, itemWidth);
}

#pragma mark -
#pragma mark - Calendar calculations

- (NSDate *)clampDate:(NSDate *)date toComponents:(NSUInteger)unitFlags
{
    NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];
    return [self.calendar dateFromComponents:components];
}

- (BOOL)isTodayDate:(NSDate *)date
{
    return [self clampAndCompareDate:date withReferenceDate:[NSDate date]];
}

- (BOOL)isSelectedDate:(NSDate *)date
{
    if (!self.selectedDate) {
        return NO;
    }
    return [self clampAndCompareDate:date withReferenceDate:self.selectedDate];
}

- (BOOL)isEnabledDate:(NSDate *)date
{
    NSDate *clampedDate = [self clampDate:date toComponents:kCalendarUnitYMD];
    if (([clampedDate compare:self.firstDate] == NSOrderedAscending) || ([clampedDate compare:self.lastDate] == NSOrderedDescending)) {
        return NO;
    }

    if ([self.delegate respondsToSelector:@selector(simpleCalendarViewController:isEnabledDate:)]) {
        return [self.delegate simpleCalendarViewController:self isEnabledDate:date];
    }

    return YES;
}

- (BOOL)clampAndCompareDate:(NSDate *)date withReferenceDate:(NSDate *)referenceDate
{
    NSDate *refDate = [self clampDate:referenceDate toComponents:kCalendarUnitYMD];
    NSDate *clampedDate = [self clampDate:date toComponents:kCalendarUnitYMD];

    return [refDate isEqualToDate:clampedDate];
}

#pragma mark - Collection View / Calendar Methods

- (NSDate *)firstOfMonthForSection:(NSInteger)section
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.month = section;

    return [self.calendar dateByAddingComponents:offset toDate:self.firstDateMonth options:0];
}

- (NSInteger)sectionForDate:(NSDate *)date
{
    return [self.calendar components:NSCalendarUnitMonth fromDate:self.firstDateMonth toDate:date options:0].month;
}


- (NSDate *)dateForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *firstOfMonth = [self firstOfMonthForSection:indexPath.section];

    NSUInteger weekday = [[self.calendar components: NSCalendarUnitWeekday fromDate: firstOfMonth] weekday];
    NSInteger startOffset = weekday - self.calendar.firstWeekday;
    startOffset += startOffset >= 0 ? 0 : self.daysPerWeek;

    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.day = indexPath.item - startOffset;

    return [self.calendar dateByAddingComponents:dateComponents toDate:firstOfMonth options:0];
}


static const NSInteger kFirstDay = 1;
- (NSIndexPath *)indexPathForCellAtDate:(NSDate *)date
{
    if (!date) {
        return nil;
    }
    NSInteger section = [self sectionForDate:date];
    NSDate *firstOfMonth = [self firstOfMonthForSection:section];

    NSInteger weekday = [[self.calendar components: NSCalendarUnitWeekday fromDate: firstOfMonth] weekday];
    NSInteger startOffset = weekday - self.calendar.firstWeekday;
    startOffset += startOffset >= 0 ? 0 : self.daysPerWeek;

    NSInteger day = [[self.calendar components:kCalendarUnitYMD fromDate:date] day];

    NSInteger item = (day - kFirstDay + startOffset);

    return [NSIndexPath indexPathForItem:item inSection:section];
}

- (PDTSimpleCalendarViewCell *)cellForItemAtDate:(NSDate *)date
{
    return (PDTSimpleCalendarViewCell *)[self.collectionView cellForItemAtIndexPath:[self indexPathForCellAtDate:date]];
}

#pragma mark - PDTSimpleCalendarViewCellDelegate

- (BOOL)simpleCalendarViewCell:(PDTSimpleCalendarViewCell *)cell shouldUseCustomColorsForDate:(NSDate *)date
{
    //If the date is not enabled (aka outside the first/lastDate) return YES
    if (![self isEnabledDate:date]) {
        return YES;
    }

    //Otherwise we ask the delegate
    if ([self.delegate respondsToSelector:@selector(simpleCalendarViewController:shouldUseCustomColorsForDate:)]) {
        return [self.delegate simpleCalendarViewController:self shouldUseCustomColorsForDate:date];
    }

    return NO;
}

- (UIColor *)simpleCalendarViewCell:(PDTSimpleCalendarViewCell *)cell circleColorForDate:(NSDate *)date
{
    if (![self isEnabledDate:date]) {
        return cell.circleDefaultColor;
    }

    if ([self.delegate respondsToSelector:@selector(simpleCalendarViewController:circleColorForDate:)]) {
        return [self.delegate simpleCalendarViewController:self circleColorForDate:date];
    }

    return nil;
}

- (UIColor *)simpleCalendarViewCell:(PDTSimpleCalendarViewCell *)cell textColorForDate:(NSDate *)date
{
    if (![self isEnabledDate:date]) {
        return cell.textDisabledColor;
    }

    if ([self.delegate respondsToSelector:@selector(simpleCalendarViewController:textColorForDate:)]) {
        return [self.delegate simpleCalendarViewController:self textColorForDate:date];
    }

    return nil;
}

- (UIColor *)simpleCalendarViewCell:(PDTSimpleCalendarViewCell *)cell circleSelectedForDate:(NSDate *)date {
    if (![self isEnabledDate:date]) {
        return cell.circleSelectedColor;
    }
    
    if ([self.delegate respondsToSelector:@selector(simpleCalendarViewController:circleSelectedColorForDate:)]) {
        return [self.delegate simpleCalendarViewController:self circleSelectedColorForDate:date];
    }
    
    return nil;
}

@end
