// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <Foundation/Foundation.h>

#import "JustMonikaView.h"

@interface JustMonikaSettings : NSObject

@property (assign) BOOL settingsSheetEnabled;

@property (assign) BOOL updateChecksAllowed;
@property (assign) BOOL updateChecksPermissionRequested;
@property (strong) NSDate *lastCheckDate;
@property (strong) NSString *lastSeenVersionString;

- (void)reset;

@end

// Expose this property to the preview app
@interface JustMonikaView (Settings)
@property (readonly,strong) JustMonikaSettings *settings;
@end
