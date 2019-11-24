//
//  draw.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "draw.h"

int just_monika_draw(struct just_monika *context)
{
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(context->screen_program);

    glUniformMatrix4fv(context->screen_transform,
                       1,       /* one 4x4 matrix */
                       GL_TRUE, /* row-major order */
                       context->screen_transform_matrix);

    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, context->screen_vertex_buffer);
    glVertexAttribPointer(0,        /* index */
                          3,        /* 3D point coordinates */
                          GL_FLOAT, /* typed as floats */
                          GL_FALSE, /* not normalized */
                          0,        /* stride */
                          NULL);    /* offset */
    /* Draw a quad out of 2 x 3 point set. */
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glDisableVertexAttribArray(0);

    return 0;
}
