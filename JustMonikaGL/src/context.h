//
//  context.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_PRIVATE_CONTEXT_H
#define JUST_MONIKA_GL_PRIVATE_CONTEXT_H

#include <JustMonikaGL/context.h>

#include "opengl.h"

struct just_monika {
    GLuint viewport_width;
    GLuint viewport_height;

    GLuint screen_width;
    GLuint screen_height;
    GLuint screen_vertex_array;
    GLuint screen_vertex_buffer;
    GLuint screen_program;
    GLuint screen_transform;
    GLfloat screen_transform_matrix[16];
};

#endif /* JUST_MONIKA_GL_PRIVATE_CONTEXT_H */
