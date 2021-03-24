// SPDX-License-Identifier: GPL-3.0-only
// JustMonikaPreview
// Copyright (c) 2019 ilammy's tearoom

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Load the embedded screen saver plugin
        NSString *pluginPath = [[NSBundle mainBundle] builtInPlugInsPath];
        NSString *monikaPath = [pluginPath stringByAppendingPathComponent:@"JustMonika.saver"];
        NSBundle *justMonika = [NSBundle bundleWithPath:monikaPath];
        [justMonika load];
    }
    return NSApplicationMain(argc, argv);
}
