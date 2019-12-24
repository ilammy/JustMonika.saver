//
//  JustMonikaView.h
//  JustMonikaView
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "JustMonikaView.h"

// Yes, I know that Apple deprecates OpenGL in favor of its Metal.
// You don't need to remind me about that in every build.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

struct just_monika_settings;

@interface JustMonikaGLView : NSOpenGLView

- (instancetype)initWithFrame:(NSRect)frameRect;

- (void)startAnimation;
- (void)stopAnimation;

@end

#pragma clang diagnostic pop

// Expose this property to the preview app
@interface JustMonikaView (OpenGLView)
@property (readonly,weak) JustMonikaGLView *monika;
@end
