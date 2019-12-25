//
//  JustMonikaView.m
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-17.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import "JustMonikaView.h"

#import "JustMonikaGLView.h"
#import "JustMonikaSettings.h"
#import "NSView+Subviews.h"

@interface JustMonikaView ()

@property (strong) IBOutlet NSWindow *settingsSheet;
@property (weak) IBOutlet NSTextField *textOfDoom;

@property (weak) JustMonikaGLView *monika;
@property (strong) JustMonikaSettings *settings;

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
}

// Called by Interface Builder for previews
- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];

    [self initMonikaView];
    [self initSettings];
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
