//
//  draw.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "draw.h"

#include <OpenGL/gl3.h>
#pragma clang diagnostic ignored "-Wdeprecated"

extern GLuint vaID;
extern GLuint vbID;
extern GLuint prID;

int just_monika_draw(struct just_monika *context)
{
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(prID);

    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, vbID);
    glVertexAttribPointer(0,        /* index */
                          3,        /* 3D point coordinates */
                          GL_FLOAT, /* typed as floats */
                          GL_FALSE, /* not normalized */
                          0,        /* stride */
                          NULL);    /* offset */
    /* Draw a triangle out of 3 points */
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glDisableVertexAttribArray(0);

    return 0;
}
