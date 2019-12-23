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
    [self initThumbnail];

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

#pragma mark - Thumbnail fixups

- (void)viewDidMoveToSuperview
{
    [self initThumbnail];
}

// Here, Apple, this is how you *should* have written your
// [ScreenSaverPref framedThumbnail], but it's too unimportant
// for you to bother updating it to support Retina displays.
+ (NSImage *)framedThumbnail:(NSImage *)thumbnail
{
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonika"];

    NSImage *frame = [bundle imageForResource:@"ScreenSaverThumbFrame"];
    NSImage *mask = [bundle imageForResource:@"ScreenSaverThumbMask"];

    // Frame and mask are a little bit smaller than the thumbnail.
    // Position them in the center.
    NSRect thumbnailRect = rectOfSize(thumbnail.size);
    NSRect frameRect = centerRectIn(thumbnailRect, rectOfSize(frame.size));
    NSRect maskRect = centerRectIn(thumbnailRect, rectOfSize(mask.size));

    NSImage *result = [[NSImage alloc] initWithSize:thumbnail.size];

    [result lockFocus];
    {
        NSGraphicsContext *currentContext = NSGraphicsContext.currentContext;

        [currentContext saveGraphicsState];

        CGImageRef maskImage = [mask CGImageForProposedRect:nil
                                                    context:currentContext
                                                      hints:nil];
        CGImageRef maskMask =
            CGImageMaskCreate(CGImageGetWidth(maskImage),
                              CGImageGetHeight(maskImage),
                              CGImageGetBitsPerComponent(maskImage),
                              CGImageGetBitsPerPixel(maskImage),
                              CGImageGetBytesPerRow(maskImage),
                              CGImageGetDataProvider(maskImage),
                              CGImageGetDecode(maskImage),
                              CGImageGetShouldInterpolate(maskImage));

        CGContextClipToMask(currentContext.CGContext,
                            maskRect,
                            maskMask);

        [thumbnail drawInRect:thumbnailRect
                     fromRect:NSZeroRect
                    operation:NSCompositingOperationSourceOver
                     fraction:1.0f];

        [currentContext restoreGraphicsState];

        [frame drawInRect:frameRect
                 fromRect:NSZeroRect
                operation:NSCompositingOperationSourceOver
                 fraction:1.0f];

    }
    [result unlockFocus];

    return result;
}

static NSRect rectOfSize(NSSize size)
{
    return NSMakeRect(0.0f, 0.0f, size.width, size.height);
}

static NSRect centerRectIn(NSRect dst, NSRect src)
{
    CGFloat dX = (NSWidth(dst) - NSWidth(src))/2.0f;
    CGFloat dY = (NSHeight(dst) - NSHeight(src))/2.0f;
    return NSOffsetRect(src, dX, dY);
}

