//
//  VisualView.h
//  Spectronics
//
//  Created by Ivan Wick on 12/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SettingsController.h"

#import "Spectronics.h"

// Width = frequency resolution (should be 256)
#define SG_TEXWIDTH  256
// Larger textures make glCopyTexSubImage2D slower. 256*128 seems close to
// the point where improvement becomes negligible.
#define SG_TEXHEIGHT 128
// Number of textures to allocate, must be such that SG_NTEXTURES*SG_TEXHEIGHT
// is as wide as the widest possible display. 4096 pixels seems reasonable...
#define SG_NTEXTURES 32
// Maximum number of lines per update (must be power of 2). 4 seems the maximum,
// above this the graph starts showing obvious bands.
#define SG_MAXCHUNK  4


@interface VisualView : NSOpenGLView  //<NSKeyValueObserving> // Cannot find protocol declaration?
{
    VisualPluginData * _visualPluginData;
    
    /* the first time a drawFrame is requested from the view, it has to make sure its OpenGL
     context is initialized.
     */
    BOOL m_glContextInitialized;
    
    // ivan- from SpectroGraph, moved from static vars to instance vars
    GLuint *pnTextureID; // Array with IDs
    UInt8 gnTexID;    // current texture index
    UInt32 gnPosition; // position inside texture
    UInt8 gnLPU;      // number of lines per update
    
    BOOL _scroll;
    BOOL _orientation;
    UInt32 gDelay;
    struct timeval gLineTimeStamp;
    struct timeval gFrameTimeStamp;
#ifdef SG_DEBUG
    struct timeval gFPSTimeStamp;
#endif
    
    UInt8 freshPixels[SG_TEXWIDTH*4*SG_MAXCHUNK];
    int nStored;
    UInt16 nTimePixels;
    int nNumTiles;
    BOOL _needsReshape;
}

@property (nonatomic, assign) VisualPluginData * visualPluginData;

// ivan- from SpectroGraph, moved from static vars to instance vars
@property (readwrite, assign) BOOL color;
@property (readwrite, assign) BOOL invertColors;
@property (readwrite, assign) BOOL scroll;
@property (readwrite, assign) BOOL linear;
@property (readwrite, assign) BOOL orientation; // YES:vert NO:horiz

@property (readwrite, retain) SettingsController* settingsController;

- (void)drawRect:(NSRect)dirtyRect;
- (BOOL)acceptsFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (void)keyDown:(NSEvent *)theEvent;
- (void)setupTextures;

- (void)saveRenderData:(RenderVisualData*)rvd;
- (void)DrawVisual;

- (void)initGL;
- (void)addObserversForSettings:(SettingsController*)sc;
- (void)removeObserversForSettings;

- (void)rewindDisplay;

@end
