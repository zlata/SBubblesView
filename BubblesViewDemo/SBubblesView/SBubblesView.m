//
//  SImagesFlowerView.m
//  BubblesViewDemo
//
//  Created by zlata samarskaya on 25.10.14.
//  Copyright (c) 2014 zlata samarskaya. All rights reserved.
//

/*--------------------------------------------------*/

#import "SBubblesView.h"
#import <UIImageView+AFNetworking.h>

/*--------------------------------------------------*/
#pragma mark - Bubble View
/*--------------------------------------------------*/

static CGFloat const SBubbleViewPopupAnimationDuration = 0.15f;

static NSString *const SBubbleAnimationPopupKey = @"SBubbleAnimationPopupKey";

/*--------------------------------------------------*/

@interface SBubbleView : UIControl

@property (nonatomic, strong) UIImage *intersectImage;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, strong) NSArray* transitionPoints;

@end

@implementation SBubbleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - Setup subviews

- (void)setup {
    self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2;

    [self addSubview:self.imageView];
}

#pragma mark - Accessors

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.layer.masksToBounds = YES;
        _imageView.layer.cornerRadius = CGRectGetWidth(_imageView.bounds) / 2;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}

#pragma mark - Animations

- (void)animateTransitionWithDelay:(CGFloat)delay duration:(CGFloat)duration bounces:(BOOL)bounces {
    self.center = self.startPoint;
    if (self.transitionPoints.count == 0) {
        return;
    }
    [self.transitionPoints enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint point = ((NSValue*)obj).CGPointValue;
        CGFloat delayTime = idx * duration;
        [UIView animateWithDuration:duration delay:delayTime options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.center = point;
        } completion:^(BOOL finished) {
            if (idx == self.transitionPoints.count - 1) {
                if (self.intersectImage != nil) {
                    self.imageView.image = self.intersectImage;
                    self.imageView.transform = CGAffineTransformIdentity;
                }
            }
        }];
    }];
}

- (void)animateAlphaWithDelay:(CGFloat)delay duration:(CGFloat)duration bounces:(BOOL)bounces {
    self.alpha = 0;
    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        if (bounces) {
            [self animatePopup];
        }
    }];
}

- (void)animatePopup {
    [self.imageView.layer addAnimation:[self _popUpAnimation] forKey:SBubbleAnimationPopupKey];
}

- (CAKeyframeAnimation*)_popUpAnimation {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];

    NSValue *scale1Value = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05f, 1.05f, 1.0f)];
    NSValue *scale2Value = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9f, 0.9f, 1.0f)];
    NSValue *scale3Value = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)];
    animation.values = @[scale1Value, scale2Value, scale3Value];

    animation.keyTimes = @[@(0.0f), @(0.5f), @(1.0f)];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = SBubbleViewPopupAnimationDuration;

    return animation;
}

@end

/*--------------------------------------------------*/
#pragma mark - Bubbles View
/*--------------------------------------------------*/

static NSString *const SAnimationSpiningKey = @"SAnimationSpiningKey";

/*--------------------------------------------------*/

@interface SBubblesView () {
    CGFloat _bubbleRadius;
    CGFloat _containerRadius;
}

@property(nonatomic, strong) UIView *container;
@property(nonatomic, strong) NSMutableArray *bubbleViews;

@end

/*--------------------------------------------------*/

@implementation SBubblesView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    _startAngle = -90.f;
    _bubbleBackgroundColor = UIColor.redColor;
    _bubbleForegroundColor = UIColor.whiteColor;
    _bubbleShadowColor = [UIColor colorWithWhite:0 alpha:0.15];
    _bubbleShadowSize = CGSizeMake(3, 3);
    _font = [UIFont boldSystemFontOfSize:32];
    _bounces = YES;
    _rotating = YES;
    _animationDuration = 0.2f;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = _containerRadius * 2;
    self.container.frame = CGRectMake(0, 0, width, width);
    self.container.center = CGPointMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2);

    [self _layoutBubbles];
}

#pragma mark - Public

- (void)reloadData {
    [self stopAnimating];

    [self _clear];

    if (self.dataSource == nil) {
        return;
    }
    NSInteger count = [self.dataSource numberOfBubblesInBubblesView:self];
    if (count == 0) {
        return;
    }
    _containerRadius = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))  / 2;
    _bubbleRadius = [self _radiusForImagesCount:count];

    for (NSInteger i = 0; i < count; i++) {
        [self _addBubbleForIndex:i];
    }

    [self setNeedsDisplay];
}

- (void)startAnimating {
    [self _layoutBubbles];
    if (self.appearanceType == SBubblesViewAppearanceTypeTransition) {
        [self _animateBubblesTransition];
    }
    if (self.appearanceType == SBubblesViewAppearanceTypeAlpha) {
        [self _animateBubblesAlpha];
    }
    if (self.rotating) {
        [self _startRotationAnimation];
    }
}

