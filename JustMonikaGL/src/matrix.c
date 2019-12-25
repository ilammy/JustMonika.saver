/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#include "matrix.h"

#include <string.h>

void matrix_set_identity(GLfloat matrix[16])
{
    static const GLfloat identity[] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
    };
    memcpy(matrix, identity, sizeof(identity));
}

/*
 * | sx  0  0  0 |
 * |  0 sy  0  0 |
 * |  0  0  1  0 |
 * |  0  0  0  1 |
 */
void matrix_scale(GLfloat matrix[16], GLfloat sx, GLfloat sy)
{
    matrix[0] *= sx;
    matrix[1] *= sx;
    matrix[2] *= sx;
    matrix[3] *= sx;

    matrix[4] *= sy;
    matrix[5] *= sy;
    matrix[6] *= sy;
    matrix[7] *= sy;
}

/*
 * | 1  0  0 dx |
 * | 0  1  0 dy |
 * | 0  0  1  0 |
 * | 0  0  0  1 |
 */
void matrix_translate(GLfloat matrix[16], GLfloat dx, GLfloat dy)
{
    matrix[0] += dx * matrix[12];
    matrix[1] += dx * matrix[13];
    matrix[2] += dx * matrix[14];
    matrix[3] += dx * matrix[15];

    matrix[4] += dy * matrix[12];
    matrix[5] += dy * matrix[13];
    matrix[6] += dy * matrix[14];
    matrix[7] += dy * matrix[15];
}
