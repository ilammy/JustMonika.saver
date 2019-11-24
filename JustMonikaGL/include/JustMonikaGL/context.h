//
//  context.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_CONTEXT_H
#define JUST_MONIKA_GL_CONTEXT_H

struct just_monika;

struct just_monika* just_monika_make(void);

void just_monika_free(struct just_monika *context);

#endif /* JUST_MONIKA_GL_CONTEXT_H */
