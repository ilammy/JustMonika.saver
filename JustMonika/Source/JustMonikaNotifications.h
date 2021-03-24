// SPDX-License-Identifier: GPL-3.0-only
// JustMonika.saver
// Copyright (c) 2019 ilammy's tearoom

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JustMonikaNotification : NSObject

@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *body;
@property (nonatomic,strong) NSString *versionString;
@property (nonatomic,assign) BOOL isCritical;

@end

@interface JustMonikaNotifications : NSObject

- (void)show:(JustMonikaNotification *)notification;

@end

NS_ASSUME_NONNULL_END
