//
//  JustMonikaView.m
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-17.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "JustMonikaView.h"

#import <QuartzCore/CoreAnimation.h>

#import "DawnAnimationController.h"

@interface JustMonikaView ()

@property(nonatomic) DawnAnimationController *dawnAnimation;

@end

@implementation JustMonikaView

// Called by JustMonikaPreview.app
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupCALayer];
    // TODO: start the animation more natually
    [self.dawnAnimation startAnimation];
}

// Called by Interface Builder preview
- (void)prepareForInterfaceBuilder
{
    [self setupCALayer];
}

// Called by Screen Saver framework
- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
        [self setupCALayer];
    }
    return self;
}

- (void)setupCALayer
{
    // Screen savers are loaded as plugins so their main bundle is not
    // this one, but the host bundle. We need to use the name directly.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonika"];
    NSImage *scene = [bundle imageForResource:@"monika_bg"];
    NSImage *light = [bundle imageForResource:@"monika_bg_highlight"];

    CALayer *sceneLayer = centeredSublayerWithImage(scene);
    CALayer *lightLayer = centeredSublayerWithImage(light);

    CALayer *layer = [CALayer new];
    layer.backgroundColor = [[NSColor blackColor] CGColor];
    layer.contentsGravity = kCAGravityResizeAspectFill;
    layer.layoutManager = [CAConstraintLayoutManager layoutManager];

    [layer addSublayer:sceneLayer];
    [layer addSublayer:lightLayer];

    self.layer = layer;

    self.dawnAnimation = [DawnAnimationController new];
    [self.dawnAnimation addLayer:lightLayer];
}

static CAConstraint *centerX;
static CAConstraint *centerY;
static dispatch_once_t constraintToken;

static CALayer* centeredSublayerWithImage(NSImage *image)
{
    CALayer *layer = [CALayer new];
    layer.contents = image;

    // Bounds need to be set explicitly for sublayers
    layer.bounds = CGRectMake(0, 0, image.size.width, image.size.height);

    // Constraints to ensure that sublayer is centered within its superlayer
    dispatch_once(&constraintToken, ^{
        centerX = [CAConstraint constraintWithAttribute:kCAConstraintMidY
                                             relativeTo:@"superlayer"
                                              attribute:kCAConstraintMidY];
        centerY = [CAConstraint constraintWithAttribute:kCAConstraintMidX
                                             relativeTo:@"superlayer"
                                              attribute:kCAConstraintMidX];
    });

    [layer addConstraint:centerX];
    [layer addConstraint:centerY];

    return layer;
}

- (void)startAnimation
{
    [super startAnimation];

    [self.dawnAnimation startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];

    [self.dawnAnimation stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
