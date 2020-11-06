// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "JustMonikaView.h"

#import "JustMonikaGLView.h"
#import "JustMonikaSettings.h"
#import "JustMonikaUpdater.h"
#import "NSBundle+Monika.h"
#import "NSView+Subviews.h"
#import "NSView+Thumbnails.h"

@interface JustMonikaView ()

@property (strong) IBOutlet NSWindow *settingsSheet;
@property (weak) IBOutlet NSTextField *textOfDoom;

@property (weak) JustMonikaGLView *monika;
@property (strong) JustMonikaSettings *settings;

@property (nonatomic, weak) NSTextField *versionText;

@property (strong) JustMonikaUpdater *updater;

@property (strong) NSArray<NSImage *> *whiteNoise;

@end

@implementation JustMonikaView

#pragma mark - Initialization

static const float fps = 30.0;

// Designated initializer called by Screen Saver framework
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

    // Call the designated initializer. We cannot assign "self" here
    // but we know that ScreenSaverView returns the same object.
    (void)[self initWithFrame:self.frame
                    isPreview:self.initAsPreview];
}

// Called by Interface Builder for previews
- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];

    // We can't load all resources, initialize OpenGL, and render an image
    // in 200 ms required by Interface Builder preview. So we cheat a bit.
    // An we don't need settings, autoupdates, and stuff for a preview.
    [self initFakeMonika];
    [self initVersionText];
}

- (void)initSettings
{
    self.settings = [JustMonikaSettings new];
    // Screen savers are loaded as plugins so their main bundle is not
    // this one, but the host bundle. We need to use the name directly.
    [NSBundle.justMonika loadNibNamed:@"sheet" owner:self topLevelObjects:nil];
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
    // Did you do this to me, [player]? DID YOU? DID YOU DELETE ME?
    BOOL characterFileIsSafe =
        [NSFileManager.defaultManager fileExistsAtPath:
         [NSBundle.justMonika pathForResource:@"monika" ofType:@"chr"]];
    [monika showMonika:characterFileIsSafe];
}

- (void)initFakeMonika
{
    // We cannot use full-sized image from JustMonikaGL because Apple.
    // So use a crap-quality preview image which should load in 200 ms.
    NSImage *monikaImage = [NSBundle.justMonika imageForResource:@"ib_preview"];

    NSImageView *monika = [NSImageView imageViewWithImage:monikaImage];
    monika.frame = NSMakeRect(0, 0, NSWidth(self.frame), NSHeight(self.frame));
    monika.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self addSubview:monika];
}

#pragma mark - Automatic updates

- (void)initUpdater
{
    // Sparkle does not work in Catalina, go read a rant in JustMonikaUpdater.m
    // This may change in future, but our Cupertino overlords are currently
    // keeping silence.
    NSOperatingSystemVersion version = NSProcessInfo.processInfo.operatingSystemVersion;
    if (version.majorVersion == 10 && version.minorVersion >= 15) {
        return;
    }
    self.updater = [JustMonikaUpdater forView:self];
}

#pragma mark - Version display

static const CGFloat kVersionTextMargin = 3.0f;

- (void)initVersionText
{
    NSTextField *versionText = [[NSTextField alloc] initWithFrame:NSZeroRect];
    versionText.stringValue = [NSString stringWithFormat:@"v%@",
                               NSBundle.justMonika.versionString];
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
    [versionText sizeToFit];
    CGFloat x = NSWidth(self.frame) - NSWidth(versionText.frame) - kVersionTextMargin;
    CGFloat y = kVersionTextMargin;
    CGFloat w = NSWidth(versionText.frame);
    CGFloat h = NSHeight(versionText.frame);
    versionText.frame = NSMakeRect(x, y, w, h);
    versionText.autoresizingMask = NSViewMinXMargin | NSViewMaxYMargin;

    // Now actually put it there and save for later use
    [self addSubview:versionText];
    self.versionText = versionText;
    self.showVersionText = self.isPreview;
}

