//
//  init.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_INIT_H
#define JUST_MONIKA_GL_INIT_H

#include <stdio.h>

struct just_monika;

typedef FILE*(*open_resource)(const char *path);

void just_monika_set_open_resource_callback(struct just_monika *context, open_resource cb);

int just_monika_init(struct just_monika *context);

int just_monika_set_viewport(struct just_monika *context, unsigned width, unsigned height);

#endif /* JUST_MONIKA_GL_INIT_H */
