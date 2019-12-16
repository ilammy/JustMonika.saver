//
//  JustMonikaView.h
//  JustMonikaView
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import <AppKit/AppKit.h>

// Yes, I know that Apple deprecates OpenGL in favor of its Metal.
// You don't need to remind me about that in every build.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

struct just_monika_settings;

IB_DESIGNABLE
@interface JustMonikaGLView : NSOpenGLView

- (instancetype)initWithFrame:(NSRect)frameRect;

- (void)startAnimation;
- (void)stopAnimation;

- (void)configureWith:(const struct just_monika_settings *)settings;

@end

#pragma clang diagnostic pop
