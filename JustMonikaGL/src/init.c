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
    GLuint vertex_shader = 0;
    GLuint screen_shader = 0;
    GLuint fragment_shader = 0;
    GLchar *buffer = NULL;
    size_t length = 0;

    length = load_resource("vertex.glsl", (uint8_t**)&buffer);
    vertex_shader = compile_shader(GL_VERTEX_SHADER,
                                   "vertex_shader",
                                   buffer, length);

    length = load_resource("screen.glsl", (uint8_t**)&buffer);
    screen_shader = compile_shader(GL_FRAGMENT_SHADER,
                                   "screen_shader",
                                   buffer, length);

    length = load_resource("fragment.glsl", (uint8_t**)&buffer);
    fragment_shader = compile_shader(GL_FRAGMENT_SHADER,
                                     "fragment_shader",
                                     buffer, length);

    free(buffer);

    context->screen_program = link_program(vertex_shader, fragment_shader);
    context->screen_program_rename_me = link_program(vertex_shader, screen_shader);

    /* Shaders are now owned by linked program */
    glDeleteShader(vertex_shader);
    glDeleteShader(screen_shader);
    glDeleteShader(fragment_shader);

    context->xy_location = glGetAttribLocation(context->screen_program, "vertexXY_modelSpace");
    context->xy_transform_location = glGetUniformLocation(context->screen_program, "vertexXY_transform");

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

    context->screen_sampler = glGetUniformLocation(context->screen_program_rename_me, "screen");
    context->screen_xy_location = glGetAttribLocation(context->screen_program_rename_me, "vertexXY_modelSpace");
    context->screen_xy_transform_location = glGetUniformLocation(context->screen_program_rename_me, "vertexXY_transform");
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
    glGenFramebuffers(1, &context->screen_frambuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, context->screen_frambuffer);

    glGenTextures(1, &context->screen_texture);
    glBindTexture(GL_TEXTURE_2D, context->screen_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 2048, 2048, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    glFramebufferTexture(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         context->screen_texture,
                         0);

    GLenum attachment = GL_COLOR_ATTACHMENT0;
    glDrawBuffers(1, &attachment);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        // TODO: log error
    }

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

int just_monika_set_viewport(struct just_monika *context, unsigned width, unsigned height)
{
    context->viewport_width = width;
    context->viewport_height = height;

    init_xy_matrix(context);

    glViewport(0, 0, width, height);

    return 0;
}
