//
//  NSView+Subviews.m
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-23.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

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
