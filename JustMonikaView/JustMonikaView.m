//
//  JustMonikaView.m
//  JustMonikaView
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "JustMonikaView.h"

#import <JustMonikaGL/JustMonikaGL.h>

// Yes, I know that Apple deprecates OpenGL in favor of its Metal.
// You don't need to remind me about that in every build.
#pragma clang diagnostic ignored "-Wdeprecated"

@interface JustMonikaView ()

@property (nonatomic,assign) struct just_monika *monika;

@end

@implementation JustMonikaView

// Called when constructing UI made with Interface Builder.
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

// Called by Interface Builder for previews.
- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    [self setup];
}

- (void)setup
{
    if (self.pixelFormat == nil) {
        NSOpenGLPixelFormatAttribute attributes[] =
        {
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
            NSOpenGLPFADoubleBuffer,    // double-buffered
            NSOpenGLPFADepthSize, 32,   // 32 bit depth buffer
            NSOpenGLPFAAccelerated,     // anti-aliased
            NSOpenGLPFAMultisample,     // anti-aliasing via multisampling
            NSOpenGLPFASampleBuffers, 1,    // one sampling buffer
            NSOpenGLPFASamples, 9,          // 3x3 multisampling
            0
        };
        self.pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    }
    if (self.openGLContext == nil) {
        self.openGLContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat
                                                        shareContext:nil];
    }
    if (self.monika == NULL) {
        self.monika = just_monika_make();
    }
}

- (void)dealloc
{
    just_monika_free(self.monika);
    self.monika = NULL;
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
