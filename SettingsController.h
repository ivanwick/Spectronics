//
//  SettingsController.h
//  Spactrograph
//
//  Created by Ivan Wick on 12/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SettingsController : NSWindowController <NSWindowDelegate>
{
    NSMutableDictionary *preferences;
    
    BOOL _invertColors;
    BOOL _color;
    BOOL _bandBias;
    BOOL _scroll;
}

@property (retain) NSMutableDictionary* preferences;

@property (assign) BOOL invertColors;
@property (assign) BOOL color;
@property (assign) BOOL bandBias;
@property (assign) BOOL scroll;

@end
