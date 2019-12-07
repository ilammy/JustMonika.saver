//
//  draw.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "draw.h"

int just_monika_draw(struct just_monika *context)
{
    if (context->clock_ticking) {
        clock_sync(&context->clock);
    }

    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(context->screen_program);

    glUniformMatrix4fv(context->xy_transform_location,
                       1,       /* one 4x4 matrix */
                       GL_TRUE, /* row-major order */
                       context->xy_transform_matrix);

    glUniformMatrix4fv(context->uv_transform_location,
                       1,       /* one 4x4 matrix */
                       GL_TRUE, /* row-major order */
                       context->uv_transform_matrix);

    glUniform1i(context->monika_bg_sampler, 0);
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(GL_TEXTURE_2D, context->monika_bg_texture);

    glUniform1i(context->monika_bg_highlight_sampler, 1);
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_2D, context->monika_bg_highlight_texture);

    glUniform1i(context->mask_2_sampler, 2);
    glActiveTexture(GL_TEXTURE0 + 2);
    glBindTexture(GL_TEXTURE_2D, context->mask_2_texture);

    glUniform1i(context->mask_3_sampler, 3);
    glActiveTexture(GL_TEXTURE0 + 3);
    glBindTexture(GL_TEXTURE_2D, context->mask_3_texture);

    glUniform1f(context->time, clock_seconds_elapsed(&context->clock));

    glEnableVertexAttribArray(context->xy_location);
    glEnableVertexAttribArray(context->uv_location);

    glBindBuffer(GL_ARRAY_BUFFER, context->xy_buffer);
    glVertexAttribPointer(context->xy_location,
                          2,        /* 2D XY coordinates */
                          GL_FLOAT, /* typed as floats */
                          GL_FALSE, /* not normalized */
                          0,        /* stride */
                          NULL);    /* offset */

    glBindBuffer(GL_ARRAY_BUFFER, context->uv_buffer);
    glVertexAttribPointer(context->uv_location,
                          2,        /* 2D UV coordinates */
                          GL_FLOAT, /* typed as floats */
                          GL_FALSE, /* not normalized */
                          0,        /* stride */
                          NULL);    /* offset */

    /* Draw a quad out of 2 x 3 point set. */
    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDisableVertexAttribArray(context->xy_location);
    glDisableVertexAttribArray(context->uv_location);

    return 0;
}

int just_monika_start_animation(struct just_monika *context)
{
    context->clock_ticking = true;
    clock_start(&context->clock);
    return 0;
}

int just_monika_stop_animation(struct just_monika *context)
{
    context->clock_ticking = false;
    return 0;
}
