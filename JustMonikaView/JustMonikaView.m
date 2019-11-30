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

struct just_monika_texture_image {
    FILE *fp;
};

static struct just_monika_texture_image* open_image(const char *name)
{
    struct just_monika_texture_image *image = NULL;

    image = malloc(sizeof(*image));
    if (!image) {
        return NULL;
    }

    NSBundle *thisBundle = [NSBundle bundleForClass:JustMonikaView.class];
    NSString *imageName = [NSString stringWithCString:name
                                             encoding:NSUTF8StringEncoding];
    NSString *imagePath = [thisBundle pathForResource:imageName
                                               ofType:@"png"
                                          inDirectory:@"Monika"];

    image->fp = fopen([imagePath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
    if (!image->fp) {
        free(image);
        return NULL;
    }

    return image;
}

static size_t read_image(struct just_monika_texture_image *image,
                          void *buffer, size_t size)
{
    return fread(buffer, 1, size, image->fp);
}

static void free_image(struct just_monika_texture_image *image)
{
    if (!image) {
        return;
    }
    fclose(image->fp);
    free(image);
}

static const struct texture_image_reader image_reader = {
    .open = open_image,
    .read = read_image,
    .free = free_image,
};

- (void)prepareOpenGL
{
    [super prepareOpenGL];

    [self.openGLContext makeCurrentContext];

    just_monika_set_texture_reader(self.monika, &image_reader);

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
