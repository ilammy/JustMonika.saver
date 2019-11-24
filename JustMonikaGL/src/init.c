//
//  init.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "init.h"

#include <OpenGL/gl.h>

int just_monika_init(struct just_monika *context)
{
    /* Nice warm pink color */
    glClearColor(251.0f/256.0f, 231.0f/256.0f, 243.0f/256.0f, 0.0f);

    return 0;
}
