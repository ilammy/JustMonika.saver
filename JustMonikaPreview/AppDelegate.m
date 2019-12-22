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
#import "JustMonikaGL.h"

@interface AppDelegate ()

@property(weak) IBOutlet NSWindow *window;
@property(weak) IBOutlet JustMonikaView *view;
@property(weak) IBOutlet NSButton *settingsButton;

@property (weak) IBOutlet NSWindow *adjustments;
@property (weak) IBOutlet NSSlider *offsetXSlider;
@property (weak) IBOutlet NSSlider *offsetYSlider;
@property (weak) IBOutlet NSTextField *offsetXText;
@property (weak) IBOutlet NSTextField *offsetYText;

@property (weak) IBOutlet NSTextField *biasAText;
@property (weak) IBOutlet NSTextField *biasBText;
@property (weak) IBOutlet NSTextField *scaleAText;
@property (weak) IBOutlet NSTextField *scaleBText;

@property (weak) IBOutlet NSTextField *blurText;
@property (weak) IBOutlet NSSlider *blurSlider;

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

    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
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

- (IBAction)adjustButtonPressed:(id)sender
{
    [self.adjustments orderFront:sender];
}

- (IBAction)offsetSliderDidUpdate:(id)sender
{
    self.offsetXText.doubleValue = round(self.offsetXSlider.doubleValue);
    self.offsetYText.doubleValue = round(self.offsetYSlider.doubleValue);

    if (sender == self.blurSlider) {
        self.blurText.doubleValue = self.blurSlider.doubleValue;
    }

    struct just_monika_settings settings = {
        .offsetX = self.offsetXSlider.doubleValue,
        .offsetY = self.offsetYSlider.doubleValue,
        .biasA = self.biasAText.doubleValue,
        .biasB = self.biasBText.doubleValue,
        .scaleA = self.scaleAText.doubleValue,
        .scaleB = self.scaleBText.doubleValue,
        .blur_parameter = self.blurText.doubleValue,
    };
    [self.view.monika configureWith:&settings];
}

@end
