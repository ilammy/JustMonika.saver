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
    res = clock_gettime(CLOCK_MONOTONIC, &clock->start);
    if (res) {
        return res;
    }
    clock->current = clock->start;
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
