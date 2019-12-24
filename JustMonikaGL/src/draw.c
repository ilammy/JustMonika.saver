//
//  draw.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "draw.h"

static void draw_into_framebuffer(struct just_monika *context)
{
    /*
     * Draw into our framebuffer instead of the default one,
     * set the viewport appropriately, clear the screen,
     * and select the main shader program.
     */
    glBindFramebuffer(GL_FRAMEBUFFER, context->screen_framebuffer);
    glViewport(0, 0, context->screen_width, context->screen_height);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(context->screen_program);

    /* Bind textures to samplers */

    glUniform1i(context->monika_bg_sampler, 0);
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(GL_TEXTURE_RECTANGLE, context->monika_bg_texture);

    glUniform1i(context->monika_bg_highlight_sampler, 1);
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_RECTANGLE, context->monika_bg_highlight_texture);

    glUniform1i(context->mask_2_sampler, 2);
    glActiveTexture(GL_TEXTURE0 + 2);
    glBindTexture(GL_TEXTURE_RECTANGLE, context->mask_2_texture);

    glUniform1i(context->mask_3_sampler, 3);
    glActiveTexture(GL_TEXTURE0 + 3);
    glBindTexture(GL_TEXTURE_RECTANGLE, context->mask_3_texture);

    glUniform1i(context->mask_sampler, 4);
    glActiveTexture(GL_TEXTURE0 + 4);
    glBindTexture(GL_TEXTURE_RECTANGLE, context->mask_texture);

    glUniform1i(context->maskb_sampler, 5);
    glActiveTexture(GL_TEXTURE0 + 5);
    glBindTexture(GL_TEXTURE_RECTANGLE, context->maskb_texture);

    /* Set other uniform parameters */

    glUniform1f(context->time_location, clock_seconds_elapsed(&context->clock));

    /* Do actual drawing now... */

    glEnableVertexAttribArray(context->screen_xy_location);

    glBindBuffer(GL_ARRAY_BUFFER, context->xy_buffer);
    glVertexAttribPointer(context->screen_xy_location,
                          2,        /* 2D XY coordinates */
                          GL_FLOAT, /* typed as floats */
                          GL_FALSE, /* not normalized */
                          0,        /* stride */
                          NULL);    /* offset */

    /* Draw a quad out of 2 x 3 point set. */
    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDisableVertexAttribArray(context->screen_xy_location);
}

static void transfer_to_screen(struct just_monika *context)
{
    /*
     * Draw into the default framebuffer now, reset the viewport
     * and clear the screen again, use a simpler shader program.
     */
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, context->viewport_width, context->viewport_height);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(context->viewport_program);

    /* Bind textures to samplers */

    glUniform1i(context->screen_sampler, 0);
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(GL_TEXTURE_RECTANGLE, context->screen_texture);

    /* Set other uniform parameters */

    glUniformMatrix4fv(context->viewport_xy_transform_location,
                       1,       /* one 4x4 matrix */
                       GL_TRUE, /* row-major order */
                       context->xy_transform_matrix);

    glUniform1f(context->blur_radius_location, context->blur_radius);

    /* Do drawing once more */

    glEnableVertexAttribArray(context->viewport_xy_location);

    glBindBuffer(GL_ARRAY_BUFFER, context->xy_buffer);
    glVertexAttribPointer(context->viewport_xy_location,
                          2,        /* 2D XY coordinates */
                          GL_FLOAT, /* typed as floats */
                          GL_FALSE, /* not normalized */
                          0,        /* stride */
                          NULL);    /* offset */

    /* Draw a quad out of 2 x 3 point set. */
    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDisableVertexAttribArray(context->viewport_xy_location);
}

int just_monika_draw(struct just_monika *context)
{
    clock_sync(&context->clock);

    draw_into_framebuffer(context);
    transfer_to_screen(context);

    return 0;
}

int just_monika_start_animation(struct just_monika *context)
{
    clock_start(&context->clock);
    return 0;
}

int just_monika_stop_animation(struct just_monika *context)
{
    clock_stop(&context->clock);
    return 0;
}
