// SPDX-License-Identifier: GPL-3.0-only
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
    NSString *result;
    result = self.localizedInfoDictionary[(NSString *)kCFBundleNameKey];
    if (result) {
        return result;
    }
    result = self.infoDictionary[(NSString *)kCFBundleNameKey];
    if (result) {
        return result;
    }
    return nil;
}

- (NSString *)versionString
{
    return self.infoDictionary[@"CFBundleShortVersionString"];
}

@end
