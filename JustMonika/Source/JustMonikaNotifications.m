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
static NSString *kUpdateAlertActionOKID = @"net.ilammy.JustMonika.UpdateAlert.OK";

- (void)registerNotificationCategories
    API_AVAILABLE(macosx(10.14))
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;

    // Initially I wanted to display the notification as a simple alert with
    // no action buttons. However, clicking the notification (or any actions)
    // when the application is not running results in the application
    // being relaunched. That is, when the screen saver finally closes and
    // the user click the notification, the screen saver activates again,
    // locking the screen back! Moreover, in order to react to the action
    // we have to install a delegate early at startup, that's not when our
    // code executes at all. Therefore we cannot, say, put a button to open
    // the System Preferences dialog. Even if we could, the screen saver will
    // still launch. So... let it launch! And hope the user gets the joke.
    UNNotificationAction *justMonika =
        [UNNotificationAction actionWithIdentifier:kUpdateAlertActionOKID
                                             title:@"Just Monika"
                                           options:UNNotificationActionOptionNone];

    UNNotificationCategory *updateAlert =
        [UNNotificationCategory categoryWithIdentifier:kUpdateAlertCategoryID
                                               // macOS displays up to 10 actions
                                               actions:@[justMonika, justMonika,
                                                         justMonika, justMonika,
                                                         justMonika, justMonika,
                                                         justMonika, justMonika,
                                                         justMonika, justMonika]
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
