/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#include "texture.h"

#include <stdlib.h>
#include <string.h>

#include "opengl.h"
#include "resource.h"

GLuint load_texture_from_resource(const char *name)
{
    uint8_t *rgba = NULL;
    size_t width = 0;
    size_t height = 0;
    GLuint texture = 0;

    load_png_resource(name, &rgba, &width, &height);
    if (!rgba) {
        return 0;
    }

    /*
     * Now actually load the texture into the GPU.
     */
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_RECTANGLE, texture);
    glTexImage2D(GL_TEXTURE_RECTANGLE,
                 0,                 /* base image level */
                 GL_RGBA,           /* internal format */
                 (GLsizei)width,
                 (GLsizei)height,
                 0,                 /* border, must be 0 */
                 GL_RGBA,           /* data format */
                 GL_UNSIGNED_BYTE,  /* data type */
                 rgba);
    /*
     * GL_TEXTURE_RECTANGLE does not support mipmapping, just use bilinear.
     */
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    /*
     * We need to use clamping behavior for filters to behave nicely.
     */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    free(rgba);

    return texture;
}
