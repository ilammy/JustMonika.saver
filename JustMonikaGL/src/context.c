//
//  context.c
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "context.h"

#include <stdlib.h>

/* Ideally, it matches with raw image dimensions in pixels. */
static const GLuint default_screen_width = 1280;
static const GLuint default_screen_height = 720;

static struct just_monika_texture_image* stub_open(const char *name)
{
    return NULL;
}

static size_t stub_read(struct just_monika_texture_image *image, void *buffer, size_t size)
{
    return 0;
}

static void stub_free(struct just_monika_texture_image *image)
{
}

struct just_monika* just_monika_make(void)
{
    struct just_monika *context = calloc(1, sizeof(*context));
    if (!context) {
        return NULL;
    }
    context->image.open = stub_open;
    context->image.read = stub_read;
    context->image.free = stub_free;
    context->screen_width = default_screen_width;
    context->screen_height = default_screen_height;
    context->viewport_width = default_screen_width;
    context->viewport_height = default_screen_height;
    return context;
}

void just_monika_free(struct just_monika *context)
{
    free(context);
}
