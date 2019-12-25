/* SPDX-License-Identifier: Apache-2.0 */
/* JustMonikaGL, (c) 2019 ilammy's tearoom */

#ifndef JUST_MONIKA_GL_PRIVATE_TIMER_H
#define JUST_MONIKA_GL_PRIVATE_TIMER_H

#include <stdbool.h>
#include <time.h>

struct clock {
    bool ticking;
    struct timespec start;
    struct timespec current;
};

int clock_start(struct clock *clock);

int clock_stop(struct clock *clock);

int clock_sync(struct clock *clock);

float clock_seconds_elapsed(const struct clock *clock);

#endif /* JUST_MONIKA_GL_PRIVATE_TIMER_H */
