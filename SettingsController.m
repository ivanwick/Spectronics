//
//  SettingsController.m
//  Spactrograph
//
//  Created by Ivan Wick on 12/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SettingsController.h"

@implementation SettingsController

@synthesize invertColors;
@synthesize color;
@synthesize scroll;
@synthesize visualPluginData;

- (void)setBandBias:(BOOL)bandBias { self.visualPluginData->biasNormFlag = bandBias; }
- (BOOL)bandBias { return self.visualPluginData->biasNormFlag; }


- (NSDictionary*) preferencesDictionary
{
    NSArray *keys;
    keys = [NSArray arrayWithObjects:
            @"invertColors",
            @"color",
            @"scroll",
            @"bandBias",
            nil];
    
    return [self dictionaryWithValuesForKeys:keys];
}

#if 0 // so far nothing needs to be inited here.
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
#endif

#if 0 // not modal.
- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
}
#endif

@end
