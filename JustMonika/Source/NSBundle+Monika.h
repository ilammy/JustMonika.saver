// SPDX-License-Identifier: GPL-3.0-only
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Monika)

+ (nullable NSBundle *)justMonika;

- (nullable NSString *)bundleName;
- (nullable NSString *)versionString;

@end

NS_ASSUME_NONNULL_END

// Since we're a screen saver plugin bundle, we can't just use the main bundle
#define JMLocalizedString(key, comment) \
    NSLocalizedStringFromTableInBundle((key), @"JustMonika", NSBundle.justMonika, (comment))
