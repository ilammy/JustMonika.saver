// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <AppKit/AppKit.h>

// Yes, I know that Apple deprecates OpenGL in favor of its Metal.
// You don't need to remind me about that in every build.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

@interface JustMonikaGLView : NSOpenGLView

- (instancetype)initWithFrame:(NSRect)frameRect;

- (void)startAnimation;
- (void)stopAnimation;

@end

#pragma clang diagnostic pop
