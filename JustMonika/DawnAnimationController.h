//
//  DawnAnimationController.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-19.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import <QuartzCore/CoreAnimation.h>

@interface DawnAnimationController : NSObject

- (void)addLayer:(CALayer *)layer;

- (void)startAnimation;
- (void)stopAnimation;

@end
