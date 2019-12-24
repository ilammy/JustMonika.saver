//
//  JustMonikaSettings.h
//  JustMonika
//
//  Created by Alexei Lozovsky on 2019-11-23.
//  Copyright © 2019 ilammy's tearoom. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JustMonikaView.h"

@interface JustMonikaSettings : NSObject

@property (assign) BOOL settingsSheetEnabled;

- (void)reset;

@end

// Expose this property to the preview app
@interface JustMonikaView (Settings)
@property (readonly,strong) JustMonikaSettings *settings;
@end
