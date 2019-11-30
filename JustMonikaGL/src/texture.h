//
//  texture.h
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-28.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_PRIVATE_TEXTURE_H
#define JUST_MONIKA_GL_PRIVATE_TEXTURE_H

#include <JustMonikaGL/init.h>
#include <JustMonikaGL/context.h>

#include "opengl.h"

GLuint load_texture(struct just_monika *context, struct just_monika_texture_image *image);

#endif /* JUST_MONIKA_GL_PRIVATE_TEXTURE_H */