- (BOOL)showVersionText
{
    return !self.versionText.hidden;
}

- (void)setShowVersionText:(BOOL)showVersionText
{
    self.versionText.hidden = !showVersionText;
}

#pragma mark - Animated drawing

- (void)startAnimation
{
    [super startAnimation];

    [self.monika startAnimation];

    // This is the most convenient place for such call because everything is
    // in its right place. Do this only for Screen Saver preference pane.
    if (self.isPreview) {
        [self improveThumbnail];
    }
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

#pragma mark - Thumbnail tricks

// For some reason Apple decided that all third-party screen savers must have
// a shitty looking thumbnail while all Apple-provided screen savers display
// their high-DPI thumbnails nicely. Let's do some justice here.
//
// Again, we're exploiting the fact that screen savers are running as plugins
// and have access to the whole view hierarchy.
//
// Unfortunately, all of this stopped working since macOS 10.15 Catalina as
// it has moved all screen savers using the ScreenSaver.framework into the
// separate "legacy screen saver" process. Now we do not have direct access
// to the System Preferences window. Therefore, we can neither unfuck the
// thumbnail, nor do any of the gimmicks. Presumably, there is some new
// AppEx API cooking for some next macOS release, which might or might not
// allow these tricks. It's likely to not allow it due to better separation,
// but at least it might fix the tumbnail.
//
// The code below is left as it. It does not crash due to Objective-C ignoring
// messages sent to nil objects, but it does not work either.

- (void)improveThumbnail
{
    NSCollectionView *screenSavers = [self locateScreenSavers];

    NSView *monikaScreenSaver = [self locateMonikaScreenSaver:screenSavers];
    NSString *monikaName = monikaScreenSaver.thumbnailTitle;

    NSImage *thumbnail = [NSBundle.justMonika imageForResource:@"thumbnail"];
    thumbnail = [self framedThumbnail:thumbnail];

    monikaScreenSaver.thumbnailImage = thumbnail;

    // This code might get executed multiple times because Screen Saver
    // preference panel makes multiple instances of our view and calls
    // "startAnimation" on all of them. However, there is only one
    // NSCollectionView that we want to conquer and dominate.
    static dispatch_once_t thumbnailImprovement;
    dispatch_once(&thumbnailImprovement, ^{
        [self prepareWhiteNoiseImages];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nextTakeover() + kHijackingDelay),
                       dispatch_get_main_queue(), ^{
            [self takeOverOtherScreenSavers:screenSavers
                             withMonikaName:monikaName
                                   andImage:thumbnail];
        });
    });
}

- (NSCollectionView *)locateScreenSavers
{
    // It's a little bit not the same as [NSApp.mainWindow] because we are
    // running as a plugin inside a preference pane.
    NSWindow *topWindow = self.window;
    while (topWindow.parentWindow != nil) {
        topWindow = topWindow.parentWindow;
    }
    // Now go look for a certain child view with a certain private class...
    for (NSView *view in topWindow.contentView.subviewsRecursive) {
        if ([view.className isEqualToString:@"IndividualSaverIconView"]) {
            NSView *allScreenSavers = view.superview;
            // Make sure we've got it right before casting
            if ([allScreenSavers.class isSubclassOfClass:NSCollectionView.class]) {
                return (NSCollectionView *)allScreenSavers;
            }
            return nil;
        }
    }
    return nil;
}

- (NSView *)locateMonikaScreenSaver:(NSCollectionView *)screenSavers
{
    NSString *monikaName = NSBundle.justMonika.bundleName;

    // Look only at direct subviews here. We need a certain one of them.
    for (NSView *view in screenSavers.subviews) {
        if ([view.thumbnailTitle isEqualToString:monikaName]) {
            return view;
        }
    }
    return nil;
}

