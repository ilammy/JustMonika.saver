//
//  timer.c
//  JustMonikaGL
//
//  Created by Alexei Lozovsky on 2019-12-01.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#include "timer.h"

int clock_start(struct clock *clock)
{
    int res;
    struct timespec diff = {
        clock->current.tv_sec - clock->start.tv_sec,
        clock->current.tv_nsec - clock->start.tv_nsec,
    };
    res = clock_gettime(CLOCK_MONOTONIC, &clock->start);
    if (res) {
        return res;
    }
    clock->current = clock->start;
    /* Preserve existing difference so that this is more like "restart" */
    clock->start.tv_sec -= diff.tv_sec;
    clock->start.tv_nsec -= diff.tv_nsec;
    return 0;
}

int clock_sync(struct clock *clock)
{
    return clock_gettime(CLOCK_MONOTONIC, &clock->current);
}

float clock_seconds_elapsed(const struct clock *clock)
{
    float elapsed = clock->current.tv_sec - clock->start.tv_sec;
    elapsed += (clock->current.tv_nsec - clock->start.tv_nsec) / 1000000000.0f;
    return elapsed;
}
