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

@property (nonatomic) JustMonikaSettings *settings;

@property (weak) IBOutlet NSWindow *settingsSheet;

@property (weak) JustMonikaGLView *monika;

@end

@implementation JustMonikaView

// Called when constructing UI made with Interface Builder.
- (void)awakeFromNib
{
    [super awakeFromNib];

    // This method can get called recursively due to NIB loading in setup.
    // NIB fills in settingsSheet, so if it's there then we can just exit.
    if (self.settingsSheet) {
        return;
    }

    // TODO: can we avoid this sorcery?
    (void)[super initWithFrame:self.frame isPreview:NO];
    [self setup];
}

// Called by Interface Builder for previews.
- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];

    // TODO: can we avoid this sorcery?
    (void)[super initWithFrame:self.frame isPreview:NO];
    [self setup];
}

static const float fps = 30;

// Called by Screen Saver framework
- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1.0/fps];
        [self setup];
    }
    return self;
}

- (void)setup
{
    // Screen savers are loaded as plugins so their main bundle is not
    // this one, but the host bundle. We need to use the name directly.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonika"];

    [bundle loadNibNamed:@"Monika" owner:self topLevelObjects:nil];

    self.settings = [JustMonikaSettings new];

    JustMonikaGLView *monika = [[JustMonikaGLView alloc] initWithFrame:self.frame];
    [self addSubview:monika];
    monika.frame = NSMakeRect(0, 0, NSWidth(self.frame), NSHeight(self.frame));
    monika.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.monika = monika;
}

- (void)startAnimation
{
    [super startAnimation];

    [self.monika startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];

    [self.monika stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    self.needsDisplay = YES;
}

- (BOOL)hasConfigureSheet
{
    return self.settings.settingsSheetEnabled;
}

- (NSWindow*)configureSheet
{
    if (!self.settings.settingsSheetEnabled) {
        return nil;
    }
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
