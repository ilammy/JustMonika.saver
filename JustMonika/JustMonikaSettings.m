//
//  JustMonikaSettings.m
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-23.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "JustMonikaSettings.h"

#import <ScreenSaver/ScreenSaver.h>

static NSString *settingsModuleName = @"net.ilammy.JustMonika";
static NSString *settingsSheetEnabledKey = @"settingsSheetEnabled";
static const NSInteger kSettingsSheetEnabledUnknown = 0;
static const NSInteger kSettingsSheetEnabledNo      = 1;
static const NSInteger kSettingsSheetEnabledYes     = 2;

// For per-user installation the settings are stored here:
// ~/Library/Preferences/ByHost/net.ilammy.JustMonika.7CCB5D00-8F7D-5C99-8F6A-E5398EFECCDE.plist

@implementation JustMonikaSettings

static ScreenSaverDefaults* getDefaults()
{
    return [ScreenSaverDefaults defaultsForModuleWithName:settingsModuleName];
}

+ (BOOL)settingsSheetEnabled
{
    ScreenSaverDefaults *defaults = getDefaults();
    [defaults synchronize];
    NSInteger value = [defaults integerForKey:settingsSheetEnabledKey];
    switch (value) {
        case kSettingsSheetEnabledNo:
            return NO;
        case kSettingsSheetEnabledYes:
            return YES;
        case kSettingsSheetEnabledUnknown:
            return YES;
    }
    return YES;
}

+ (void)setSettingsSheetEnabled:(BOOL)enabled
{
    ScreenSaverDefaults *defaults = getDefaults();
    [defaults setInteger:(enabled ? kSettingsSheetEnabledYes : kSettingsSheetEnabledNo)
                  forKey:settingsSheetEnabledKey];
    [defaults synchronize];
}

@end
