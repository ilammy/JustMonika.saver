//
//  init.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "init.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "matrix.h"
#include "resource.h"
#include "shader.h"
#include "texture.h"

static void init_xy_array(struct just_monika *context)
{
    GLfloat quad_xy_coords[] = {
        0.0,                   0.0,
        context->screen_width, 0.0,
        context->screen_width, context->screen_height,
        0.0,                   0.0,
        context->screen_width, context->screen_height,
        0.0,                   context->screen_height,
    };

    glGenVertexArrays(1, &context->xy_array);
    glBindVertexArray(context->xy_array);

    glGenBuffers(1, &context->xy_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, context->xy_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad_xy_coords), quad_xy_coords, GL_STATIC_DRAW);
}

static void init_xy_matrix(struct just_monika *context)
{
    matrix_set_identity(context->xy_transform_matrix);

    /*
     * Adjust translation so that origin (0, 0) maps onto the lower left corner
     * of the screen quad, instead of the viewport center.
     */
    GLfloat shift_x = -0.5 * context->screen_width;
    GLfloat shift_y = -0.5 * context->screen_height;
    matrix_translate(context->xy_transform_matrix, shift_x, shift_y);

    /*
     * Adjust scale so that the screen quad maintains apparent aspect ratio
     * and takes the whole viewport width.
     */
    GLfloat scale = 2.0f / context->screen_width;
    GLfloat scale_x = scale;
    GLfloat scale_y = scale * context->viewport_width / context->viewport_height;
    matrix_scale(context->xy_transform_matrix, scale_x, scale_y);
}

static void init_shader_program(struct just_monika *context)
{
    GLuint viewport_vertex_shader = 0;
    GLuint viewport_fragment_shader = 0;
    GLuint screen_vertex_shader = 0;
    GLuint screen_fragment_shader = 0;
    GLchar *buffer = NULL;
    size_t length = 0;

    length = load_resource("viewport-vertex.glsl", (uint8_t**)&buffer);
    viewport_vertex_shader = compile_shader(GL_VERTEX_SHADER,
                                            "viewport_vertex_shader",
                                            buffer, length);

    length = load_resource("viewport-fragment.glsl", (uint8_t**)&buffer);
    viewport_fragment_shader = compile_shader(GL_FRAGMENT_SHADER,
                                              "viewport_fragment_shader",
                                              buffer, length);

    length = load_resource("screen-vertex.glsl", (uint8_t**)&buffer);
    screen_vertex_shader = compile_shader(GL_VERTEX_SHADER,
                                          "screen_vertex_shader",
                                          buffer, length);

    length = load_resource("screen-fragment.glsl", (uint8_t**)&buffer);
    screen_fragment_shader = compile_shader(GL_FRAGMENT_SHADER,
                                            "screen_fragment_shader",
                                            buffer, length);

    free(buffer);

    context->viewport_program = link_program("viewport_program",
                                             viewport_vertex_shader,
                                             viewport_fragment_shader);

    context->screen_program = link_program("screen_program",
                                           screen_vertex_shader,
                                           screen_fragment_shader);

    /* Shaders are now owned by linked programs */
    glDeleteShader(viewport_vertex_shader);
    glDeleteShader(viewport_fragment_shader);
    glDeleteShader(screen_vertex_shader);
    glDeleteShader(screen_fragment_shader);

    /* viewport_program locations */

    context->viewport_xy_location = glGetAttribLocation(context->viewport_program, "vertexXY_modelSpace");
    context->viewport_xy_transform_location = glGetUniformLocation(context->viewport_program, "vertexXY_transform");

    context->screen_sampler = glGetUniformLocation(context->viewport_program, "sampler");

    context->viewport_use_blur_location = glGetUniformLocation(context->viewport_program, "useBlur");
    context->blur_parameter_location = glGetUniformLocation(context->viewport_program, "blurParameter");

    /* screen_program locations */

    context->screen_xy_location = glGetAttribLocation(context->screen_program, "XY");

    context->monika_bg_sampler = glGetUniformLocation(context->screen_program, "monika_bg");
    context->monika_bg_highlight_sampler = glGetUniformLocation(context->screen_program, "monika_bg_highlight");
    context->mask_2_sampler = glGetUniformLocation(context->screen_program, "mask_2");
    context->mask_3_sampler = glGetUniformLocation(context->screen_program, "mask_3");
    context->mask_sampler = glGetUniformLocation(context->screen_program, "mask");
    context->maskb_sampler = glGetUniformLocation(context->screen_program, "maskb");

    context->time = glGetUniformLocation(context->screen_program, "time");

    context->offsetX_location = glGetUniformLocation(context->screen_program, "offsetX");
    context->offsetY_location = glGetUniformLocation(context->screen_program, "offsetY");

    context->biasA_location = glGetUniformLocation(context->screen_program, "biasA");
    context->biasB_location = glGetUniformLocation(context->screen_program, "biasB");
    context->scaleA_location = glGetUniformLocation(context->screen_program, "scaleA");
    context->scaleB_location = glGetUniformLocation(context->screen_program, "scaleB");
}

