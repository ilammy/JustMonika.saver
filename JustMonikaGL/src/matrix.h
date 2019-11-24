//
//  matrix.h
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-26.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_PRIVATE_MATRIX_H
#define JUST_MONIKA_GL_PRIVATE_MATRIX_H

#include "opengl.h"

void matrix_set_identity(GLfloat matrix[16]);

void matrix_scale(GLfloat matrix[16], GLfloat sx, GLfloat sy);

void matrix_translate(GLfloat matrix[16], GLfloat dx, GLfloat dy);

#endif /* JUST_MONIKA_GL_PRIVATE_MATRIX_H */
