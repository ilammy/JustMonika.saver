//
//  DawnAnimationController.m
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-19.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "DawnAnimationController.h"

#import <ScreenSaver/ScreenSaver.h>

@interface DawnAnimationController ()

@property(nonatomic) CAAnimation *animation;
@property(nonatomic) NSMutableArray<CALayer*> *layers;

@end

// CAAnimationDelegate is stored as a strong reference in CAAnimation
// so we use this indirection with a weak reference to avoid cycles.
@interface DawnAnimationControllerDelegate : NSObject <CAAnimationDelegate>

@property(nonatomic,weak) DawnAnimationController *controller;

@end

@implementation DawnAnimationController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.animation = prepareAnimation();
        self.animation.delegate = prepareDelegate(self);
        self.layers = [NSMutableArray new];
    }
    return self;
}

// Animation timings, in seconds.
static CFTimeInterval fadeInDuration   =  3.0;
static CFTimeInterval highlightDelay   =  2.0;
static CFTimeInterval fadeOutDuration  =  3.5;
static CFTimeInterval minPulseInterval = 20.0;
static CFTimeInterval maxPulseInterval = 40.0;

static CAAnimation* prepareAnimation()
{
    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.duration = fadeInDuration;
    fadeIn.fromValue = [NSNumber numberWithFloat:0.0];
    fadeIn.toValue = [NSNumber numberWithFloat:1.0];
    fadeIn.fillMode = kCAFillModeForwards;

    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOut.beginTime = fadeInDuration + highlightDelay;
    fadeOut.duration = fadeOutDuration;
    fadeOut.fromValue = [NSNumber numberWithFloat:1.0];
    fadeOut.toValue = [NSNumber numberWithFloat:0.0];
    fadeOut.fillMode = kCAFillModeForwards;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[fadeIn, fadeOut];
    group.duration = fadeInDuration + highlightDelay + fadeOutDuration;

    return group;
}

static DawnAnimationControllerDelegate* prepareDelegate(DawnAnimationController *controller)
{
    DawnAnimationControllerDelegate* delegate = [DawnAnimationControllerDelegate new];
    delegate.controller = controller;
    return delegate;
}

- (void)addLayer:(CALayer *)layer
{
    layer.opacity = 0.0;
    [self.layers addObject:layer];
}

static NSString *animationKey = @"dawnAnimation";

static CFTimeInterval randomAnimationOffset()
{
    return SSRandomFloatBetween(minPulseInterval, maxPulseInterval);
}

- (void)startAnimation
{
    // Note that "beginTime" is absolute time.
    self.animation.beginTime = CACurrentMediaTime() + randomAnimationOffset();
    for (CALayer *layer in self.layers) {
        [layer addAnimation:self.animation forKey:animationKey];
    }
}

- (void)stopAnimation
{
    for (CALayer *layer in self.layers) {
        [layer removeAnimationForKey:animationKey];
    }
}

@end

@implementation DawnAnimationControllerDelegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished
{
    // If the animation has finished normally, reschedule it for the next run.
    if (finished) {
        [self.controller startAnimation];
    }
}

@end
