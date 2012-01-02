//
//  SettingsController.h
//  Spectronics
//
//  Created by Ivan Wick on 12/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//  This class exists because we need a way to store settings independent of the lifecycle of
//  the VisualView object.

#import <Cocoa/Cocoa.h>
#import "Spectronics.h"

@interface SettingsController : NSWindowController <NSWindowDelegate>

@property (assign) BOOL invertColors;
@property (assign) BOOL color;
@property (assign) BOOL bandBias;
@property (assign) BOOL scroll;
@property (assign) BOOL linear;
@property (assign,nonatomic) BOOL orientation;
@property (assign) VisualPluginData* visualPluginData;
@property (readonly) NSArray* viewSettingsKeys;
@property (readonly) NSArray* processSettingsKeys;


- (NSDictionary*) preferencesDictionary;

@end
