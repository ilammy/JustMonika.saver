/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#ifndef JUST_MONIKA_GL_PRIVATE_MATRIX_H
#define JUST_MONIKA_GL_PRIVATE_MATRIX_H

#include "opengl.h"

void matrix_set_identity(GLfloat matrix[16]);

void matrix_scale(GLfloat matrix[16], GLfloat sx, GLfloat sy);

void matrix_translate(GLfloat matrix[16], GLfloat dx, GLfloat dy);

#endif /* JUST_MONIKA_GL_PRIVATE_MATRIX_H */
