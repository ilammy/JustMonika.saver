//
//  AppDelegate.m
//  JustMonikaPreview
//
//  Created by Alexei Lozovsky on 2019-11-17.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "AppDelegate.h"

#import "JustMonikaView.h"

@interface AppDelegate ()

@property(weak) IBOutlet NSWindow *window;
@property(weak) IBOutlet JustMonikaView *view;
@property(weak) IBOutlet NSButton *settingsButton;

@end

@implementation AppDelegate

- (IBAction)openSettings:(id)sender
{
//    [NSApp beginSheet:self.view.configureSheet
//       modalForWindow:self.window
//        modalDelegate:self
//       didEndSelector:@selector(settingsDidClose:returnCode:contextInfo:)
//          contextInfo:nil];
    [self.window beginSheet:self.view.configureSheet
          completionHandler:^(NSModalResponse returnCode){
        self.settingsButton.enabled = self.view.hasConfigureSheet;
    }];
}

- (void)settingsDidClose:(NSWindow *)sheet
              returnCode:(NSInteger)returnCode
             contextInfo:(void *)contextInfo
{
    self.settingsButton.enabled = self.view.hasConfigureSheet;
}

@end
