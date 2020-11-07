// SPDX-License-Identifier: GPL-3.0-or-later
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
            updateChecksAllowedKey: @NO,
            updateChecksPermissionRequestedKey: @NO,
        }];
    }
    return self;
}

static NSString *settingsSheetEnabledKey = @"settingsSheetEnabled";
static NSString *updateChecksAllowedKey = @"updateChecksAllowed";
static NSString *updateChecksPermissionRequestedKey = @"updateChecksPermissionRequested";
static NSString *lastCheckDateKey = @"lastCheckDate";
static NSString *lastSeenVersionStringKey = @"lastSeenVersionString";

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

- (BOOL)updateChecksAllowed
{
    [self.defaults synchronize];
    return [self.defaults boolForKey:updateChecksAllowedKey];
}

- (void)setUpdateChecksAllowed:(BOOL)allowed
{
    [self.defaults setBool:allowed forKey:updateChecksAllowedKey];
    [self.defaults synchronize];
}

- (BOOL)updateChecksPermissionRequested
{
    [self.defaults synchronize];
    return [self.defaults boolForKey:updateChecksPermissionRequestedKey];
}

- (void)setUpdateChecksPermissionRequested:(BOOL)requested
{
    [self.defaults setBool:requested forKey:updateChecksPermissionRequestedKey];
    [self.defaults synchronize];
}

- (NSDate *)lastCheckDate
{
    [self.defaults synchronize];
    return [self.defaults valueForKey:lastCheckDateKey];
}

- (void)setLastCheckDate:(NSDate *)date
{
    [self.defaults setValue:date forKey:lastCheckDateKey];
    [self.defaults synchronize];
}

- (NSString *)lastSeenVersionString
{
    [self.defaults synchronize];
    return [self.defaults stringForKey:lastSeenVersionStringKey];
}

- (void)setLastSeenVersionString:(NSString *)versionString
{
    [self.defaults setValue:versionString forKey:lastSeenVersionStringKey];
    [self.defaults synchronize];
}

- (void)reset
{
    [self.defaults removeObjectForKey:settingsSheetEnabledKey];
    [self.defaults synchronize];
}

@end
