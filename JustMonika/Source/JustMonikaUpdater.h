// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <Foundation/Foundation.h>
#import <Sparkle/Sparkle.h>

NS_ASSUME_NONNULL_BEGIN

@class JustMonikaView;

@interface JustMonikaUpdater : NSObject <SUUpdaterDelegate>

+ (instancetype)forView:(JustMonikaView *)view;

@end

NS_ASSUME_NONNULL_END
