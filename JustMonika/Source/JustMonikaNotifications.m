// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaNotifications.h"

#import <UserNotifications/UserNotifications.h>

@interface JustMonikaNotification ()

@property (nonatomic,readonly) NSString *identifier;

@end

@interface JustMonikaNotifications () <NSUserNotificationCenterDelegate>

@property (nonatomic,assign) BOOL notificationsAllowed;
@property (nonatomic,strong) NSString *updateAlertCategory;

@end

@implementation JustMonikaNotifications

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (@available(macOS 10.14, *)) {
            [self requestNotificationPermission];
            [self registerNotificationCategories];
        } else {
            [self initUserNotificationDelegate];
            [self setNotificationsAllowed:YES];
        }
    }
    return self;
}

- (void)show:(JustMonikaNotification *)notification
{
    if (!self.notificationsAllowed) {
        return;
    }
    if (@available(macOS 10.14, *)) {
        [self postUNNotification:notification];
    } else {
        [self postNSNotification:notification];
    }
}

#pragma mark - UserNotifications

// UserNotifications.framework is macOS 10.14+ thing which I'm fine with^W^W
// submitted to. It's not nice, but I do not have an older version of macOS
// available so I have no personal reason to support anything older than 10.14
// which I'm currently running. However, there should be no significant issues
// with porting all of this to the deprecated NSUserNotification interface.

- (void)requestNotificationPermission API_AVAILABLE(macosx(10.14))
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;

    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert
                          completionHandler:^(BOOL granted, NSError *error) {
        self.notificationsAllowed = granted;
    }];
}

static NSString *kUpdateAlertCategoryID = @"net.ilammy.JustMonika.UpdateAlert";

- (void)registerNotificationCategories
    API_AVAILABLE(macosx(10.14))
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;

    // UserNotifications have an issue: if the user clicks on the notification
    // (or any of its registered actions) then the system notifies the source
    // application about that. If the application is not running then it gets
    // relaunched and then notified. That is, when the screen saver finally
    // closes, the notification is displayed again, and if the user clicks
    // the notification, the screen saver activates again, locking the screen!
    //
    // There seems to be no way to prevent this. UserNotifications kinda unify
    // macOS behavior with iOS because Apple.
    //
    // Furthermore, in case of screen savers you cannot register a delegate to
    // handle notification actions, because the notifications about actions get
    // delivered before we get a chance to register a (global) delegate. What
    // an amazing new API, indeed! (Well, it's us who's weird by using it with
    // screen savers, honestly, but it's still frustrating.)
    //
    // Initially I did not want any actions, just display a banner. Another
    // idea was to have an action to open System Preferences, but we cannot
    // handle actions, as described above. Another idea was to turn this issue
    // into an easter egg by showing "Just Monika" actions which do nothing,
    // but still have a side effect of opening the screen saver back. It sounds
    // fun, but unfortunately make the notification an alert that does not go
    // away automatically. So we're back to banners now.
    //
    // Well, I still leave the category registration code in faint hope that
    // Apple some day provides a new framework^W API to disable app relaunch.
    // However, it does not do anything useful.
    UNNotificationCategory *updateAlert =
        [UNNotificationCategory categoryWithIdentifier:kUpdateAlertCategoryID
                                               actions:@[]
                                     intentIdentifiers:@[]
                                               options:UNNotificationCategoryOptionNone];

    self.updateAlertCategory = updateAlert.identifier;

    [center setNotificationCategories:[NSSet setWithObject:updateAlert]];
}

- (UNNotificationContent *)makeUNNnotificationContent:(JustMonikaNotification *)notification
    API_AVAILABLE(macosx(10.14))
{
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.categoryIdentifier = self.updateAlertCategory;
    content.title = notification.title;
    content.body = notification.body;
    return content;
}

- (void)postUNNotification:(JustMonikaNotification *)notification
    API_AVAILABLE(macosx(10.14))
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;

    NSString *identifier = notification.identifier;

    // If we have already shown a notification for this version then don't
    // nag the user about it every time when a screen saver is opened,
    // unless it's a critical update. Unfortunately, there isn't a way
    // other that waiting for the full list and iterating through it.
    [center getDeliveredNotificationsWithCompletionHandler:
     ^(NSArray<UNNotification *> *notifications) {
        if (!notification.isCritical) {
            for (UNNotification *notification in notifications) {
                if ([notification.request.identifier isEqualToString:identifier]) {
                    return;
                }
            }
        }
        // Now that we're sure we're not being annoying without a reason,
        // show a notification.
        UNNotificationContent *content = [self makeUNNnotificationContent:notification];
        UNNotificationRequest *notification =
            [UNNotificationRequest requestWithIdentifier:identifier
                                                 content:content
                                                 trigger:nil];

        [center addNotificationRequest:notification
                 withCompletionHandler:nil];
    }];
}

#pragma mark - NSUserNotification

// This is legacy API that was available until macOS 10.14 came with a new
// UserNotifications.framework. Unfortunately, it does not seem to work on
// macOS 10.14 so I'm not really able to test it. After some experimentation
// I have found out that Notification Center *remembers* which API you have
// used: NSUserNotification or UserNotification.framework, and forbids you
// to use the other API. Brilliant decision, Apple! /s

- (void)initUserNotificationDelegate
{
    NSUserNotificationCenter.defaultUserNotificationCenter.delegate = self;
}

- (NSUserNotification *)makeNSNotification:(JustMonikaNotification *)notification
    API_DEPRECATED("use UserNotifications.framework", macos(10.8, 10.14))
{
    // No jokes here because NSUserNotification API does not cause the
    // application to launch whenever the user accidentally click the
    // notification. It supports actions, but to handle them we need
    // to be running, which we aren't doing once screen saver stops.
    NSUserNotification *userNotification = [NSUserNotification new];
    userNotification.identifier = notification.identifier;
    userNotification.title = notification.title;
    userNotification.informativeText = notification.body;
    userNotification.hasActionButton = NO;
    return userNotification;
}

- (void)postNSNotification:(JustMonikaNotification *)notification
    API_DEPRECATED("use UserNotifications.framework", macos(10.8, 10.14))
{
    NSUserNotificationCenter *center = NSUserNotificationCenter.defaultUserNotificationCenter;

    NSString *identifier = notification.identifier;

    // If we have already shown a notification for this version then don't
    // nag the user about it every time when a screen saver is opened,
    // unless it's a critical update. Unfortunately, there isn't a way
    // other that waiting for the full list and iterating through it.
    if (!notification.isCritical) {
        for (NSUserNotification *notification in center.deliveredNotifications) {
            if ([notification.identifier isEqualToString:identifier]) {
                return;
            }
        }
    }
    // Now that we're sure we're not being annoying without a reason,
    // show a notification.
    [center deliverNotification:[self makeNSNotification:notification]];
}

#pragma mark - NSUserNotificationCenterDelegate

// By default notifications are not displayed if you application is in
// foreground, like if you are a screen saver. Override this behavior
// and always allow showing our notifications.
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end

@implementation JustMonikaNotification

- (NSString *)identifier
{
    return [NSString stringWithFormat:@"%@.%@",
            kUpdateAlertCategoryID, self.versionString];
}

@end