- (void)initThumbnail
{
    // For some reason Apple decided that all third-party screen savers
    // should have a shitty looking thumbnail while all Apple-provided
    // screen savers display their high-DPI thumbnails nicely. This is
    // unforgivable. Let's renew some justic here.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.ilammy.JustMonika"];

    NSString *saverTitle = bundle.localizedBundleName;
    NSImage *saverThumbnail = [bundle imageForResource:@"thumbnail"];
    saverThumbnail = [JustMonikaView framedThumbnail:saverThumbnail];

    NSWindow *topWindow = self.window;
    while (topWindow.parentWindow != nil) {
        topWindow = topWindow.parentWindow;
    }

    // Actually, if we cannot switch the image in time, let's just kill
    // all other screensavers. Just Monika. But do it gently, so that
    // the user does not realize that the screensavers are gone before
    // they want to change them.

    NSMutableArray<NSView *> *otherScreenSavers = [NSMutableArray new];
    NSCollectionView *screenSaverCollectionView;

    for (NSView *view in topWindow.contentView.subviewsRecursive) {
        // This is a private class so we don't have headers for it,
        // but its structure does not really change between systems.
        // Thank you, Objective-C, for your dynamic Smalltalk heritage.
        if ([view.className isEqualToString:@"IndividualSaverIconView"]) {
            NSString *title = [view performSelector:@selector(title)];
            if ([title isEqualToString:saverTitle]) {
                screenSaverCollectionView = (NSCollectionView *)view.superview;
                [view performSelector:@selector(setImage:)
                           withObject:saverThumbnail];
            } else {
                [otherScreenSavers addObject:view];
            }
        }
    }

/*

    id<NSCollectionViewDataSource> data = screenSaverCollectionView.dataSource;
//    NSInteger num = [data collectionView:screenSaverCollectionView numberOfItemsInSection:0];

    NSString *message = @"";

    unsigned int outCount, i;
    Method *methods = class_copyMethodList(data.class, &outCount);
    for (i = 0; i < outCount; i++) {
        char buffer[256] = {0};
        NSString *method = @"";
        const char *name = sel_getName(method_getName(methods[i]));
        method = [method stringByAppendingFormat:@"%s", name];
        unsigned int argCount = method_getNumberOfArguments(methods[i]);
        for (unsigned j = 0; j < argCount; j++) {
            method_getArgumentType(methods[i], j, buffer, sizeof(buffer));
            method = [method stringByAppendingFormat:@"$%s", buffer];
        }
        message = [message stringByAppendingFormat:@"%@\n", method];
    }
    free(methods);

    */

//    NSAlert *alert = [[NSAlert alloc] init];
//    alert.messageText = message;
//    [alert runModal];

    // It seems that Cocoa architecture does not make it easy to remove
    // items from collection. Well, we have removeFromSuperview on other
    // modules, but that will not remove them immediately and they will
    // still be there as a volume.

    // I don't know... maybe glitch out the images and zalgo the text?
    // That we can do without crashing.

//    for (NSView *view in otherScreenSavers) {
//        NSImage *image = [view performSelector:@selector(image)];
//        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:image.TIFFRepresentation];
//        NSData* jpegData = [bitmap representationUsingType:NSBitmapImageFileTypeJPEG
//                                                properties:@{NSImageCompressionFactor: @0.1}];
//        NSMutableData *jpegDataMut = [[NSMutableData alloc] initWithData:jpegData];
////        // TODO: corrupt JPEG data somehow
//        uint8_t *bytes = jpegDataMut.mutableBytes;
//        for (NSUInteger i = 400; i < jpegDataMut.length; i += 13) {
//            bytes[i] = ~bytes[i];
//        }
//        NSImage *newImage = [[NSImage alloc] initWithData:jpegDataMut];
//        [view performSelector:@selector(setImage:) withObject:newImage];
//    }

    // Sht. It does not really work the way GlithPEG works. If I randomly
    // flip bytes then NSImage just fails to decode and gives up.
    // It seems we need to be more smart about that.

/*

 deleteConfirmationSheetDidEnd:returnCode:contextInfo:$@$:$@$q$^v
 createAndAttachPreviewChildWindowsIfNeeded$@$:
 _selectTableViewItemForModuleName:$@$:$@
 collectionView:menuForRightClickOnItem:$@$:$@$@
 configureSheetDidEnd:returnCode:contextInfo:$@$:$@$q$^v
 scrollToSelectedCollectionViewItem$@$:
 reAddChildWindowsAfterAnimationCompletes$@$:
 _deleteModuleFromOV:$@$:$@
 moduleConfigure:$@$:$@
 activationTimePopUpItemClicked:$@$:$@
 doScreenSaverHelpLookup:$@$:$@
 hotCornerConfigure:$@$:$@
 hotCornerPanelCompleted:$@$:$@
 openEnergySaverPrefs:$@$:$@
 randomSaverOptionChanged:$@$:$@
 showClockOptionChanged:$@$:$@
 _deleteModuleFromRemoveButton:$@$:$@
 beginSaverPreview$@$:
 notifySelectModule:$@$:$@
 setStyleIsHidden:$@$:$c
 _delayedModuleSelect:$@$:$@
 fetchDisplaySleep$@$:
 _prefCrashedPreviously$@$:
 updateContentsOfCollectionViews$@$:
 DESTROYPreviewChildWindows$@$:
 delayedLoadPreviewArea$@$:
 willResignActive:$@$:$@
 setSelectedModule:$@$:$@
 createCollectionViews$@$:
 _setPreviewContentView:$@$:$@
 updateDisplayDimmingAlert$@$:
 reloadModulesAndSelect:$@$:$@
 _setActivationTimeUIFromPrefs$@$:
 screenSaverDidEnd:$@$:$@
 _selectTableViewItemForModule:$@$:$@
 screenSaverDidStart:$@$:$@
 willBecomeActive:$@$:$@
 changeActivationTimeToSeconds:$@$:$q
 _deleteModule:withConfirmation:$@$:$@$c
 _selectCollectionItemForModule:$@$:$@
 finishModuleInstall:$@$:$@
 _finishModuleDelete$@$:
 _deleteModuleReallySeriously:$@$:$@
 framedThumbnail:$@$:$@
 deleteModuleMenuClick:$@$:$@
 collectionViewItemWasSelected:$@$:$@
 collectionView:hadKeyDownEvent:$@$:$@$@
 setupUI$@$:
 willHide:$@$:$@
 _stopPreview$@$:
 _selectedModule$@$:
 _installModule:$@$:$@
 moduleTest:$@$:$@
 _revealModule:$@$:$@
 styleIsHidden$@$:
 dealloc$@$:
 windowDidMiniaturize:$@$:$@
 windowDidDeminiaturize:$@$:$@
 collectionView:numberOfItemsInSection:$@$:$@$q
 collectionView:itemForRepresentedObjectAtIndexPath:$@$:$@$@
 numberOfSectionsInCollectionView:$@$:$@
 mainViewDidLoad$@$:
 openDocumentAtPath:$@$:$@
 engineFinished:$@$:$@
 _startPreview$@$:
 didBecomeActive:$@$:$@
 didSelect$@$:
 willUnselect$@$:


 createAndAttachPreviewChildWindowsIfNeeded
 configureSheetDidEnd:returnCode:contextInfo:
 _selectTableViewItemForModuleName:
 collectionView:menuForRightClickOnItem:
 scrollToSelectedCollectionViewItem
 reAddChildWindowsAfterAnimationCompletes
 beginSaverPreview
 notifySelectModule:
 _prefCrashedPreviously
 _delayedModuleSelect:
 fetchDisplaySleep
 setStyleIsHidden:
 updateContentsOfCollectionViews
 DESTROYPreviewChildWindows
 delayedLoadPreviewArea
 willResignActive:
 setSelectedModule:
 createCollectionViews
 _setPreviewContentView:
 updateDisplayDimmingAlert
 reloadModulesAndSelect:
 _setActivationTimeUIFromPrefs
 screenSaverDidEnd:
 _selectTableViewItemForModule:
 screenSaverDidStart:
 willBecomeActive:
 changeActivationTimeToSeconds:
 _deleteModule:withConfirmation:
 _selectCollectionItemForModule:
 finishModuleInstall:
 _finishModuleDelete
 _deleteModuleReallySeriously:
 framedThumbnail:
 deleteModuleMenuClick:
 collectionViewItemWasSelected:
 collectionView:hadKeyDownEvent:
 hotCornerConfigure:
 _deleteModuleFromRemoveButton:
 showClockOptionChanged:
 randomSaverOptionChanged:
 openEnergySaverPrefs:
 hotCornerPanelCompleted:
 doScreenSaverHelpLookup:
 activationTimePopUpItemClicked:
 moduleConfigure:
 _deleteModuleFromOV:
 _selectedModule
 setupUI
 willHide:
 _stopPreview
 _installModule:
 moduleTest:
 _revealModule:
 styleIsHidden
 deleteConfirmationSheetDidEnd:returnCode:contextInfo:
 dealloc
 windowDidMiniaturize:
 windowDidDeminiaturize:
 collectionView:numberOfItemsInSection:
 collectionView:itemForRepresentedObjectAtIndexPath:
 numberOfSectionsInCollectionView:
 mainViewDidLoad
 openDocumentAtPath:
 engineFinished:
 _startPreview
 didBecomeActive:
 didSelect
 willUnselect

 */

//    for (NSView *view in otherScreenSavers) {
//        [view removeFromSuperview];
//    }

//    [screenSaverCollectionView layout];

//    [screenSaverCollectionView reloadData];

//    NSSet<NSIndexPath *> *items = screenSaverCollectionView.selectionIndexPaths;
//    [screenSaverCollectionView performBatchUpdates:^(void) {
//        [screenSaverCollectionView deleteItemsAtIndexPaths:items];
//    }
//                                 completionHandler:nil];

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
