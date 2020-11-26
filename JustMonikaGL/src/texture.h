/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#ifndef JUST_MONIKA_GL_PRIVATE_TEXTURE_H
#define JUST_MONIKA_GL_PRIVATE_TEXTURE_H

#include "opengl.h"
#include "resource.h"

GLuint load_texture(struct resource_file *image);

GLuint load_texture_from_resource(const char *name);

#endif /* JUST_MONIKA_GL_PRIVATE_TEXTURE_H */
