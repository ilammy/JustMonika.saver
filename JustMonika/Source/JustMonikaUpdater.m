// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaUpdater.h"

#import "JustMonikaView.h"

@interface JustMonikaUpdater ()

@property (strong) SUUpdater *updater;
@property (weak) JustMonikaView *view;

@end

@implementation JustMonikaUpdater

- (instancetype)initWithUpdater:(SUUpdater *)updater andView:(JustMonikaView *)view
{
    self = [super init];
    if (self) {
        self.updater = updater;
        self.updater.delegate = self;
        self.view = view;
    }
    return self;
}

+ (instancetype)forView:(JustMonikaView *)view
{
    NSBundle *thisBundle = [NSBundle bundleForClass:JustMonikaUpdater.class];
    SUUpdater *updater = [SUUpdater updaterForBundle:thisBundle];
    updater.sendsSystemProfile = NO; // don't you ever dare
    return [[JustMonikaUpdater alloc] initWithUpdater:updater
                                              andView:view];
}

#pragma mark - SUUpdaterDelegate

// This is a screen saver and it cannot be relaunched the way application can.
// We cannot prompt for an update when the screen saver is running. In fact,
// we should not ever prompt for anything unless System Preferences is open
// and the user is focused on configuring our screen saver. In any case, we
// should not reopen the application (ScreenSaverEngine) because that will
// lock the screen unexpectedly for the user.
- (BOOL)updaterShouldRelaunchApplication:(SUUpdater *)updater
{
    return NO;
}

// Prompt right away at the first launch after installation, normally when
// System Preferences opens with a preview. This is bad UX because the first
// thing the user sees after installation is this (not really welcome) popup.
// I'm sorry, we have to do it now because we might not get a second chance:
// if the user selects Monika, closes the dialog, and never opens it again
// then we have no suitable moments to ask for permission. We cannot do it
// when the screen saver is running since any alerts will be obscured by
// the active screen saver (but will still get keyboard focus!) One thing
// that we can do is show a notification "Could you please open the System
// Preferences dialog again and *then* see a popup we want to show you?"
// on the first screen saver activation, but that's even worse UX, I think.
// So get over with it now.
- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater
{
    return self.view.isPreview;
}

// Similar to above, no alerts if we're actually running a screen saver.
// We'll post a notification instead. If we're in preview then it's okay
// to show a modal alert window because the user's focus is on us.
- (BOOL)updaterShouldShowUpdateAlertForScheduledUpdate:(SUUpdater *)updater
                                               forItem:(SUAppcastItem *)item
{
    return self.view.isPreview;
}

@end
