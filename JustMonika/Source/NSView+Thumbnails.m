// SPDX-License-Identifier: GPL-3.0-only
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import "NSView+Thumbnails.h"

#import <objc/runtime.h>

@implementation NSView (Thumbnails)

// Take care to check whether the view responds to the selectors we need.
// If it doesn't then the runtime may and usually will throw an exception.

- (NSString *)thumbnailTitle
{
    if ([self respondsToSelector:@selector(title)]) {
        return [self performSelector:@selector(title)];
    }
    return nil;
}

- (void)setThumbnailTitle:(NSString *)title
{
    if ([self respondsToSelector:@selector(setTitle:)]) {
        [self performSelector:@selector(setTitle:)
                   withObject:title];
    }
}

- (NSImage *)thumbnailImage
{
    if ([self respondsToSelector:@selector(image)]) {
        return [self performSelector:@selector(image)];
    }
    return nil;
}

- (void)setThumbnailImage:(NSImage *)image
{
    if ([self respondsToSelector:@selector(setImage:)]) {
        [self performSelector:@selector(setImage:)
                   withObject:image];
    }
}

@end

@implementation NSCollectionView (ScreenSavers)

// This information has been reverse-engineed by staring at disassembly
// of the Screen Saver preference pane. Tread carefully, when in doubt
// return nil.

- (void)leaveOnlyScreenSaverWithName:(NSString *)name
                            andImage:(NSImage *)image
{
    NSMutableArray *dataSource = self.actualCollectionDataSource;
    if (!dataSource) {
        return;
    }

    NSUInteger index = 0;
    if (![self findScreenSaverWithName:name
                               inArray:dataSource
                               atIndex:&index])
    {
        return;
    }

    // We have to set the thumbnail again because when we reload the data
    // the view will use the old image. We would like it to use the new one.
    [self setScreenSaverThumbnail:image
                         forIndex:index
                          inArray:dataSource];

    // Kill them all!
    [self removeScreenSaversOtherThan:index
                              inArray:dataSource];

    // Now quickly reload collection data or the panel will crash.
    [self reloadData];
}

- (NSMutableArray *)actualCollectionDataSource
{
    // There should be a dataSource here, but if there isn't then bail out.
    id dataSource = self.dataSource;
    if (!dataSource) {
        return nil;
    }

    // The data source object should have a "_collectionDataSource" ivar.
    // No, this isn't a property, no selectors here. Instance variables.
    Class ScreenSaverPref = object_getClass(dataSource);
    Ivar ScreenSaverPref_collectionDataSource =
        class_getInstanceVariable(ScreenSaverPref, "_collectionDataSource");
    if (!ScreenSaverPref_collectionDataSource) {
        return nil;
    }

    // And this ivar should contain an NSMutableArray in it.
    id actual = object_getIvar(dataSource, ScreenSaverPref_collectionDataSource);
    if (![[actual class] isSubclassOfClass:NSMutableArray.class]) {
        return nil;
    }
    return actual;
}

- (BOOL)findScreenSaverWithName:(NSString *)name
                        inArray:(NSArray *)dataSource
                        atIndex:(nonnull NSUInteger *)outIndex
{
    NSUInteger index = 0;
    for (id item in dataSource) {
        if ([self thisThing:item hasName:name]) {
            *outIndex = index;
            return YES;
        }
        index++;
    }
    return NO;
}

static NSString *kName = @"name";
static NSString *kImage = @"image";

- (BOOL)thisThing:(id)thing hasName:(NSString *)name
{
    // Data source array should contain NSDictionaries...
    if (![[thing class] isSubclassOfClass:NSDictionary.class]) {
        return NO;
    }
    // ...and the dictionary should contain a certain key...
    id itemName = thing[kName];
    if (![[itemName class] isSubclassOfClass:NSString.class]) {
        return NO;
    }
    // ...which must have a certain value.
    return [(NSString *)itemName isEqualToString:name];
}

- (void)setScreenSaverThumbnail:(NSImage *)image
                       forIndex:(NSUInteger)index
                        inArray:(NSMutableArray *)array
{
    // Make sure we have an image to replace first...
    id oldImage = array[index][kImage];
    if (![[oldImage class] isSubclassOfClass:NSImage.class]) {
        return;
    }
    // Dictionaries stored there are not mutable. Make a mutable copy.
    NSMutableDictionary *copy =
        [[NSMutableDictionary alloc] initWithDictionary:array[index]];
    copy[kImage] = image;
    array[index] = copy;
}

- (void)removeScreenSaversOtherThan:(NSUInteger)index
                            inArray:(NSMutableArray *)array
{
    NSRange allIndexes = NSMakeRange(0, array.count);
    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc]
                                  initWithIndexesInRange:allIndexes];
    [indexes removeIndex:index];
    [array removeObjectsAtIndexes:indexes];
}

@end
