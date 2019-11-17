//
//  main.m
//  JustMonikaPreview
//
//  Created by Alexei Lozovsky on 2019-11-17.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

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
