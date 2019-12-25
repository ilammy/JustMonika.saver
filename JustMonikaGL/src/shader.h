/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#ifndef JUST_MONIKA_GL_PRIVATE_SHADER_H
#define JUST_MONIKA_GL_PRIVATE_SHADER_H

#include "opengl.h"

GLuint compile_shader(GLenum type, const char *name, const char *code, size_t size);

GLuint link_program(const char *name, GLuint vertex_shader, GLuint fragment_shader);

#endif /* JUST_MONIKA_GL_PRIVATE_SHADER_H */
