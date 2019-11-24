//
//  JustMonikaView.h
//  JustMonikaView
//
//  Created by Alexei Lozovsky on 2019-11-24.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import <AppKit/AppKit.h>

//! Project version number for JustMonikaView.
FOUNDATION_EXPORT double JustMonikaViewVersionNumber;

//! Project version string for JustMonikaView.
FOUNDATION_EXPORT const unsigned char JustMonikaViewVersionString[];

// Yes, I know that Apple deprecates OpenGL in favor of its Metal.
// You don't need to remind me about that in every build.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

IB_DESIGNABLE
@interface JustMonikaView : NSOpenGLView

@end

#pragma clang diagnostic pop
