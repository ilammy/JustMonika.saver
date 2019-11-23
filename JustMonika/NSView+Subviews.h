//
//  NSView+Subviews.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-23.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSView (Subviews)

- (NSArray<NSView*>*)subviewsRecursive;

@end
