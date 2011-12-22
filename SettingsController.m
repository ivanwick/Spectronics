//
//  SettingsController.m
//  Spactrograph
//
//  Created by Ivan Wick on 12/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SettingsController.h"

@implementation SettingsController

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
    
    NSLog(@"yeap");
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
}
@end
