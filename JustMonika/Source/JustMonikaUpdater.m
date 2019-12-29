// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaUpdater.h"

#import <UserNotifications/UserNotifications.h>

#import "JustMonikaView.h"

@interface JustMonikaUpdater ()

@property (strong) SUUpdater *updater;
@property (weak) JustMonikaView *view;

@property (nonatomic) BOOL notificationsAllowed;
@property (strong) NSString *updateAlertCategory;

@end

@implementation JustMonikaUpdater

- (instancetype)initWithUpdater:(SUUpdater *)updater andView:(JustMonikaView *)view
{
    self = [super init];
    if (self) {
        self.updater = updater;
        self.updater.delegate = self;
        self.view = view;

        [self requestNotificationPermission];
        [self registerNotificationCategories];
        [self listenToSparkleRestarts];
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

#pragma mark - User Notifications

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

- (void)notifyAboutUpdate:(SUAppcastItem *)item
{
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;

    NSString *identifier = [self notificationIDForUpdate:item];

    // If we have already shown a notification for this version then don't
    // nag the user about it every time when a screen saver is opened,
    // unless it's a critical update. Unfortunately, there isn't a way
    // other that waiting for the full list and iterating through it.
    [center getDeliveredNotificationsWithCompletionHandler:
     ^(NSArray<UNNotification *> *notifications) {
        if (!item.isCriticalUpdate) {
            for (UNNotification *notification in notifications) {
                if ([notification.request.identifier isEqualToString:identifier]) {
                    return;
                }
            }
        }
        // Now that we're sure we're not being annoying without a reason,
        // show a notification.
        //
        // The notification will be sent on behalf of the ScreenSaverEngine
        // and will display its application icon. This cannot be changed and
        // is intentional feature of macOS so that the source application
        // cannot be spoofed for the user.
        UNNotificationContent *content = [self notificationContentForUpdate:item];
        UNNotificationRequest *notification =
            [UNNotificationRequest requestWithIdentifier:identifier
                                                 content:content
                                                 trigger:nil];

        [center addNotificationRequest:notification
                 withCompletionHandler:nil];
    }];
}

- (NSString *)notificationIDForUpdate:(SUAppcastItem *)item
{
    return [NSString stringWithFormat:@"%@.%@",
            kUpdateAlertCategoryID, item.versionString];
}

- (UNNotificationContent *)notificationContentForUpdate:(SUAppcastItem *)item
{
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.categoryIdentifier = self.updateAlertCategory;
    // The space is gold here. We have around 40 characters for the title
    // and then two more lines of text for the body. Keep it short.
    if (item.isCriticalUpdate) {
        content.title =
            [NSString stringWithFormat:@"Critical Update Available: Monika %@",
             item.displayVersionString];
        content.body = @"An important update to this screen saver is available. "
            @"Please open \"System Preferences\" to install it.";
    } else {
        content.title =
            [NSString stringWithFormat:@"Update Available: Monika %@",
             item.displayVersionString];
        content.body = @"A new version of this screen saver is available. "
            @"Please open \"System Preferences\" to install it.";
    }
    return content;
}

#pragma mark - Restart handling

// Learned about this caveat in Aerial:
// https://github.com/JohnCoates/Aerial
//
// Before Sparkle tries to restart our screen saver we have to quit System
// Preferences dialog. Otherwise Sparkle tries to terminate the Screen Saver
// preference pane process which crashes it and fails the update.
//
// Note that this does not work in Catalina (macOS 10.15+) because Apple is
// a dick and sandboxed all screen savers even more tightly:
// https://github.com/JohnCoates/Aerial/issues/801
// https://github.com/sparkle-project/Sparkle/issues/1476
// Well, it's not a issue for me because I'm running 10.14 and 10.15 requires
// all screen savers to be signed by Developer ID and notarized by Apple.
// Which I do not have. Please accept my condolences if you're using 10.15.

- (void)listenToSparkleRestarts
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(sparkleWillRestart)
                                               name:SUUpdaterWillRestartNotification
                                             object:nil];
}

- (void)sparkleWillRestart
{
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications) {
        if ([app.bundleIdentifier isEqualToString:@"com.apple.systempreferences"]) {
            [app terminate];
        }
    }
}

#pragma mark - SUUpdaterDelegate

// Sparkle always relaunches after installing an update, unless it's an
// automatic background update. We allow automatic updates only when we're
// in screen saver mode. Opening System Preferences triggers manual update
// which we have to relaunch for the preference pane to see the new version.
// We need to return YES here to proceed with updates. Sparkes's automatic
// update driver ensures that it will not relaunch the screen saver.
- (BOOL)updaterShouldRelaunchApplication:(SUUpdater *)updater
{
    return YES;
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

// Now, if we have found a valid update while we are running in screen saver
// mode, Sparkle does not show any alerts. However, we would like to notify
// the user about the update when the screen saver finishes.
- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)item
{
    // If we're running as preview then the user should see an alert instead.
    if (self.view.isPreview) {
        return;
    }

    // Don't bother sending a notification if they were denied by the user.
    if (self.notificationsAllowed) {
        [self notifyAboutUpdate:item];
    }
}

@end
