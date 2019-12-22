//
//  NSBundle+Name.m
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-12-22.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "NSBundle+Name.h"

@implementation NSBundle (Name)

- (NSString *)localizedBundleName
{
    NSString *bundleNameKey = (NSString *)kCFBundleNameKey;
    NSString *name;
    if ((name = self.localizedInfoDictionary[bundleNameKey])) {
        return name;
    }
    if ((name = self.infoDictionary[bundleNameKey])) {
        return name;
    }
    return nil;
}

@end