- (void)stopAnimating {
    [self _stopRotationAnimation];
}

#pragma mark - Accessors

- (UIView*)container {
    if (_container == nil) {
        CGFloat width = _containerRadius * 2;
        _container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
        [self addSubview:_container];
    }
    return _container;
}

#pragma mark - Private
#pragma mark - Animations

- (void)_stopRotationAnimation {
    [self.container.layer removeAnimationForKey:SAnimationSpiningKey];
}

- (void)_startRotationAnimation {
    CABasicAnimation* spinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    spinAnimation.toValue = @(2 * M_PI);
    spinAnimation.repeatCount = INFINITY;
    spinAnimation.duration = 10;
    spinAnimation.removedOnCompletion = NO;
    spinAnimation.fillMode = kCAFillModeForwards;

    [self.container.layer addAnimation:spinAnimation forKey:SAnimationSpiningKey];
}

- (void)_animateBubblesTransition {
    [self.bubbleViews enumerateObjectsUsingBlock:^(SBubbleView *bubbleView, NSUInteger index, BOOL *stop) {
        bubbleView.center = bubbleView.startPoint;
        CGFloat delayTime = index * self.animationDuration;
        [bubbleView animateTransitionWithDelay:delayTime duration:self.animationDuration bounces:self.bounces];
    }];
}

- (void)_animateBubblesAlpha {
    [self.bubbleViews enumerateObjectsUsingBlock:^(SBubbleView *bubbleView, NSUInteger index, BOOL *stop) {
        CGFloat delayTime = index * self.animationDuration;
        [bubbleView animateAlphaWithDelay:delayTime duration:self.animationDuration bounces:self.bounces];
    }];
}

#pragma mark - Actions

- (void)handleBubbleTap:(SBubbleView*)bubbleView {
    if ([_delegate respondsToSelector:@selector(bubblesView:didSelectViewAtIndex:)]) {
        [_delegate bubblesView:self didSelectViewAtIndex:bubbleView.tag];
    }
    if (_appearanceType == SBubblesViewAppearanceTypeTransition) {
        [bubbleView animatePopup];
    }
}

- (void)_clear {
    [self stopAnimating];

    self.bubbleViews = [NSMutableArray new];

    [self.container removeFromSuperview];
    self.container = nil;
}

#pragma mark - Bubbles

- (void)_addBubbleForIndex:(NSInteger)index {
    CGFloat width = _bubbleRadius * 2;
    SBubbleView *bubbleView = [self _bubbleViewWithRect:CGRectMake(0, 0, width, width)];
    bubbleView.tag = index;
    [self.bubbleViews addObject:bubbleView];
    [self.container addSubview:bubbleView];

    if ([_dataSource respondsToSelector:@selector(bubblesView:imageForIndex:)]) {
        UIImage *image = [_dataSource bubblesView:self imageForIndex:index];
        if (image != nil) {
            [bubbleView.imageView setImage:image];
            return;
        }
    }
    if ([_dataSource respondsToSelector:@selector(bubblesView:imageUrlForIndex:)]) {
        NSURL *url = [_dataSource bubblesView:self imageUrlForIndex:index];
        if (url != nil) {
            [bubbleView.imageView setImageWithURL:url];
            return;
        }
    }
    if ([_dataSource respondsToSelector:@selector(bubblesView:titleForIndex:)]) {
        NSString *title = [_dataSource bubblesView:self titleForIndex:index];
        if (title != nil) {
            [bubbleView.imageView setImage:[self _imageForTitle:title]];
        }
    }
}

