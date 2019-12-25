/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#ifndef JUST_MONIKA_GL_H
#define JUST_MONIKA_GL_H

#if defined(__GNUC__) || defined(__clang__)
#define JUST_MONIKA_API __attribute__((visibility("default")))
#else
#define JUST_MONIKA_API
#endif

/**
 * Opaque handle to JustMonikaGL state.
 */
struct just_monika;

/**
 * Allocates a new Monika.
 *
 * @returns NULL in case of allocation failure.
 */
JUST_MONIKA_API
struct just_monika* just_monika_make(void);

/**
 * Deletes this Monika.
 */
JUST_MONIKA_API
void just_monika_free(struct just_monika *context);

/**
 * Initializes Monika.
 *
 * Load OpenGL resources and prepare everything for rendering.
 *
 * @returns zero in case of success, non-zero value otherwise.
 */
JUST_MONIKA_API
int just_monika_init(struct just_monika *context);

/**
 * Sets OpenGL viewport.
 *
 * @param width  new width in pixels
 * @param height new height in pixels
 *
 * @returns zero in case of success, non-zero value otherwise.
 */
JUST_MONIKA_API
int just_monika_set_viewport(struct just_monika *context,
                             unsigned width,
                             unsigned height);

/**
 * Renders Monika.
 *
 * Draws a single frame into the current OpenGL context.
 *
 * @returns zero in case of success, non-zero value otherwise.
 */
JUST_MONIKA_API
int just_monika_draw(struct just_monika *context);

/**
 * Starts animation timer.
 *
 * Monika will animate until stopped.
 *
 * @returns zero in case of success, non-zero value otherwise.
 */
JUST_MONIKA_API
int just_monika_start_animation(struct just_monika *context);

/**
 * Stop animation timer.
 *
 * Monika will freeze-frame until started.
 *
 * @returns zero in case of success, non-zero value otherwise.
 */
JUST_MONIKA_API
int just_monika_stop_animation(struct just_monika *context);

#endif /* JUST_MONIKA_GL_H */
