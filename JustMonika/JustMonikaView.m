//
//  JustMonikaView.m
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-17.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "JustMonikaView.h"

@implementation JustMonikaView

// Called by JustMonikaPreview.app
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupCALayer];
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
    NSImage *image = [bundle imageForResource:@"monika_bg"];

    CALayer *layer = [CALayer new];
    layer.backgroundColor = [[NSColor blackColor] CGColor];
    layer.contents = image;
    layer.contentsGravity = kCAGravityResizeAspectFill;
    self.layer = layer;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
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
