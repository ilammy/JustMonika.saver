// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaView.h"

@interface JustMonikaView (Private)

@property (nonatomic) BOOL showVersionText;

- (void)showCriticalUpdateBannerForVersion:(NSString *)newVersion;

@end
