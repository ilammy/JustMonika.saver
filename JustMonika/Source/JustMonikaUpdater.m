// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaUpdater.h"

#import <Sparkle/Sparkle.h>

#import "JustMonikaNotifications.h"
#import "JustMonikaView.h"
#import "NSBundle+Monika.h"

@interface JustMonikaUpdater () <SUUpdaterDelegate>

@property (strong) JustMonikaNotifications *notifications;
@property (strong) SUUpdater *updater;
@property (weak) JustMonikaView *view;

@property (strong) NSURLSession *session;

@end

@interface JustMonikaVersionInfo : NSObject

@property (strong) NSString *versionString;
@property (strong) NSString *displayName;
@property (strong) NSString *description;
@property (strong) NSString *releaseURL;

@end

@implementation JustMonikaUpdater

- (instancetype)initWithUpdater:(SUUpdater *)updater andView:(JustMonikaView *)view
{
    self = [super init];
    if (self) {
        self.notifications = [JustMonikaNotifications new];
        self.updater = updater;
        self.updater.delegate = self;
        self.view = view;

        [self listenToSparkleRestarts];
        [self initReleaseRequestParameters];
    }
    return self;
}

+ (instancetype)forView:(JustMonikaView *)view
{
    SUUpdater *updater = [SUUpdater updaterForBundle:NSBundle.justMonika];
    updater.sendsSystemProfile = NO; // don't you ever dare
    return [[JustMonikaUpdater alloc] initWithUpdater:updater
                                              andView:view];
}

#pragma mark - Querying release info

// See the following documentation for reference:
// https://docs.github.com/v3/repos/releases/#get-the-latest-release

static NSString *githubURL =
    @"https://api.github.com/repos/ilammy/JustMonika.saver/releases/latest";

- (void)initReleaseRequestParameters
{
    // The defaults are fine for doing public API queries. We only need to set
    // the MIME type for response to prefer the v3 API.
    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{
        @"Accept": @"application/vnd.github.v3+json",
    };
    self.session = [NSURLSession sessionWithConfiguration:config];
}

- (void)checkForUpdates
{
    // TODO: check for updates
    // 1. Check if we are allowed to check for updates at all.
    // 2. Check if the previous check was long ago enough.
    // 3. Query the latest release.
}

- (void)queryLatestRelease
{
    NSURLSessionDataTask *task =
        [self.session dataTaskWithURL:[NSURL URLWithString:githubURL]
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
            // The release description is a JSON object with the following
            // interesting fields:
            //
            // {
            //   "url": "https://api.github.com/repos/octocat/Hello-World/releases/1",
            //   "html_url": "https://github.com/octocat/Hello-World/releases/v1.0.0",
            //   "tag_name": "v1.0.0",
            //   "name": "v1.0.0",
            //   "body": "Description of the release",
            //   ...
            // }
            if (error) {
                NSLog(@"Failed to get latest version: %@", error);
                return;
            }
            NSDictionary *release =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&error];
            if (error) {
                NSLog(@"Failed to parse version info: %@", error);
                return;
            }
            JustMonikaVersionInfo *version = [JustMonikaVersionInfo new];
            version.releaseURL    = release[@"html_url"];
            version.versionString = release[@"tag_name"];
            version.displayName   = release[@"name"];
            version.description   = release[@"body"];
            [self handleLatestRelease:version];
        }];
    // The task will be performed asynchronously and then dropped by the session.
    [task resume];
}

- (void)handleLatestRelease:(JustMonikaVersionInfo *)version
{
    // TODO: notify about updates
    // 1. Check that this is an update.
    // 2. Decide whether we issue a notification or show an alert.
    // 3. If the alert has decided to ignore the update, ignore it.
}

#pragma mark - User Notifications

- (void)notifyAboutUpdate:(SUAppcastItem *)item
{
    // The space is gold here. We have around 40 characters for the title
    // and then two more lines of text for the body. Keep it short.
    JustMonikaNotification *notification = [JustMonikaNotification new];
    notification.isCritical = item.isCriticalUpdate;
    notification.versionString = item.versionString;
    if (item.isCriticalUpdate) {
        notification.title =
            [NSString stringWithFormat:
             JMLocalizedString(@"Critical Update Available: Monika %@",
                               @"Notification title for critical updates. "
                               @"%@ is replaced with version (e.g., 2.0)"),
             item.displayVersionString];
        notification.body =
            JMLocalizedString(@"An important update to this screen saver is available. "
                              @"Please open \"System Preferences\" to install it.",
                              @"Notification body for critical updates.");
    } else {
        notification.title =
            [NSString stringWithFormat:
             JMLocalizedString(@"Update Available: Monika %@",
                               @"Notification title for regular updates. "
                               @"%@ is replaced with version (e.g., 2.0)"),
             item.displayVersionString];
        notification.body =
            JMLocalizedString(@"A new version of this screen saver is available. "
                              @"Please open \"System Preferences\" to install it.",
                              @"Notification body for regular updates.");
    }

    [self.notifications show:notification];
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

    [self notifyAboutUpdate:item];
}

@end