- (void)_layoutBubbles {
    CGFloat imageDistanceFromPivot = _containerRadius - _bubbleRadius;
    CGPoint center = CGPointMake(CGRectGetWidth(self.container.bounds) / 2, CGRectGetHeight(self.container.bounds) / 2);
    
    CGFloat imageBetweenAngel = (360.f / self.bubbleViews.count);

    NSMutableArray *coordinates = [NSMutableArray array];
    CGPoint startPoint = CGPointZero;
    for (int i = 0; i < self.bubbleViews.count; ++i) {
        SBubbleView *bubbleView = [self.bubbleViews objectAtIndex:i];

        CGFloat angle = self.startAngle - i * imageBetweenAngel;

        CGFloat x = cos(angle * M_PI / 180) * imageDistanceFromPivot + center.x;
        CGFloat y = sin(angle * M_PI / 180) * imageDistanceFromPivot + center.y;
        CGPoint point = CGPointMake(x, y);
        if (self.appearanceType == SBubblesViewAppearanceTypeTransition) {
            if (i == 0) {
                startPoint = point;
            }
            bubbleView.startPoint = startPoint;
            [coordinates addObject:[NSValue valueWithCGPoint:point]];
        } else {
            bubbleView.center = point;
        }

        CGFloat rotatingAngleDegrees = atan2f(center.y - y, center.x - x) * (180. / M_PI);
        CGFloat rotatingAngleRadian = (rotatingAngleDegrees + self.startAngle) * M_PI / 180;
        if (i == self.bubbleViews.count - 1 && _intersectCoefficient > 0) {
            bubbleView.intersectImage = [self _intersectImageForBubbbleView:bubbleView
                                                              intersectView:self.bubbleViews.firstObject
                                                                      angle:rotatingAngleRadian];
        }
        bubbleView.imageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, rotatingAngleRadian);
    }
    if (self.appearanceType == SBubblesViewAppearanceTypeTransition) {
        for (int i = 0; i < self.bubbleViews.count; ++i) {
            SBubbleView *bubbleView = [self.bubbleViews objectAtIndex:i];
            bubbleView.transitionPoints = [coordinates subarrayWithRange:NSMakeRange(0, i + 1)];
        }
    }
}

- (SBubbleView*)_bubbleViewWithRect:(CGRect)rect {
    SBubbleView *bubbleView = [[SBubbleView alloc] initWithFrame:rect];
    bubbleView.layer.shadowColor = self.bubbleShadowColor.CGColor;
    bubbleView.layer.shadowRadius = self.bubbleShadowRadius;
    bubbleView.layer.shadowOffset = self.bubbleShadowSize;
    bubbleView.layer.shadowOpacity = 1.0f;

    [bubbleView addTarget:self action:@selector(handleBubbleTap:) forControlEvents:UIControlEventTouchUpInside];

    return bubbleView;
}

- (CGFloat)_radiusForImagesCount:(NSInteger)count {
    CGFloat radius = 0.0f;
    CGFloat halfImageBetweenAngel = 360.f / count / 2;
    //calculate triangle with inscribed circle
    CGFloat catet = _containerRadius;
    CGFloat hypotenuse = catet / cos(halfImageBetweenAngel * M_PI / 180.0f);
    CGFloat triangleBase = 2 * hypotenuse * sin (halfImageBetweenAngel * M_PI / 180.0f);
    //calculate inscribed circle radius
    radius = ceil((triangleBase / 2) * sqrtf((2 * hypotenuse - triangleBase) / (2 * hypotenuse + triangleBase)));
    radius *= 1 + self.intersectCoefficient;

    return radius;
}

#pragma mark - Drawing Images

- (UIImage*)_imageForTitle:(NSString*)title {
    CGRect rect = (CGRect){0, 0, _containerRadius, _containerRadius};
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.bubbleBackgroundColor.CGColor);
    CGContextFillEllipseInRect(context, rect);
    
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetTextMatrix(context, CGAffineTransformMake(1.0,0.0, 0.0, -1.0, 0.0, 0.0));

    NSDictionary* stringAttrs = @{ NSFontAttributeName : _font, NSForegroundColorAttributeName : self.bubbleForegroundColor };
    CGRect textRect = [title boundingRectWithSize:rect.size options:NSStringDrawingUsesFontLeading attributes:stringAttrs context:nil];
    textRect.origin.x = (CGRectGetWidth(rect) - CGRectGetWidth(textRect)) / 2;
    textRect.origin.y = (CGRectGetHeight(rect) - CGRectGetHeight(textRect)) / 2;

    [title drawInRect:textRect withAttributes:stringAttrs];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage*)_intersectImageForBubbbleView:(SBubbleView*)bubbleView intersectView:(SBubbleView*)intersectBubbleView angle:(CGFloat)angle {
    CGFloat xOffset = intersectBubbleView.center.x - bubbleView.center.x;
    CGFloat yOffset = intersectBubbleView.center.y - bubbleView.center.y;
    
    CGRect rect =  bubbleView.bounds;
    CGRect rect1 = CGRectMake(- rect.size.width / 2, - rect.size.height / 2, rect.size.width, rect.size.height);
    CGRect rect2 = rect1;
    rect2.origin.x += xOffset;
    rect2.origin.y += yOffset;

    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, CGRectGetWidth(rect1) / 2, CGRectGetHeight(rect1) / 2);
    CGContextRotateCTM(context,  angle);
    
    CGContextSetShadowWithColor(context, self.bubbleShadowSize, self.bubbleShadowRadius, self.bubbleShadowColor.CGColor);
    [bubbleView.imageView.image drawInRect:rect1];
    CGContextRotateCTM(context, - angle);
    [intersectBubbleView.imageView.image drawInRect:rect2];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

@end
