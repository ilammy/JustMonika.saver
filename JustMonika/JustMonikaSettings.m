//
//  JustMonikaSettings.m
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-23.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "JustMonikaSettings.h"

#import <ScreenSaver/ScreenSaver.h>

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
        NSBundle *thisBundle = [NSBundle bundleForClass:self.class];
        NSString *moduleName = thisBundle.bundleIdentifier;
        self.defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];
    }
    return self;
}

// Since NSUserDefaults does not provide an explicit way to determine whether
// a setting has been set or not, we treat the implicit zero value specially.
// Also note that we *do need* to use "synchronize" with ScreenSaverDefaults.
static NSString *settingsSheetEnabledKey = @"settingsSheetEnabled";
static const NSInteger kSettingsSheetEnabledUnknown = 0;
static const NSInteger kSettingsSheetEnabledNo      = 1;
static const NSInteger kSettingsSheetEnabledYes     = 2;

- (BOOL)settingsSheetEnabled
{
    [self.defaults synchronize];
    NSInteger value = [self.defaults integerForKey:settingsSheetEnabledKey];
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

- (void)setSettingsSheetEnabled:(BOOL)enabled
{
    NSInteger value = (enabled ? kSettingsSheetEnabledYes : kSettingsSheetEnabledNo);
    [self.defaults setInteger:value forKey:settingsSheetEnabledKey];
    [self.defaults synchronize];
}

@end
