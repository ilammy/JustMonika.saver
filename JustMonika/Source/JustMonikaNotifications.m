// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaNotifications.h"

#import <UserNotifications/UserNotifications.h>

@interface JustMonikaNotification ()

@property (nonatomic,readonly) NSString *identifier;

@end

@interface JustMonikaNotifications ()

@property (nonatomic,assign) BOOL notificationsAllowed;
@property (nonatomic,strong) NSString *updateAlertCategory;

@end

@implementation JustMonikaNotifications

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self requestNotificationPermission];
        [self registerNotificationCategories];
    }
    return self;
}

- (void)show:(JustMonikaNotification *)notification
{
    [self postUNNotification:notification];
}

#pragma mark - UserNotifications

// UserNotifications.framework is macOS 10.14+ thing which I'm fine with^W^W
// submitted to. It's not nice, but I do not have an older version of macOS
// available so I have no personal reason to support anything older than 10.14
// which I'm currently running. However, there should be no significant issues
// with porting all of this to the deprecated NSUserNotification interface.

- (void)requestNotificationPermission
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
{
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.categoryIdentifier = self.updateAlertCategory;
    content.title = notification.title;
    content.body = notification.body;
    return content;
}

- (void)postUNNotification:(JustMonikaNotification *)notification
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

@end

@implementation JustMonikaNotification

- (NSString *)identifier
{
    return [NSString stringWithFormat:@"%@.%@",
            kUpdateAlertCategoryID, self.versionString];
}

@end
