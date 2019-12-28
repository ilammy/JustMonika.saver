// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaView.h"

#import "JustMonikaGLView.h"
#import "JustMonikaSettings.h"
#import "JustMonikaUpdater.h"
#import "NSView+Subviews.h"

@interface JustMonikaView ()

@property (strong) IBOutlet NSWindow *settingsSheet;
@property (weak) IBOutlet NSTextField *textOfDoom;

@property (weak) JustMonikaGLView *monika;
@property (strong) JustMonikaSettings *settings;

@property (nonatomic, weak) NSTextField *versionText;

@property (strong) JustMonikaUpdater *updater;

@end

@implementation JustMonikaView

#pragma mark - Initialization

static const float fps = 30.0;

// Called by Screen Saver framework
- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self initMonikaView];
        [self initSettings];
        [self initVersionText];
        [self initUpdater];
    }
    return self;
}

// Called when constructing UI made with Interface Builder
- (void)awakeFromNib
{
    [super awakeFromNib];

    // This method may be called recursively when loading NIB file
    // for the settings sheet below. Break recursion here.
    if (self.monika != nil) {
        return;
    }

    [self initMonikaView];
    [self initSettings];
    [self initVersionText];
    [self initUpdater];
}

// Called by Interface Builder for previews
- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];

    [self initMonikaView];
    [self initSettings];
    [self initVersionText];
    [self initUpdater];
}

- (void)initSettings
{
    self.settings = [JustMonikaSettings new];
    // Screen savers are loaded as plugins so their main bundle is not
    // this one, but the host bundle. We need to use the name directly.
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    [bundle loadNibNamed:@"sheet" owner:self topLevelObjects:nil];
    // Fill in the placeholder for the user name
    self.textOfDoom.stringValue =
        [self.textOfDoom.stringValue stringByReplacingOccurrencesOfString:@"[player]"
                                                               withString:NSUserName()];
}

- (void)initMonikaView
{
    NSRect frame = NSMakeRect(0, 0, NSWidth(self.frame), NSHeight(self.frame));
    JustMonikaGLView *monika = [[JustMonikaGLView alloc] initWithFrame:frame];
    monika.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:monika];
    [self setMonika:monika];
    [self setAnimationTimeInterval:1.0/fps];
}

#pragma mark - Automatic updates

- (void)initUpdater
{
    self.updater = [JustMonikaUpdater forView:self];
}

#pragma mark - Version display

static const CGFloat kVersionTextMargin = 3.0f;

- (void)initVersionText
{
    NSTextField *versionText = [[NSTextField alloc] initWithFrame:NSZeroRect];
    versionText.stringValue = self.versionString;
    // Transparent and non-interactive text label
    versionText.bezeled = NO;
    versionText.drawsBackground = NO;
    versionText.editable = NO;
    versionText.selectable = NO;
    // Use light color, we're on black background
    versionText.textColor = NSColor.lightGrayColor;
    versionText.backgroundColor = NSColor.clearColor;
    versionText.font = [NSFont labelFontOfSize:NSFont.smallSystemFontSize];
    // Keep the label in the bottom right corner
    versionText.autoresizingMask = NSViewMinXMargin | NSViewMaxYMargin;

    // Now actually put it there and save for later use
    [self addSubview:versionText];
    self.versionText = versionText;
    self.showVersionText = self.isPreview;
}

- (void)repositionVersionText
{
    [self.versionText sizeToFit];
    NSRect frame = self.versionText.frame;
    CGFloat x = NSWidth(self.frame) - NSWidth(frame) - kVersionTextMargin;
    CGFloat y = kVersionTextMargin;
    CGFloat w = NSWidth(frame);
    CGFloat h = NSHeight(frame);
    self.versionText.frame = NSMakeRect(x, y, w, h);
}

- (BOOL)showVersionText
{
    return !self.versionText.hidden;
}

- (void)setShowVersionText:(BOOL)showVersionText
{
    if (showVersionText) {
        [self repositionVersionText];
    }
    self.versionText.hidden = !showVersionText;
}

- (void)showCriticalUpdateBannerForVersion:(NSString *)newVersion
{
    self.versionText.textColor = NSColor.systemRedColor;
    self.versionText.stringValue =
        [NSString stringWithFormat:@"Critical update available: v%@ (current %@)",
         newVersion, self.versionString];
    self.showVersionText = YES;
}

- (NSString *)versionString
{
    NSBundle *thisBundle = [NSBundle bundleForClass:self.class];
    NSString *version = thisBundle.infoDictionary[@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"v%@", version];
}

#pragma mark - Animated drawing

- (void)startAnimation
{
    [super startAnimation];

    [self.monika startAnimation];
}

- (void)stopAnimation
{
    [self.monika stopAnimation];

    [super stopAnimation];
}

- (void)animateOneFrame
{
    [self.monika drawRect:self.monika.frame];
}

#pragma mark - Configuration sheet

- (BOOL)hasConfigureSheet
{
    return self.settings.settingsSheetEnabled;
}

- (NSWindow*)configureSheet
{
    return self.settingsSheet;
}

- (IBAction)disableConfigureSheet:(id)sender
{
    self.settings.settingsSheetEnabled = NO;
    [self disableScreenSaverOptionsButton];
    [NSApp endSheet:self.settingsSheet];
}

- (void)disableScreenSaverOptionsButton
{
    // Unfortunately, System Settings dialog caches "hasConfigureSheet" result
    // and shows the settings button as enabled until the user switches to some
    // other screen saver or reopens the window. Let's play a trick on the user
    // and actually disable the button right away.
    //
    // We can exploit the fact that Screen Savers are loaded as plugins into
    // System Settings, and thus we have access to full NSView hierarchy.
    NSView *contentView = self.settingsSheet.sheetParent.contentView;
    for (NSView *view in contentView.subviewsRecursive) {
        if (view.class == NSBox.class) {
            NSBox *box = (NSBox*)view;
            for (NSView *view in box.contentView.subviewsRecursive) {
                if (view.class == NSButton.class) {
                    NSButton *button = (NSButton*)view;
                    button.enabled = NO;
                    return;
                }
            }
        }
    }
}

@end
