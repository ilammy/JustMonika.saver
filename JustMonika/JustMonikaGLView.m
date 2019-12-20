//
//  JustMonikaView.m
//  JustMonikaView
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

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
            NSOpenGLPFAMultisample,     // enable 2x2 antialiasing
            NSOpenGLPFASampleBuffers, 1,
            NSOpenGLPFASamples,       4,
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

#pragma mark - Configuration API

- (void)configureWith:(const struct just_monika_settings *)settings
{
    just_monika_configure(self.monika, settings);
}

#pragma mark - NSOpenGLView overrides

- (void)prepareOpenGL
{
    [super prepareOpenGL];

    [self.openGLContext makeCurrentContext];

    just_monika_init(self.monika);

    unsigned width = NSWidth(self.frame);
    unsigned height = NSHeight(self.frame);
    just_monika_set_viewport(self.monika, width, height);
}

- (void)reshape
{
    [super reshape];

    [self.openGLContext makeCurrentContext];

    unsigned width = NSWidth(self.frame);
    unsigned height = NSHeight(self.frame);
    just_monika_set_viewport(self.monika, width, height);
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self.openGLContext makeCurrentContext];

    just_monika_draw(self.monika);

    [self.openGLContext flushBuffer];
}

@end
