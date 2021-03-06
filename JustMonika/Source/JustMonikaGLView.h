// SPDX-License-Identifier: GPL-3.0-only
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <AppKit/AppKit.h>

#import "JustMonikaView.h"

// Yes, I know that Apple deprecates OpenGL in favor of its Metal.
// You don't need to remind me about that in every build.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

@interface JustMonikaGLView : NSOpenGLView

- (instancetype)initWithFrame:(NSRect)frameRect;

- (void)startAnimation;
- (void)stopAnimation;

- (void)showMonika:(BOOL)visible;

@end

#pragma clang diagnostic pop

// Expose this property to the preview app
@interface JustMonikaView (GLView)
@property (readonly, weak) JustMonikaGLView *monika;
@end
