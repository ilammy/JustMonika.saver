//
//  shader.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-26.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "shader.h"

#include <limits.h>
#include <stdio.h>

#define ERROR_BUFFER_LENGTH 1024

GLuint compile_shader(GLenum type, const char *name, const char *code, size_t size)
{
    GLuint id = 0;
    GLint res = GL_FALSE;
    const GLchar *shader_code = code;
    GLint shader_length = (GLint)size;
    GLint info_log_length = 0;

    id = glCreateShader(type);
    glShaderSource(id, 1, &shader_code, &shader_length);
    glCompileShader(id);

    glGetShaderiv(id, GL_COMPILE_STATUS, &res);
    glGetShaderiv(id, GL_INFO_LOG_LENGTH, &info_log_length);
    if (res != GL_TRUE) {
        if (info_log_length > 0) {
            GLsizei length = 0;
            GLchar buffer[ERROR_BUFFER_LENGTH] = {0};

            glGetShaderInfoLog(id, sizeof(buffer), &length, buffer);
            fprintf(stderr, "shader compilation failed (%s):\n%s%s",
                    name, buffer,
                    ((length + 1) < info_log_length) ? "\n(truncated)\n" : "");
        }
        goto error;
    }

    return id;

error:
    glDeleteShader(id);
    return 0;
}

GLuint link_program(GLuint vertex_shader, GLuint fragment_shader)
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
            GLsizei length = 0;
            GLchar buffer[ERROR_BUFFER_LENGTH] = {0};

            glGetProgramInfoLog(id, sizeof(buffer), &length, buffer);
            fprintf(stderr, "program link failed:\n%s%s",
                    buffer,
                    ((length + 1) < info_log_length) ? "\n(truncated)\n" : "");
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
