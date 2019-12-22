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
#import "NSBundle+Name.h"

#import <objc/runtime.h>

@interface JustMonikaView ()

@property (nonatomic) JustMonikaSettings *settings;

@property (strong) IBOutlet NSWindow *settingsSheet;
@property (weak) IBOutlet NSTextField *ttt;

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

    [self initMonikaView];
}

// Called by Interface Builder for previews
- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];

    [self initMonikaView];
}

- (void)initSettings
{
    self.settings = [JustMonikaSettings new];
    [self.settings reset];
    // Screen savers are loaded as plugins so their main bundle is not
    // this one, but the host bundle. We need to use the name directly.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonika"];
    [bundle loadNibNamed:@"Monika" owner:self topLevelObjects:nil];
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
    [self trick]; // ehehey!

    return YES; // self.settings.settingsSheetEnabled;
}

- (NSWindow*)configureSheet
{
    return self.settingsSheet;
}

- (IBAction)disableConfigureSheet:(id)sender
{
//    self.settings.settingsSheetEnabled = NO;
//    [self disableScreenSaverOptionsButton];
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

#pragma mark - Thumbnail tricks

- (void)trick
{
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonika"];
    NSString *monika = bundle.localizedBundleName;

    NSWindow *topWindow = self.window;
    while (topWindow.parentWindow != nil) {
        topWindow = topWindow.parentWindow;
    }

    NSImage *monikaImage;
    NSMutableArray<NSView*> *thumbnails = [NSMutableArray new];
    for (NSView *view in topWindow.contentView.subviewsRecursive) {
        if ([view.className isEqualToString:@"IndividualSaverIconView"]) {
            NSString *title = [view performSelector:@selector(title)];
            if ([title isEqualToString:monika]) {
                monikaImage = [view performSelector:@selector(image)];
            } else {
                [thumbnails addObject:view];
            }
        }
    }

    int64_t delay = SSRandomIntBetween(1000, 1200);
    for (NSView *view in [thumbnails reverseObjectEnumerator]) {
        int64_t duration = SSRandomIntBetween(100, 250);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_MSEC),
                       dispatch_get_main_queue(), ^{
            NSString *title = [view performSelector:@selector(title)];
            NSImage *image = [view performSelector:@selector(image)];
            [view performSelector:@selector(setTitle:) withObject:monika];
            [view performSelector:@selector(setImage:) withObject:monikaImage];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_MSEC),
                           dispatch_get_main_queue(), ^{
                [view performSelector:@selector(setTitle:) withObject:title];
                [view performSelector:@selector(setImage:) withObject:image];
            });
        });
        delay += SSRandomIntBetween(-50, 50);
    }
}

-(void)initThumbnail
{
    return;

    // For some reason Apple decided that all third-party screen savers
    // should have a shitty looking thumbnail while all Apple-provided
    // screen savers display their high-DPI thumbnails nicely. This is
    // unforgivable. Let's renew some justic here.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonika"];

    NSString *saverTitle = bundle.localizedBundleName;
    NSImage *saverThumbnail = [bundle imageForResource:@"thumbnail"];

    NSWindow *topWindow = self.window;
    while (topWindow.parentWindow != nil) {
        topWindow = topWindow.parentWindow;
    }

    for (NSView *view in topWindow.contentView.subviewsRecursive) {
        // This is a private class so we don't have headers for it,
        // but its structure does not really change between systems.
        // Thank you, Objective-C, for your dynamic Smalltalk heritage.
        if ([view.className isEqualToString:@"IndividualSaverIconView"]) {
            NSString *title = [view performSelector:@selector(title)];
            if ([title isEqualToString:saverTitle]) {
                [view performSelector:@selector(setImage:)
                           withObject:saverThumbnail];
                return;
            }
        }
    }
#if 0
    NSString *msg = @"walking up:\n";
    NSWindow *window = self.window;
    do {
        window = window.parentWindow;
    } while (window.parentWindow != nil);
    NSView *view = window.contentView;
    msg = [msg stringByAppendingString:@"subobjects of content view:\n"];
    for (NSView *v in view.subviewsRecursive) {
        if ([v.className isEqualToString:@"IndividualSaverIconView"]) {
            NSString *title = [v performSelector:@selector(title)];
            if ([title isEqualToString:@"Monika"]) {
                NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonika"];
                NSImage *image = [bundle imageForResource:@"thumbnail"];
                [v performSelector:@selector(setImage:) withObject:image];
                break;
            }
            continue;
            unsigned int outCount, i;
            objc_property_t *properties = class_copyPropertyList(v.class, &outCount);
            msg = [msg stringByAppendingFormat:@"properties (%u):\n",
                   outCount];
            for(i = 0; i < outCount; i++) {
                objc_property_t property = properties[i];
                const char *propName = property_getName(property);
                msg = [msg stringByAppendingFormat:@"%s\n",
                       propName];
            }
            free(properties);
            id image = [v performSelector:@selector(image)];
            msg = [msg stringByAppendingFormat:@"image: %@\n", image];
            break;
        }
    }
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = msg;
    [alert runModal];
#endif
}

@end
