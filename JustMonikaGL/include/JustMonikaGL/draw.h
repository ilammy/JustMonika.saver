//
//  draw.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#ifndef JUST_MONIKA_GL_DRAW_H
#define JUST_MONIKA_GL_DRAW_H

struct just_monika;

int just_monika_draw(struct just_monika *context);

int just_monika_start_animation(struct just_monika *context);

int just_monika_stop_animation(struct just_monika *context);

#endif /* JUST_MONIKA_GL_DRAW_H */
