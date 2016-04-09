//
//  SBubblesView.h
//  SBubblesViewDemo
//
//  Created by zlata samarskaya on 25.10.14.
//  Copyright (c) 2014 zlata samarskaya. All rights reserved.
//
/*--------------------------------------------------*/

@class SBubblesView;

/*--------------------------------------------------*/

@protocol SBubblesViewDelegate <NSObject>

@optional
- (void)bubblesView:(SBubblesView*)bubblesView didSelectViewAtIndex:(NSInteger)index;

@end

@protocol SBubblesViewDataSource <NSObject>

@required
- (NSInteger)numberOfBubblesInBubblesView:(SBubblesView*)bubblesView;

@optional
- (UIImage*)bubblesView:(SBubblesView*)bubblesView imageForIndex:(NSInteger)index;
- (NSURL*)bubblesView:(SBubblesView*)bubblesView imageUrlForIndex:(NSInteger)index;
- (NSString*)bubblesView:(SBubblesView*)bubblesView titleForIndex:(NSInteger)index;

@end

/*--------------------------------------------------*/

typedef NS_ENUM(NSUInteger, SBubblesViewAppearanceType) {
    SBubblesViewAppearanceTypeAlpha,
    SBubblesViewAppearanceTypeTransition
};

/*--------------------------------------------------*/

@interface SBubblesView : UIView

@property(nonatomic, strong) UIColor *bubbleBackgroundColor IB_DESIGNABLE;
@property(nonatomic, strong) UIColor *bubbleForegroundColor IB_DESIGNABLE;
@property(nonatomic, strong) UIColor *bubbleShadowColor IB_DESIGNABLE;
@property(nonatomic, assign) CGFloat bubbleShadowRadius IB_DESIGNABLE;
@property(nonatomic, assign) CGSize bubbleShadowSize IB_DESIGNABLE;
@property(nonatomic, strong) UIFont *font IB_DESIGNABLE;

@property(nonatomic, assign) CGFloat intersectCoefficient IB_DESIGNABLE;
@property(nonatomic, assign) CGFloat startAngle IB_DESIGNABLE;
@property(nonatomic, assign) CGFloat animationDuration IB_DESIGNABLE;

@property(nonatomic, assign) BOOL bounces IB_DESIGNABLE;
@property(nonatomic, assign) BOOL rotating IB_DESIGNABLE;

@property(nonatomic, assign) SBubblesViewAppearanceType appearanceType;

@property(nonatomic, assign) id <SBubblesViewDelegate> delegate;
@property(nonatomic, assign) id <SBubblesViewDataSource> dataSource;

- (void)reloadData;
- (void)startAnimating;
- (void)stopAnimating;

@end
