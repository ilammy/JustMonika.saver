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
#import "JustMonikaGLView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet JustMonikaView *view;

@property (weak) IBOutlet NSWindow *adjustments;
@property (weak) IBOutlet NSButton *animationCheckBox;

@property (weak) IBOutlet NSButton *settingsButton;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // We have to do it manually since we're not Screen Saver framework
    [self.view.monika startAnimation];

    NSTimer *timer = [NSTimer timerWithTimeInterval:self.view.animationTimeInterval
                                            repeats:YES
                                              block:^(NSTimer *timer) {
        [self.view animateOneFrame];
    }];

    // Useful to have both in case we have some slider for live updates
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];

    [self syncSettingsButtonState];
}

#pragma mark - Configuration sheet

- (IBAction)openSettings:(id)sender
{
    [self.window beginSheet:self.view.configureSheet
          completionHandler:^(NSModalResponse response){
        [self syncSettingsButtonState];
    }];
}

- (IBAction)resetSettings:(id)sender
{
    [self.view.settings reset];
    [self syncSettingsButtonState];
}

- (void)syncSettingsButtonState
{
    self.settingsButton.enabled = self.view.hasConfigureSheet;
}

#pragma mark - Adjustments

- (IBAction)adjustButtonPressed:(id)sender
{
    [self.adjustments orderFront:sender];
}

- (IBAction)animationCheckBoxPressed:(id)sender
{
    // We need to call JustMonikaGLView directly because we are not
    // Screen Saver framework and did not initialize its timer.
    if (self.animationCheckBox.state == YES) {
        [self.view.monika startAnimation];
    } else {
        [self.view.monika stopAnimation];
    }
}

@end
