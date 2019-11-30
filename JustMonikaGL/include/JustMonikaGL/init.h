//
//  init.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_INIT_H
#define JUST_MONIKA_GL_INIT_H

#include <stddef.h>

struct just_monika;

int just_monika_init(struct just_monika *context);

int just_monika_set_viewport(struct just_monika *context, unsigned width, unsigned height);

struct just_monika_texture_image;

typedef struct just_monika_texture_image* (*just_monika_open_texture)(const char *name);
typedef size_t (*just_monika_read_texture)(struct just_monika_texture_image *texture,
                                           void *buffer, size_t size);
typedef void (*just_monika_free_texture)(struct just_monika_texture_image *texture);

struct texture_image_reader {
    just_monika_open_texture open;
    just_monika_read_texture read;
    just_monika_free_texture free;
};

void just_monika_set_texture_reader(struct just_monika *context, const struct texture_image_reader *reader);

#endif /* JUST_MONIKA_GL_INIT_H */
