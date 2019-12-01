//
//  init.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "init.h"

#include <string.h>

#include "matrix.h"
#include "resource.h"
#include "shader.h"
#include "texture.h"

static GLuint closest_power_of_two(GLuint width, GLuint height)
{
    GLuint max = (width > height) ? width : height;
    GLuint size = 1;
    /* Edge case */
    if (max == 0) {
        return 0;
    }
    while (size <= max && size != 0) {
        size *= 2;
    }
    return size;
}

static int init_vertex_buffer_object(struct just_monika *context)
{
    GLfloat quad[] = {
        0.0,                   0.0,
        context->screen_width, 0.0,
        context->screen_width, context->screen_height,
        0.0,                   0.0,
        context->screen_width, context->screen_height,
        0.0,                   context->screen_height,
    };
    GLfloat side = closest_power_of_two(context->screen_width,
                                        context->screen_height);
    GLfloat width = context->screen_width;
    GLfloat height = context->screen_height;
    GLfloat uv[] = {
        0.0,          0.0,
        width / side, 0.0,
        width / side, height / side,
        0.0,          0.0,
        width / side, height / side,
        0.0,          height / side,
    };

    glGenVertexArrays(1, &context->screen_vertex_array);
    glBindVertexArray(context->screen_vertex_array);

    glGenBuffers(1, &context->screen_vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, context->screen_vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);

    glGenVertexArrays(1, &context->screen_uv_array);
    glBindVertexArray(context->screen_uv_array);

    glGenBuffers(1, &context->screen_uv_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, context->screen_uv_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(uv), uv, GL_STATIC_DRAW);

    return 0;
}

#define MAX_SHADER_SIZE 4096

static int init_shader_program(struct just_monika *context)
{
    GLuint vertex_shader = 0;
    GLuint fragment_shader = 0;
    GLchar buffer[MAX_SHADER_SIZE];
    size_t length = 0;

    length = load_resource("vertex.glsl", (uint8_t*)buffer, sizeof(buffer));
    vertex_shader = compile_shader(GL_VERTEX_SHADER,
                                   "vertex_shader",
                                   buffer, length);

    length = load_resource("fragment.glsl", (uint8_t*)buffer, sizeof(buffer));
    fragment_shader = compile_shader(GL_FRAGMENT_SHADER,
                                     "fragment_shader",
                                     buffer, length);

    context->screen_program = link_program(vertex_shader, fragment_shader);
    if (!context->screen_program) {
        goto error;
    }

    context->screen_vertex_id = glGetAttribLocation(context->screen_program, "vertexXY_modelSpace");
    context->screen_uv_id = glGetAttribLocation(context->screen_program, "vertexUV");
    context->screen_transform = glGetUniformLocation(context->screen_program, "transform");
    context->screen_sampler = glGetUniformLocation(context->screen_program, "sampler");
    context->timer = glGetUniformLocation(context->screen_program, "timer");

error:
    if (vertex_shader != 0) {
        glDeleteShader(vertex_shader);
    }
    if (fragment_shader != 0) {
        glDeleteShader(fragment_shader);
    }
    return -1;
}

static GLuint load_texture_from_resource(const char *name)
{
    GLuint texture = 0;
    struct resource_file *resource = NULL;

    resource = open_resource(name);
    if (!resource) {
        return 0;
    }
    texture = load_texture(resource);
    free_resource(resource);
    return texture;
}

static int load_textures(struct just_monika *context)
{
    context->screen_texture = load_texture_from_resource("monika_bg.png");
    if (!context->screen_texture) {
        return -1;
    }
    return 0;
}

int just_monika_init(struct just_monika *context)
{
    /* Use opaque black color for background */
    glClearColor(0.0, 0.0, 0.0, 1.0);

    /* Enable transparency, use recommended blending function */
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    init_vertex_buffer_object(context);
    init_shader_program(context);
    load_textures(context);

    glViewport(0, 0, 100, 100);

    return 0;
}

int just_monika_set_viewport(struct just_monika *context, unsigned width, unsigned height)
{
    context->viewport_width = width;
    context->viewport_height = height;

    matrix_set_identity(context->screen_transform_matrix);

    /*
     * Adjust translation so that origin (0, 0) maps onto the lower left corner
     * of the screen quad, instead of the viewport center.
     */
    GLfloat shift_x = -0.5 * context->screen_width;
    GLfloat shift_y = -0.5 * context->screen_height;
    matrix_translate(context->screen_transform_matrix, shift_x, shift_y);

    /*
     * Adjust scale so that the screen quad maintains apparent aspect ratio
     * and takes the whole viewport width.
     */
    GLfloat scale = 2.0f / context->screen_width;
    GLfloat scale_x = scale;
    GLfloat scale_y = scale * ((GLfloat)width / (GLfloat)height);
    matrix_scale(context->screen_transform_matrix, scale_x, scale_y);

    glViewport(0, 0, width, height);

    return 0;
}