static GLuint load_texture_from_resource(const char *name)
{
    GLuint texture = 0;
    struct resource_file *resource = NULL;

    resource = open_resource(name);
    texture = load_texture(resource);
    free_resource(resource);

    return texture;
}

static void init_textures(struct just_monika *context)
{
    context->monika_bg_texture = load_texture_from_resource("monika_bg.png");
    context->monika_bg_highlight_texture = load_texture_from_resource("monika_bg_highlight.png");
    context->mask_2_texture = load_texture_from_resource("mask_2.png");
    context->mask_3_texture = load_texture_from_resource("mask_3.png");
    context->mask_texture = load_texture_from_resource("mask.png");
    context->maskb_texture = load_texture_from_resource("maskb.png");
}

static void init_screen_framebuffer(struct just_monika *context)
{
    /* Make ourselves a new framebuffer */
    glGenFramebuffers(1, &context->screen_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, context->screen_framebuffer);

    /* Allocate a texture where framebuffer will be rendered to */
    glGenTextures(1, &context->screen_texture);
    glBindTexture(GL_TEXTURE_RECTANGLE, context->screen_texture);
    /* Use bilinear filtering for scaling with appropriate clamping */
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    /* Just make an empty texture, we don't care about initial contents */
    glTexImage2D(GL_TEXTURE_RECTANGLE,
                 0,                 /* base image level */
                 GL_RGBA,           /* internal format */
                 context->screen_width,
                 context->screen_height,
                 0,                 /* border, must be 0 */
                 GL_RGBA,           /* data format */
                 GL_UNSIGNED_BYTE,  /* data type */
                 NULL);             /* no initial data */

    /* Attach the texture to the framebuffer for color output */
    glFramebufferTexture(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         context->screen_texture,
                         0);        /* base image level */

    /* And tell the framebuffer to render color there */
    GLenum attachment = GL_COLOR_ATTACHMENT0;
    glDrawBuffers(1, &attachment);

    /* Switch back to the default framebuffer for now */
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

int just_monika_init(struct just_monika *context)
{
    /* Use opaque black color for background */
    glClearColor(0.0, 0.0, 0.0, 1.0);

    /* Enable transparency, use recommended blending function */
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    init_xy_array(context);
    init_shader_program(context);
    init_textures(context);
    init_screen_framebuffer(context);

    return 0;
}

/*
 * I have visually experimented with blur radius for different viewport widths
 * and obtained this data:
 *
 *     width  radius
 *      600     0.0    bigger than this is fine with no blur
 *      500     1.0    around this is fine
 *      400     1.5    definitely looks better than 1.0
 *      300     2.5    it looks better than 2.0
 *      200     3.0    almost no difference with 2.5, but 3.5 looks blurry
 *      100     6.0    this looks way nicer than, say, 4.0
 *
 * Putting it through a logarithmic regression yields the following
 * approximation:
 *
 *     radius = 20.0 - 3.11 ln width
 *
 * with correlation |r| = 0.98 it is pretty close to 1.0 to convince me.
 */
static GLfloat blur_radius_for_width(unsigned width)
{
    GLfloat radius = 20.0f - 3.11f * logf(width);
    if (radius < 0.0f) {
        radius = 0.0f;
    }
    return radius;
}

int just_monika_set_viewport(struct just_monika *context, unsigned width, unsigned height)
{
    context->viewport_width = width;
    context->viewport_height = height;

    init_xy_matrix(context);

    /*
     * Adapt the blur radius to viewport width. We need more blur for smaller
     * viewports to look better.
     */
    context->blur_parameter = blur_radius_for_width(width);

    return 0;
}
