//
//  init.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_INIT_H
#define JUST_MONIKA_GL_INIT_H

struct just_monika;

int just_monika_init(struct just_monika *context);

int just_monika_set_viewport(struct just_monika *context, unsigned width, unsigned height);

#endif /* JUST_MONIKA_GL_INIT_H */
