//
//  JustMonikaView.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-17.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

#import "JustMonikaGLView.h"

IB_DESIGNABLE
@interface JustMonikaView : ScreenSaverView

@property (weak) JustMonikaGLView *monika;

@end
