// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <ScreenSaver/ScreenSaver.h>

IB_DESIGNABLE
@interface JustMonikaView : ScreenSaverView

@property (nonatomic) BOOL showVersionText;

/// Initialize this view as a preview in awakeFromNib.
@property (nonatomic) IBInspectable BOOL initAsPreview;

@end
