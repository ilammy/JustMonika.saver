// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "NSView+Subviews.h"

@implementation NSView (Subviews)

- (NSArray<NSView*>*)subviewsRecursive
{
    NSMutableArray<NSView*> *subviews = self.subviews.mutableCopy;
    for (NSUInteger i = 0; i < subviews.count; i++) {
        [subviews addObjectsFromArray:[[subviews objectAtIndex:i] subviews]];
    }
    return subviews;
}

@end