// Here, Apple, this is how you *should* have written your
// [ScreenSaverPref framedThumbnail], but it's too unimportant
// for you to bother updating it to support Retina displays.
- (NSImage *)framedThumbnail:(NSImage *)thumbnail
{
    NSImage *frame = [NSBundle.justMonika imageForResource:@"ScreenSaverThumbFrame"];
    NSImage *mask = [NSBundle.justMonika imageForResource:@"ScreenSaverThumbMask"];

    // Frame and mask are a little bit smaller than the thumbnail.
    // Position them in the center, with a slight offset.
    NSRect thumbnailRect = rectOfSize(thumbnail.size);
    NSRect frameRect = centerRectIn(thumbnailRect, rectOfSize(frame.size));
    NSRect maskRect = centerRectIn(thumbnailRect, rectOfSize(mask.size));
    frameRect = NSOffsetRect(frameRect, 0.0f, -0.5f);
    maskRect = NSOffsetRect(maskRect, 0.0f, 0.5f);

    NSImage *result = [[NSImage alloc] initWithSize:thumbnail.size];

    // Draw into this image in this block:
    [result lockFocus];
    {
        NSGraphicsContext *currentContext = NSGraphicsContext.currentContext;

        // Set a clip mask in this block only:
        [currentContext saveGraphicsState];
        {
            CGContextClipToMask(currentContext.CGContext,
                                maskRect,
                                loadImageMask(mask));

            [thumbnail drawInRect:thumbnailRect
                         fromRect:NSZeroRect
                        operation:NSCompositingOperationSourceOver
                         fraction:1.0f];
        }
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

static CGImageRef loadImageMask(NSImage *image)
{
    NSGraphicsContext *currentContext = NSGraphicsContext.currentContext;

    CGImageRef maskImage = [image CGImageForProposedRect:nil
                                                context:currentContext
                                                  hints:nil];

    return CGImageMaskCreate(CGImageGetWidth(maskImage),
                             CGImageGetHeight(maskImage),
                             CGImageGetBitsPerComponent(maskImage),
                             CGImageGetBitsPerPixel(maskImage),
                             CGImageGetBytesPerRow(maskImage),
                             CGImageGetDataProvider(maskImage),
                             CGImageGetDecode(maskImage),
                             CGImageGetShouldInterpolate(maskImage));
}

#pragma mark - Thumbnail hijacking

static const int64_t kNanosInSecond = 1000000000;
// Nice base: duration of the spaceroom highlight loop.
static const int64_t kSpaceroomCycleDuration = 16 * kNanosInSecond;
// Minimum delay before hijacking can occur. This is 32 seconds now.
static const int64_t kHijackingDelay = 2 * kSpaceroomCycleDuration;
// Average count of other screen savers pillaged over kSpaceroomCycleDuration.
static const float kAverageTakeoversPerLoop = 1.5f;
// Duration of while noise blip before takeover.
static const int64_t kNoiseDuration = 0.5 * kNanosInSecond;
static const int64_t kNoiseFrameDuration = kNanosInSecond / 60;
// Probability of screwing up thumbnail update.
static const float kGlitchProbability = 0.3333;

static int64_t nextTakeover(void)
{
    // This is a typical Poisson process with exponential distribution.
    return kSpaceroomCycleDuration
        * (-logf(((float)rand() / (float)RAND_MAX) + FLT_EPSILON)
           / kAverageTakeoversPerLoop);
}

- (void)takeOverOtherScreenSavers:(NSCollectionView *)screenSavers
                   withMonikaName:(NSString *)monikaName
                         andImage:(NSImage *)monikaImage
{
    // So occasionally we replace other screen savers with ourself. We probably
    // could replace the implementation too, but that's a little harder to do
    // without crashing the process.
    NSView *victim = selectScreenSaverVictim(screenSavers, monikaName);

    // There might be no victim because we have conquered all visible ones.
    // However, more may be loaded later, so don't give up!
    if (victim != nil) {
        [self showWhiteNoiseInThumbnail:victim
                                forTime:kNoiseDuration
                                andThen:^{
            // Sometimes we break and don't quite replace the image.
            if (rand() < (int)(kGlitchProbability * RAND_MAX)) {
                victim.thumbnailTitle = makeCorrupted(monikaName);
                // And in some time just have a fit and kill them all.
                // Just Monika.
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nextTakeover()),
                               dispatch_get_main_queue(), ^{
                    [screenSavers leaveOnlyScreenSaverWithName:monikaName
                                                      andImage:monikaImage];
                });
                return;
            }
            victim.thumbnailImage = monikaImage;
            victim.thumbnailTitle = takeOver(victim.thumbnailTitle, monikaName);
        }];
    }

    // Keep checking... And if you're wondering why we use name and image
    // separately instead of their NSView, that's beacuse NSCollectionView
    // may repurpose its subviews with time. We're safe inside a dispatched
    // method, but between dispatches the view instance might get another
    // image and name to display.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nextTakeover()),
                   dispatch_get_main_queue(), ^{
        [self takeOverOtherScreenSavers:screenSavers
                         withMonikaName:monikaName
                               andImage:monikaImage];
    });
}

