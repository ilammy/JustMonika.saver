/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#include "context.h"

#include <stdlib.h>

/*
 * Matches dimensions of the main image.
 */
static const GLfloat default_screen_width = 1280;
static const GLfloat default_screen_height = 720;

struct just_monika* just_monika_make(void)
{
    struct just_monika *context = calloc(1, sizeof(*context));
    if (!context) {
        return NULL;
    }
    context->screen_width = default_screen_width;
    context->screen_height = default_screen_height;
    context->viewport_width = default_screen_width;
    context->viewport_height = default_screen_height;
    return context;
}

void just_monika_free(struct just_monika *context)
{
    free(context);
}

int just_monika_set_visible(struct just_monika *context, int show)
{
    context->show_monika_room = !show;
    return 0;
}
