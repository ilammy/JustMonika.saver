// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "NSBundle+Monika.h"

#import "JustMonikaView.h"

@implementation NSBundle (Monika)

+ (nullable NSBundle *)justMonika
{
    return [NSBundle bundleForClass:JustMonikaView.class];
}

- (NSString *)bundleName
{
    return self.infoDictionary[(NSString *)kCFBundleNameKey];
}

- (NSString *)versionString
{
    return self.infoDictionary[@"CFBundleShortVersionString"];
}

@end
