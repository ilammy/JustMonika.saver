/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#ifndef JUST_MONIKA_GL_PRIVATE_CONTEXT_H
#define JUST_MONIKA_GL_PRIVATE_CONTEXT_H

#include <JustMonikaGL/JustMonikaGL.h>

#include "opengl.h"
#include "timer.h"

struct just_monika {
    GLfloat viewport_width;
    GLfloat viewport_height;

    GLuint viewport_program;
    GLuint viewport_xy_location;
    GLuint viewport_xy_transform_location;

    GLfloat blur_radius;
    GLuint  blur_radius_location;

    GLuint  xy_array;
    GLuint  xy_buffer;
    GLfloat xy_transform_matrix[16];

    GLfloat screen_width;
    GLfloat screen_height;

    GLuint screen_framebuffer;
    GLuint screen_program;
    GLuint screen_texture;
    GLuint screen_sampler;
    GLuint screen_xy_location;

    GLuint monika_bg_sampler;
    GLuint monika_bg_texture;
    GLuint monika_bg_highlight_sampler;
    GLuint monika_bg_highlight_texture;
    GLuint monika_room_texture;
    GLuint monika_room_highlight_texture;
    GLboolean show_monika_room;
    GLuint mask_2_sampler;
    GLuint mask_2_texture;
    GLuint mask_3_sampler;
    GLuint mask_3_texture;
    GLuint mask_sampler;
    GLuint mask_texture;
    GLuint maskb_sampler;
    GLuint maskb_texture;

    struct clock clock;
    GLuint time_location;
};

#endif /* JUST_MONIKA_GL_PRIVATE_CONTEXT_H */
