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
            NSOpenGLPFAColorSize, 24,   // RGBA pixels with alpha
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFAAccelerated,     // anti-aliased
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

static FILE* open_resource_file(const char *name)
{
    NSBundle *thisBundle = [NSBundle bundleForClass:JustMonikaView.class];
    NSString *imageName = [NSString stringWithCString:name
                                             encoding:NSUTF8StringEncoding];
    NSString *imagePath = [thisBundle pathForResource:imageName
                                               ofType:@"png"
                                          inDirectory:@"Monika"];
    return fopen([imagePath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
}

- (void)prepareOpenGL
{
    [super prepareOpenGL];

    [self.openGLContext makeCurrentContext];

    just_monika_set_open_resource_callback(self.monika, open_resource_file);

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
