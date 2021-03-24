// SPDX-License-Identifier: GPL-3.0-only
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <Foundation/Foundation.h>

#import "JustMonikaView.h"

@interface JustMonikaSettings : NSObject

@property (assign) BOOL settingsSheetEnabled;

- (void)reset;

@end

// Expose this property to the preview app
@interface JustMonikaView (Settings)
@property (readonly,strong) JustMonikaSettings *settings;
@end
