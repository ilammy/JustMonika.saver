// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonikaPreview
// Copyright (c) 2019 ilammy's tearoom

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
    [self syncAnimationState];
    [self syncSettingsButtonState];

    // We still need to run a timer for redraws since JustMonikaView does not
    // update itself. It updates the image when "animateOneFrame" is called.
    NSTimer *timer = [NSTimer timerWithTimeInterval:self.view.animationTimeInterval
                                            repeats:YES
                                              block:^(NSTimer *timer) {
        [self.view animateOneFrame];
    }];

    // Useful to have both in case we have some slider for live updates
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}

- (void)syncAnimationState
{
    if (self.animationCheckBox.state == YES) {
        [self.view startAnimation];
    } else {
        [self.view stopAnimation];
    }
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
    [self syncAnimationState];
}

@end
