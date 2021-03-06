// SPDX-License-Identifier: GPL-3.0-only
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaSettings.h"

#import <ScreenSaver/ScreenSaver.h>

#import "NSBundle+Monika.h"

@interface JustMonikaSettings ()

@property (nonatomic) NSUserDefaults *defaults;

@end

@implementation JustMonikaSettings

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Screen Savers are a little bit different from normal applications
        // since they are all plugins. The framework provides us a special way
        // to get an instance of NSUserDefaults for out needs. Documentation
        // recommends to use bundle identifier as a module name.
        NSString *moduleName = NSBundle.justMonika.bundleIdentifier;
        self.defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];
        // Also note that we need to explicity call "synchronize" because
        // otherwise the settings might not end up being persisted.
        [self.defaults synchronize];
        [self.defaults registerDefaults:@{
            settingsSheetEnabledKey: @YES,
        }];
    }
    return self;
}

static NSString *settingsSheetEnabledKey = @"settingsSheetEnabled";

- (BOOL)settingsSheetEnabled
{
    [self.defaults synchronize];
    return [self.defaults boolForKey:settingsSheetEnabledKey];
}

- (void)setSettingsSheetEnabled:(BOOL)enabled
{
    [self.defaults setBool:enabled forKey:settingsSheetEnabledKey];
    [self.defaults synchronize];
}

- (void)reset
{
    [self.defaults removeObjectForKey:settingsSheetEnabledKey];
    [self.defaults synchronize];
}

@end
