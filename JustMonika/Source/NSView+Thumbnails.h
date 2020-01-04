// SPDX-License-Identifier: GPL-3.0-or-later
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

// Accessors to private class "IndividualSaverIconView"

@interface NSView (Thumbnails)

@property (strong,nullable) NSString *thumbnailTitle;
@property (strong,nullable) NSImage *thumbnailImage;

@end

// Accessors to private class "ScreenSaverPref"

@interface NSCollectionView (ScreenSavers)

- (void)leaveOnlyScreenSaverWithName:(NSString *)name andImage:(NSImage *)image;

@end

NS_ASSUME_NONNULL_END
