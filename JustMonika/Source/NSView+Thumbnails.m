// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "NSView+Thumbnails.h"

@implementation NSView (Thumbnails)

// Take care to check whether the view responds to the selectors we need.
// If it doesn't then the runtime may and usually will throw an exception.

- (NSString *)thumbnailTitle
{
    if ([self respondsToSelector:@selector(title)]) {
        return [self performSelector:@selector(title)];
    }
    return nil;
}

- (void)setThumbnailTitle:(NSString *)title
{
    if ([self respondsToSelector:@selector(setTitle:)]) {
        [self performSelector:@selector(setTitle:)
                   withObject:title];
    }
}

- (NSImage *)thumbnailImage
{
    if ([self respondsToSelector:@selector(image)]) {
        return [self performSelector:@selector(image)];
    }
    return nil;
}

- (void)setThumbnailImage:(NSImage *)image
{
    if ([self respondsToSelector:@selector(setImage:)]) {
        [self performSelector:@selector(setImage:)
                   withObject:image];
    }
}

@end
