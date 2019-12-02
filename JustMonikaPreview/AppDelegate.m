//
//  AppDelegate.m
//  JustMonikaPreview
//
//  Created by Alexei Lozovsky on 2019-11-17.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "AppDelegate.h"

#import "JustMonikaView.h"
#import "JustMonikaSettings.h"

@interface AppDelegate ()

@property(weak) IBOutlet NSWindow *window;
@property(weak) IBOutlet JustMonikaView *view;
@property(weak) IBOutlet NSButton *settingsButton;

@end

@implementation AppDelegate

//static const int fps = 30;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self.view startAnimation];
//
//    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0/fps
//                                            repeats:YES
//                                              block:^(NSTimer *timer) {
//        self.view.needsDisplay = YES;
//    }];
//
//    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (IBAction)openSettings:(id)sender
{
//    [NSApp beginSheet:self.view.configureSheet
//       modalForWindow:self.window
//        modalDelegate:self
//       didEndSelector:@selector(settingsDidClose:returnCode:contextInfo:)
//          contextInfo:nil];
//    [self.window beginSheet:self.view.configureSheet
//          completionHandler:^(NSModalResponse returnCode){
//        self.settingsButton.enabled = self.view.hasConfigureSheet;
//    }];
}

- (void)settingsDidClose:(NSWindow *)sheet
              returnCode:(NSInteger)returnCode
             contextInfo:(void *)contextInfo
{
//    self.settingsButton.enabled = self.view.hasConfigureSheet;
}

- (IBAction)resetSettings:(id)sender
{
//    NSString *pluginPath = [[NSBundle mainBundle] builtInPlugInsPath];
//    NSString *monikaPath = [pluginPath stringByAppendingPathComponent:@"JustMonika.saver"];
//    NSBundle *justMonika = [NSBundle bundleWithPath:monikaPath];
//
//    // Dynamically because we're not linked against the plugin.
//    // God bless Objective-C runtime and its dynamism.
//    [[[justMonika classNamed:@"JustMonikaSettings"] new] reset];
}

@end
