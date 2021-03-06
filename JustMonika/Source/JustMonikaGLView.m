// SPDX-License-Identifier: GPL-3.0-only
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#include "JustMonikaGLView.h"

#import <JustMonikaGL/JustMonikaGL.h>

// Yes, I know that Apple deprecates OpenGL in favor of its Metal.
// You don't need to remind me about that in every build.
#pragma clang diagnostic ignored "-Wdeprecated"

@interface JustMonikaGLView ()

@property (nonatomic,assign) struct just_monika *monika;

@end

@implementation JustMonikaGLView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        self.monika = just_monika_make();
        NSOpenGLPixelFormatAttribute attributes[] =
        {
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
            NSOpenGLPFADoubleBuffer,    // double-buffered
            NSOpenGLPFAColorSize, 24,   // RGBA pixels with alpha
            NSOpenGLPFAAlphaSize, 8,
            0
        };
        self.pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
        self.openGLContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat
                                                        shareContext:nil];
    }
    return self;
}

- (void)dealloc
{
    just_monika_free(self.monika);
    self.monika = NULL;
}

- (void)startAnimation
{
    just_monika_start_animation(self.monika);
}

- (void)stopAnimation
{
    just_monika_stop_animation(self.monika);
}

- (void)showMonika:(BOOL)visible
{
    just_monika_set_visible(self.monika, visible);
}

#pragma mark - NSOpenGLView overrides

- (void)prepareOpenGL
{
    [super prepareOpenGL];

    [self.openGLContext makeCurrentContext];

    just_monika_init(self.monika);

    [self updateMonikaViewport];
}

- (void)reshape
{
    [super reshape];

    [self.openGLContext makeCurrentContext];

    [self updateMonikaViewport];
}

- (void)updateMonikaViewport
{
    // Cocoa coordinates may not be equivalent to OpenGL ones (high DPI).
    NSSize size = [self convertSizeToBacking:self.frame.size];
    unsigned width  = size.width;
    unsigned height = size.height;
    just_monika_set_viewport(self.monika, width, height);
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self.openGLContext makeCurrentContext];

    just_monika_draw(self.monika);

    [self.openGLContext flushBuffer];
}

@end