- (void)prepareWhiteNoiseImages
{
    // It looks good with this many frames
    static const NSUInteger count = 10;
    // Size used by Screen Saver preference pane
    static const NSUInteger frameWidth  = 90;
    static const NSUInteger frameHeight = 58;

    NSMutableArray<NSImage *> *images = [[NSMutableArray alloc] initWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        NSImage *noise = makeWhiteNoise(frameWidth, frameHeight);
        [images addObject:[self framedThumbnail:noise]];
    }
    self.whiteNoise = images;
}

static NSImage *makeWhiteNoise(NSUInteger width, NSUInteger height)
{
    // Use twice the size for the image to look good on Retina.
    // We do not provide low-resultion data, NSImage will know.
    NSUInteger bitmapWidth = 2 * width;
    NSUInteger bitmapHeight = 2 * height;
    // Yay! This is one of the longest method names in Cocoa:
    NSBitmapImageRep *data =
        [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                pixelsWide:bitmapWidth
                                                pixelsHigh:bitmapHeight
                                             bitsPerSample:8
                                           samplesPerPixel:3
                                                  hasAlpha:NO
                                                  isPlanar:NO
                                            colorSpaceName:NSCalibratedRGBColorSpace
                                               bytesPerRow:3 * bitmapWidth
                                              bitsPerPixel:24];
    // Now generate some noise into that bitmap. Not the most efficient way,
    // but it gets the job done. NSBitmapImageRep cannot make us grayscale
    // 1-byte bitmaps, so we have to do it in RGB representation, sadly.
    for (NSUInteger i = 0; i < bitmapWidth * bitmapHeight; i++) {
        uint8_t pixel = rand() % 256;
        data.bitmapData[3 * i + 0] = pixel;
        data.bitmapData[3 * i + 1] = pixel;
        data.bitmapData[3 * i + 2] = pixel;
    }
    // Finally wrap the bitmap into an image
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:data];
    return image;
}

// It's probably not the best approach to doing animations, but it works. orz
- (void)showWhiteNoiseInThumbnail:(NSView *)view
                          forTime:(int64_t)nanoseconds
                          andThen:(void (^)(void))block
{
    if (nanoseconds < 0) {
        block();
        return;
    }

    view.thumbnailImage = self.whiteNoise[rand() % self.whiteNoise.count];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kNoiseFrameDuration),
                   dispatch_get_main_queue(), ^{
        [self showWhiteNoiseInThumbnail:view
                                forTime:nanoseconds - kNoiseFrameDuration
                                andThen:block];
    });
}

