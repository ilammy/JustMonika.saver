//
//  context.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_PRIVATE_CONTEXT_H
#define JUST_MONIKA_GL_PRIVATE_CONTEXT_H

#include <stdbool.h>

#include <JustMonikaGL/JustMonikaGL.h>

#include "opengl.h"
#include "timer.h"

struct just_monika {
    GLfloat viewport_width;
    GLfloat viewport_height;

    GLfloat screen_width;
    GLfloat screen_height;

    GLfloat texture_width;
    GLfloat texture_height;

    GLuint xy_array;
    GLuint xy_buffer;
    GLuint xy_location;

    GLuint  xy_transform_location;
    GLfloat xy_transform_matrix[16];

    GLuint uv_array;
    GLuint uv_buffer;
    GLuint uv_location;

    GLuint  uv_transform_location;
    GLfloat uv_transform_matrix[16];

    GLuint monika_bg_sampler;
    GLuint monika_bg_texture;

    GLuint screen_program;

    struct clock clock;
    bool clock_ticking;
    GLuint timer;
};

#endif /* JUST_MONIKA_GL_PRIVATE_CONTEXT_H */