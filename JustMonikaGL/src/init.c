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
#include "shader.h"

static const char *vertex_shader_src =
    "#version 330 core\n"
    "layout(location = 0) in vec3 vertexPosition_modelSpace;\n"
    "uniform mat4 transform;"
    "void main() {\n"
    "    gl_Position = transform * vec4(vertexPosition_modelSpace, 1.0);\n"
    "}\n";

static const char *fragment_shader_src =
    "#version 330 core\n"
    "out vec3 color;\n"
    "void main() {\n"
    "    color = vec3(0.0, 0.0, 0.0);\n"
    "}\n";

static int init_vertex_buffer_object(struct just_monika *context)
{
    GLfloat quad[] = {
        0.0,                   0.0,                    0.0,
        context->screen_width, 0.0,                    0.0,
        context->screen_width, context->screen_height, 0.0,
        0.0,                   0.0,                    0.0,
        context->screen_width, context->screen_height, 0.0,
        0.0,                   context->screen_height, 0.0,
    };

    glGenVertexArrays(1, &context->screen_vertex_array);
    glBindVertexArray(context->screen_vertex_array);

    glGenBuffers(1, &context->screen_vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, context->screen_vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);

    return 0;
}

static int init_shader_program(struct just_monika *context)
{
    GLuint vertex_shader = 0;
    GLuint fragment_shader = 0;

    vertex_shader = compile_shader(GL_VERTEX_SHADER,
                                   "vertex_shader",
                                   vertex_shader_src,
                                   strlen(vertex_shader_src));
    fragment_shader = compile_shader(GL_FRAGMENT_SHADER,
                                     "fragment_shader",
                                     fragment_shader_src,
                                     strlen(fragment_shader_src));

    context->screen_program = link_program(vertex_shader, fragment_shader);
    if (context->screen_program != 0) {
        goto error;
    }

    context->screen_transform = glGetUniformLocation(context->screen_program, "transform");

error:
    if (vertex_shader != 0) {
        glDeleteShader(vertex_shader);
    }
    if (fragment_shader != 0) {
        glDeleteShader(fragment_shader);
    }
    return -1;
}

int just_monika_init(struct just_monika *context)
{
    /* Nice warm pink color */
    glClearColor(251.0f/256.0f, 231.0f/256.0f, 243.0f/256.0f, 0.0f);

    glEnable(GL_CULL_FACE);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);

    glEnable(GL_MULTISAMPLE);

    init_vertex_buffer_object(context);
    init_shader_program(context);

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