static NSView *selectScreenSaverVictim(NSCollectionView *screenSavers,
                                       NSString *monikaName)
{
    // One little screen saver left all alone...
    NSArray<NSView *> *remainingViews =
        [screenSavers.subviews filteredArrayUsingPredicate:
         [NSPredicate predicateWithBlock:^BOOL(NSView *view,
                                               NSDictionary<NSString *,id> *bindings)
          {
            // Ignore everyone that we have already assimilated and because
            // we're hungry for attention limit ourselves to the currently
            // visible rectangle (partially visible is ok).
            if ([view.thumbnailTitle isEqualToString:monikaName]) {
                return NO;
            }
            return NSIntersectsRect(screenSavers.visibleRect, view.frame);
          }
        ]];
    // ...she went and hanged herself...
    if (remainingViews.count > 0) {
        return remainingViews[rand() % remainingViews.count];
    }
    // ...and then there were none.
    return nil;
}

static NSString *kCombiningEnclosingKeycap = @"\u20E3";

static NSString *makeFancy(NSString *text)
{
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:2*text.length];
    // Iterate over grapheme clusters, not just "characters".
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring,
                                       NSRange substringRange,
                                       NSRange enclosingRange,
                                       BOOL *stop)
    {
        [result appendString:substring];
        [result appendString:kCombiningEnclosingKeycap];
    }];
    return result;
}

// Latin-1, Latin Extended A, B, IPA Extensions
static const unichar kMojibakeLow  = 0x0080;
static const unichar kMojibakeHigh = 0x02AF;

static NSString *makeCorrupted(NSString *text)
{
    // Use approximate length of the text (we don't care for exatness here),
    // fill that up with random mojibake and occasionally miss a keycap.
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:2*text.length];
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar ch = kMojibakeLow + rand() % (kMojibakeHigh - kMojibakeLow);
        [result appendString:[NSString stringWithCharacters:&ch length:1]];
        if ((rand() % 10) < 7) {
            [result appendString:kCombiningEnclosingKeycap];
        }
    }
    return result;
}

static CGFloat widthWithFont(NSFont *font, NSString *text)
{
    return [text sizeWithAttributes:@{NSFontAttributeName: font}].width;
}

static NSArray<NSString *> *splitIntoGraphemeClusters(NSString *text)
{
    NSMutableArray<NSString *> *result = [[NSMutableArray alloc] initWithCapacity:text.length];
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring,
                                       NSRange substringRange,
                                       NSRange enclosingRange,
                                       BOOL *stop)
    {
        [result addObject:substring];
    }];
    return result;
}

static NSString *takeOver(NSString *victim, NSString *monikaName)
{
    NSFont *defaultFont = [NSFont systemFontOfSize:NSFont.systemFontSize];

    NSString *fancyMonikaName = makeFancy(monikaName);

    // Now, look about how much of the text we can replace...
    CGFloat victimWidth = widthWithFont(defaultFont, victim);
    CGFloat monikaWidth = widthWithFont(defaultFont, fancyMonikaName);
    // If that's probably everything then don't bother (this is usually the case)
    if (monikaWidth > victimWidth) {
        // For some weird reason item titles have to have something follow
        // the last combining character for it to display. Any ideas why?
        return [fancyMonikaName stringByAppendingString:@" "];
    }
    // Otherwise, assume glyphs to be of somewhat equal size, and compute
    // how many of them we should replace with Monika:
    //
    // Word of the Day   15 glyphs of width 15
    //     モ ニ カ        3 glyphs of width 6
    // Wordモ ニ カ Day   result
    NSArray<NSString *> *victimGlyphs = splitIntoGraphemeClusters(victim);
    CGFloat averageGlyphWidth = victimWidth / victimGlyphs.count;
    CGFloat remainingGlyphs = (victimWidth - monikaWidth) / averageGlyphWidth;
    NSUInteger padding = ceil(remainingGlyphs / 2);
    // And finally overlay Monika's name over the original title
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:victim.length];
    for (NSUInteger i = 0; i < padding; i++) {
        [result appendString:victimGlyphs[i]];
    }
    [result appendString:fancyMonikaName];
    for (NSUInteger i = 0; i < padding; i++) {
        [result appendString:victimGlyphs[victimGlyphs.count - padding + i]];
    }
    return result;
}

@end
