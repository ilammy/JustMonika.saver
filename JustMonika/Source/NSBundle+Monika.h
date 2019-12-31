// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Monika)

+ (nullable NSBundle *)justMonika;

- (nullable NSString *)versionString;

@end

NS_ASSUME_NONNULL_END
