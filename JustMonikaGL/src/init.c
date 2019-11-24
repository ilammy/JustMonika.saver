//
//  init.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "init.h"

#include <stdio.h>
#include <string.h>
#include <limits.h>

#include <OpenGL/gl3.h>
#pragma clang diagnostic ignored "-Wdeprecated"

GLuint vaID = 0;
GLuint vbID = 0;
GLuint prID = 0;

static const GLfloat triangle[] = {
   -1.0f, -1.0f, 0.0f,
    1.0f, -1.0f, 0.0f,
    0.0f,  1.0f, 0.0f,
};

static const char *vertex_shader =
    "#version 330 core\n"
    "layout(location = 0) in vec3 vertexPosition_modelSpace;\n"
    "void main() {\n"
    "    gl_Position.xyz = vertexPosition_modelSpace;\n"
    "    gl_Position.w = 1.0;\n"
    "}\n";

static const char *fragment_shader =
    "#version 330 core\n"
    "out vec3 color;\n"
    "void main() {\n"
    "    color = vec3(0.0, 0.0, 0.0);\n"
    "}\n";

static GLuint compile_shader(GLenum type, const char *code, size_t size);
static GLuint link_program(GLuint vertex_shader, GLuint fragment_shader);

int just_monika_init(struct just_monika *context)
{
    /* Nice warm pink color */
    glClearColor(251.0f/256.0f, 231.0f/256.0f, 243.0f/256.0f, 0.0f);

    glEnable(GL_CULL_FACE);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);

    glEnable(GL_MULTISAMPLE);

    glGenVertexArrays(1, &vaID);
    glBindVertexArray(vaID);

    glGenBuffers(1, &vbID);
    glBindBuffer(GL_ARRAY_BUFFER, vbID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(triangle), triangle, GL_STATIC_DRAW);

    GLuint vs = compile_shader(GL_VERTEX_SHADER, vertex_shader, strlen(vertex_shader));
    GLuint fs = compile_shader(GL_FRAGMENT_SHADER, fragment_shader, strlen(fragment_shader));
    prID = link_program(vs, fs);
    if (prID != 0) {
        goto error;
    }

    return 0;

error:
    if (vs != 0) {
        glDeleteShader(vs);
    }
    if (fs != 0) {
        glDeleteShader(fs);
    }
    return -1;
}

static GLuint compile_shader(GLenum type, const char *code, size_t size)
{
    GLuint id = 0;
    GLint res = GL_FALSE;
    const GLchar *shader_code = code;
    GLint shader_length = 0;
    GLint info_log_length = 0;

    if (size <= INT_MAX) {
        shader_length = (GLint)size;
    } else {
        return 0;
    }

    id = glCreateShader(type);
    glShaderSource(id, 1, &shader_code, &shader_length);
    glCompileShader(id);

    glGetShaderiv(id, GL_COMPILE_STATUS, &res);
    glGetShaderiv(id, GL_INFO_LOG_LENGTH, &info_log_length);
    if (res != GL_TRUE) {
        if (info_log_length > 0) {
            GLchar buffer[4096] = {0};
            GLsizei length = 0;

            glGetShaderInfoLog(id, sizeof(buffer), &length, buffer);
            fprintf(stderr, "shader compilation failed:\n%s\n", buffer);
        }
        goto error;
    }

    return id;

error:
    glDeleteShader(id);
    return 0;
}

static GLuint link_program(GLuint vertex_shader, GLuint fragment_shader)
{
    GLuint id = 0;
    GLint res = GL_FALSE;
    GLint info_log_length = 0;

    id = glCreateProgram();
    glAttachShader(id, vertex_shader);
    glAttachShader(id, fragment_shader);
    glLinkProgram(id);
    glDetachShader(id, vertex_shader);
    glDetachShader(id, fragment_shader);

    glGetProgramiv(id, GL_LINK_STATUS, &res);
    glGetProgramiv(id, GL_INFO_LOG_LENGTH, &info_log_length);
    if (res != GL_TRUE) {
        if (info_log_length > 0) {
            GLchar buffer[4096] = {0};
            GLsizei length = 0;

            glGetProgramInfoLog(id, sizeof(buffer), &length, buffer);
            fprintf(stderr, "program link failed:\n%s\n", buffer);
        }
        goto error;
    }

    /* Now owned by program */
    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);

    return id;

error:
    glDeleteProgram(id);
    return 0;
}
