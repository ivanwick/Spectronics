//
// File:       iTunesPlugInMac.mm
//
// Abstract:   Visual plug-in for iTunes on MacOS
//
// Version:    2.0
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ( "Apple" )
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright © 2001-2011 Apple Inc. All Rights Reserved.
//

//-------------------------------------------------------------------------------------------------
//	includes
//-------------------------------------------------------------------------------------------------

#import "Spactrograph.h"

#import <AppKit/AppKit.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <string.h>

//-------------------------------------------------------------------------------------------------
//	constants, etc.
//-------------------------------------------------------------------------------------------------

#define kTVisualPluginName              CFSTR("iTunes Sample Visualizer")

//-------------------------------------------------------------------------------------------------
//	exported function prototypes
//-------------------------------------------------------------------------------------------------

extern "C" OSStatus iTunesPluginMainMachO( OSType inMessage, PluginMessageInfo *inMessageInfoPtr, void *refCon ) __attribute__((visibility("default")));


#if USE_SUBVIEW
//-------------------------------------------------------------------------------------------------
//	VisualView
//-------------------------------------------------------------------------------------------------

@interface VisualView : NSView
{
	VisualPluginData *	_visualPluginData;
}

@property (nonatomic, assign) VisualPluginData * visualPluginData;

-(void)drawRect:(NSRect)dirtyRect;
- (BOOL)acceptsFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
-(void)keyDown:(NSEvent *)theEvent;

@end

#endif	// USE_SUBVIEW

//-------------------------------------------------------------------------------------------------
//	DrawVisual
//-------------------------------------------------------------------------------------------------
//
void DrawVisual( VisualPluginData * visualPluginData )
{
	CGRect			drawRect;
	CGPoint			where;

	// this shouldn't happen but let's be safe
	if ( visualPluginData->destView == NULL )
		return;

	drawRect = [visualPluginData->destView bounds];

	// fill the whole view with black to start
	[[NSColor blackColor] set];
	NSRectFill( drawRect );

	// pick a random location to draw our little square
	double			randomX = (random() / 2147483647.0);		// [0, 1]
	double			randomY = (random() / 2147483647.0);		// [0, 1]

	where.x = (CGFloat)(randomX * drawRect.size.width);
	where.y = (CGFloat)(randomY * drawRect.size.height);

	if ( visualPluginData->playing )
	{
		// if playing, draw a square whose color is dictated by the current max levels
		CGFloat		red		= (CGFloat)visualPluginData->maxLevel[1] / 256.0;
		CGFloat		green	= (CGFloat)visualPluginData->maxLevel[1] / 256.0;
		CGFloat		blue	= (CGFloat)visualPluginData->maxLevel[0] / 256.0;

		[[NSColor colorWithDeviceRed:red green:green blue:blue alpha:1] set];
	}
	else
	{
		// if idle, draw a partially transparent blue square
		[[[NSColor blueColor] colorWithAlphaComponent:0.75] set];
	}

	drawRect = NSMakeRect( where.x, where.y, 100, 100 );

	NSRectFill( drawRect );

	// should we draw the info/artwork in the bottom-left corner?
	time_t		theTime = time( NULL );

	if ( theTime < visualPluginData->drawInfoTimeOut )
	{
		where = CGPointMake( 10, 10 );

		// if we have a song title, draw it (prefer the stream title over the regular name if we have it)
		NSString *				theString = NULL;

		if ( visualPluginData->streamInfo.streamTitle[0] != 0 )
			theString = [NSString stringWithCharacters:&visualPluginData->streamInfo.streamTitle[1] length:visualPluginData->streamInfo.streamTitle[0]];
		else if ( visualPluginData->trackInfo.name[0] != 0 )
			theString = [NSString stringWithCharacters:&visualPluginData->trackInfo.name[1] length:visualPluginData->trackInfo.name[0]];
		
		if ( theString != NULL )
		{
			NSDictionary *		attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, NULL];
			
			[theString drawAtPoint:where withAttributes:attrs];
		}

		// draw the artwork
		if ( visualPluginData->currentArtwork != NULL )
		{
			where.y += 20;

			[visualPluginData->currentArtwork drawAtPoint:where fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.75];
		}
	}
}

#if 0 // SpectroGraph
//############################################
//	RenderVisualPort, aka drawing happens here from SpectroGraph
//############################################
static void RenderVisualPort(VisualPluginData *visualPluginData, GRAPHICS_DEVICE destPort,const Rect *destRect,Boolean onlyUpdate)
{
	(void) visualPluginData;
	(void) onlyUpdate;
	int i;
	UInt8 *spectrumDataL = visualPluginData->renderData.spectrumData[0],
    *spectrumDataR = visualPluginData->renderData.spectrumData[1];
	UInt16 nTimePixels;
	
	if (destPort == nil)
		return;
    
	glClearColor( 0.0, 0.0, 0.0, 0.0 );
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Update the texture and only draw if chunk is full, otherwise exit
	for( i=0; i<SG_TEXWIDTH; i++ )
		UInt8ToARGB( spectrumDataL[i], spectrumDataR[i], &freshPixels[(nStored*SG_TEXWIDTH+i)*4] );
	nStored++;
	if( nStored < gnLPU )
		return;
	nStored = 0;
	
	/* glTexSubImage2D is a huge bottleneck!
	 * Updating larger chunks is slightly more efficient overall, but the incurred delay
	 * quickly becomes so large that it causes an unacceptable gap in the data.
	 * TODO: tune TEXHEIGHT for optimal speed
	 * TODO 2: check if using glCopyTexSubImage2D is more efficient, we
	 *         want to squeeze the absolute max performance out of this!!! */
	glBindTexture( GL_TEXTURE_2D, pnTextureID[gnTexID] );
	glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, SG_TEXWIDTH);
	glTexSubImage2D( GL_TEXTURE_2D, 0, 0, gnPosition, SG_TEXWIDTH,
                    gnLPU, GL_BGRA, ARGB_IMAGE_TYPE, freshPixels );	
	gnPosition = gnPosition+gnLPU;
    
	if(gDirection == 0)
		nTimePixels = visualPluginData->destRect.right - visualPluginData->destRect.left;
	else
		nTimePixels = visualPluginData->destRect.bottom - visualPluginData->destRect.top;
	int nNumTiles = (int)ceil((float)nTimePixels/SG_TEXHEIGHT);
	if(gScrollFlag)
		nNumTiles++;
    
	if( !gScrollFlag && gnTexID*SG_TEXHEIGHT+gnPosition >= nTimePixels ) {
		gnTexID = 0;
		gnPosition = 0;
	}
	else if( gnPosition >= SG_TEXHEIGHT ) {
		gnPosition = 0;
		gnTexID++;
		if( gScrollFlag && gnTexID >= nNumTiles )
			gnTexID = 0;
	}
    
	float fTexWid = SG_TEXHEIGHT*2.0/nTimePixels;
	if(!gScrollFlag) {
		for( i=0; i<nNumTiles; i++ ) {
			glBindTexture( GL_TEXTURE_2D, pnTextureID[i] );
			glBegin(GL_QUADS);
			if(gDirection == 0) { // Horizontal
				float fLeft = -1.0f+i*fTexWid,
                fRight = -1.0f+(i+1)*fTexWid;
				glTexCoord2f(0.0f, 0.0f);
				glVertex3f( fLeft, -1.0f, 0.0f);
				glTexCoord2f(1.0f, 0.0f);
				glVertex3f( fLeft, 1.0f, 0.0f);
				glTexCoord2f(1.0f, 1.0f);
				glVertex3f( fRight, 1.0f, 0.0f);
				glTexCoord2f(0.0f, 1.0f);
				glVertex3f( fRight, -1.0f, 0.0f);
			}
			else {
				float fTop = 1.0f-i*fTexWid,
                fBtm = 1.0f-(i+1)*fTexWid;
				glTexCoord2f(0.0f, 0.0f);
				glVertex3f( -1.0f, fTop, 0.0f);
				glTexCoord2f(1.0f, 0.0f);
				glVertex3f(  1.0f, fTop, 0.0f);
				glTexCoord2f(1.0f, 1.0f);
				glVertex3f(  1.0f, fBtm, 0.0f);
				glTexCoord2f(0.0f, 1.0f);
				glVertex3f( -1.0f, fBtm, 0.0f);		
			}
			glEnd();
		}
	}
	else {
		float fOffset = gnPosition*2.0/nTimePixels;
		for( i=0; i<nNumTiles; i++ ) {
			UInt8 nTexID = (gnTexID-i+nNumTiles)%nNumTiles;
			glBindTexture( GL_TEXTURE_2D, pnTextureID[nTexID] );
			glBegin(GL_QUADS);
			if(gDirection == 0) { // Horizontal
				float fLeft  = 1.0f-i*fTexWid-fOffset,
                fRight = 1.0f+(1-i)*fTexWid-fOffset;
				glTexCoord2f(0.0f, 0.0f);
				glVertex3f( fLeft, -1.0f, 0.0f);
				glTexCoord2f(1.0f, 0.0f);
				glVertex3f( fLeft, 1.0f, 0.0f);
				glTexCoord2f(1.0f, 1.0f);
				glVertex3f( fRight, 1.0f, 0.0f);
				glTexCoord2f(0.0f, 1.0f);
				glVertex3f( fRight, -1.0f, 0.0f);
			}
			else { // Vertical
				float fTop = -1.0f+i*fTexWid+fOffset,
                fBtm = -1.0f+(i-1)*fTexWid+fOffset;
				glTexCoord2f(0.0f, 0.0f);
				glVertex3f( -1.0f, fTop, 0.0f);
				glTexCoord2f(1.0f, 0.0f);
				glVertex3f(  1.0f, fTop, 0.0f);
				glTexCoord2f(1.0f, 1.0f);
				glVertex3f(  1.0f, fBtm, 0.0f);
				glTexCoord2f(0.0f, 1.0f);
				glVertex3f( -1.0f, fBtm, 0.0f);		
			}
			glEnd();
		}
	}
	glBindTexture( GL_TEXTURE_2D, 0 ); // unbind texture
    
	glFinish();
	glFlush();
	
#if TARGET_OS_MAC
	aglSwapBuffers(myContext);
#else
	{
		HDC hdc = GetDC(destPort);
		SwapBuffers(hdc);
	}
#endif
	
	UInt32 nUSec = getuSec(gFrameTimeStamp);
	// We try to maintain a framerate of about 60FPS. If it drops below that,
	// we update fewer lines at once to produce a smoother display.
	if( gnLPU > 1 && nUSec > 16000 )
		gnLPU /= 2;
	// If the framerate is more than 90FPS, we update more lines at once,
	// which allows to achieve an even higher lines-per-second rate.
	// But, we must keep the update blocks aligned.
	else if( gnLPU < SG_MAXCHUNK && nUSec < 11000 && (gnPosition % (gnLPU*2) == 0) )
		gnLPU *= 2;
	startuSec(&gFrameTimeStamp);
	
#ifdef SG_DEBUG
	if( getuSec(gFPSTimeStamp) < 1000000 )
		nFps++;
	else {
		fprintf(stderr, "SpectroGraph fps: %u, LPU: %u, delay: %lu; NT: %d\n", nFps, gnLPU, nUSec, nNumTiles );
		startuSec(&gFPSTimeStamp);
		nFps = 0;
	}
#endif
}

#endif // SpectroGraph


//-------------------------------------------------------------------------------------------------
//	UpdateArtwork
//-------------------------------------------------------------------------------------------------
//
void UpdateArtwork( VisualPluginData * visualPluginData, CFDataRef coverArt, UInt32 coverArtSize, UInt32 coverArtFormat )
{
	// release current image
	[visualPluginData->currentArtwork release];
	visualPluginData->currentArtwork = NULL;
	
	// create 100x100 NSImage* out of incoming CFDataRef if non-null (null indicates there is no artwork for the current track)
	if ( coverArt != NULL )
	{
		visualPluginData->currentArtwork = [[NSImage alloc] initWithData:(NSData *)coverArt];
		
		[visualPluginData->currentArtwork setSize:CGSizeMake( 100, 100 )];
	}
	
	UpdateInfoTimeOut( visualPluginData );
}

//-------------------------------------------------------------------------------------------------
//	InvalidateVisual
//-------------------------------------------------------------------------------------------------
//
void InvalidateVisual( VisualPluginData * visualPluginData )
{
	(void) visualPluginData;

#if USE_SUBVIEW
	// when using a custom subview, we invalidate it so we get our own draw calls
	[visualPluginData->subview setNeedsDisplay:YES];
#endif
}

//-------------------------------------------------------------------------------------------------
//	CreateVisualContext
//-------------------------------------------------------------------------------------------------
//
OSStatus ActivateVisual( VisualPluginData * visualPluginData, VISUAL_PLATFORM_VIEW destView, OptionBits options )
{
	OSStatus			status = noErr;

	visualPluginData->destView			= destView;
	visualPluginData->destRect			= [destView bounds];
	visualPluginData->destOptions		= options;

	UpdateInfoTimeOut( visualPluginData );

#if USE_SUBVIEW

	// NSView-based subview
	visualPluginData->subview = [[VisualView alloc] initWithFrame:visualPluginData->destRect];
	if ( visualPluginData->subview != NULL )
	{
		[visualPluginData->subview setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

		[visualPluginData->subview setVisualPluginData:visualPluginData];

		[destView addSubview:visualPluginData->subview];
	}
	else
	{
		status = memFullErr;
	}

#endif

	return status;
}

//-------------------------------------------------------------------------------------------------
//	MoveVisual
//-------------------------------------------------------------------------------------------------
//
OSStatus MoveVisual( VisualPluginData * visualPluginData, OptionBits newOptions )
{
	visualPluginData->destRect	  = [visualPluginData->destView bounds];
	visualPluginData->destOptions = newOptions;

	return noErr;
}

//-------------------------------------------------------------------------------------------------
//	DeactivateVisual
//-------------------------------------------------------------------------------------------------
//
OSStatus DeactivateVisual( VisualPluginData * visualPluginData )
{
#if USE_SUBVIEW
	[visualPluginData->subview removeFromSuperview];
	[visualPluginData->subview autorelease];
	visualPluginData->subview = NULL;
	[visualPluginData->currentArtwork release];
	visualPluginData->currentArtwork = NULL;
#endif

	visualPluginData->destView			= NULL;
	visualPluginData->destRect			= CGRectNull;
	visualPluginData->drawInfoTimeOut	= 0;
	
	return noErr;
}

//-------------------------------------------------------------------------------------------------
//	ResizeVisual
//-------------------------------------------------------------------------------------------------
//
OSStatus ResizeVisual( VisualPluginData * visualPluginData )
{
	visualPluginData->destRect = [visualPluginData->destView bounds];

	// note: the subview is automatically resized by iTunes so nothing to do here

	return noErr;
}

#if 0 // SpectroGraph
// ChangeVisualPort from SpectroGraph
//
static OSStatus ChangeVisualPort(VisualPluginData *visualPluginData, GRAPHICS_DEVICE destPort, const Rect *destRect)
{
	OSStatus		status;
    
	status = noErr;
    
	visualPluginData->destPort = destPort;
	if(destRect != nil) {
		GLint bufferRect[4];
		GLsizei viewportWidth, viewportHeight;
		Rect portRect;
		visualPluginData->destRect = *destRect;
		
#ifdef SG_DEBUG
		if( destPort == NULL )
			fprintf(stderr, "ChangeVisualPort: destPort==NULL even though destRect!=NULL, have a nice crash!\n" );
#endif
		
		// TODO: add tests on results (GLboolean)
		aglSetDrawable(myContext, destPort);
		aglSetCurrentContext(myContext);
		// By setting AGL_SWAP_INTERVAL to 1, the swapping of buffers is synchronized with monitor retraces.
		GLint swapinterval = 0;
		aglSetInteger(myContext, AGL_SWAP_INTERVAL, &swapinterval);	
		
		// Set the bufferRect, which seems to be AGL jargon for the viewport.
		// The bufferRect must be specified as left, bottom, width, height.
		// TODO: this is way more complex in windoze, check VisualGraphicsCore::getCanvasSurroundingRect
		GetPortBounds(destPort, &portRect); // = canvasSurroundingRect (canvasRect = destRect)
		bufferRect[0] = (GLint)destRect->left;
		bufferRect[1] = (GLint)(portRect.bottom - portRect.top - destRect->bottom);
		bufferRect[2] = (GLint)(destRect->right - destRect->left);
		bufferRect[3] = (GLint)(destRect->bottom - destRect->top);
		//fprintf(stderr, "ChangeVisualPort: portBounds=%d,%d,%d,%d\n", portRect.left, portRect.top, portRect.right, portRect.bottom ); // DEBUG
		//fprintf(stderr, "ChangeVisualPort: bufferRect=%ld,%ld,%ld,%ld\n", bufferRect[0], bufferRect[1], bufferRect[2], bufferRect[3] ); // DEBUG
		aglEnable(myContext, AGL_BUFFER_RECT);
		aglSetInteger(myContext, AGL_BUFFER_RECT, bufferRect);
		
		// Notify the rendering context that the window geometry has changed
		aglUpdateContext(myContext);
		
		// FIXME: some crap needs to be added for windoze if fullscreen. Check VisualGraphicsCore::setViewport
		viewportWidth = destRect->right - destRect->left;
		viewportHeight = destRect->bottom - destRect->top;
		glViewport(0, 0, viewportWidth, viewportHeight);
		
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		
		glOrtho(-1.0, 1.0, -1.0, 1.0, 0.0, 10.0);
		
		glMatrixMode(GL_MODELVIEW);
		
		// TODO (cosmetic): if viewport is enlarged, erase new texture parts
	}
	
	return status;
}
#endif


//-------------------------------------------------------------------------------------------------
//	ConfigureVisual
//-------------------------------------------------------------------------------------------------
//
OSStatus ConfigureVisual( VisualPluginData * visualPluginData )
{
	(void) visualPluginData;

	// load nib
	// show modal dialog
	// update settings
	// invalidate

	return noErr;
}

#if 0 // SpectroGraph
#if TARGET_OS_MAC
/* 
 settingsControlHandler
 */
pascal OSStatus settingsControlHandler(EventHandlerCallRef inRef,EventRef inEvent, void* userData)
{
	WindowRef wind=NULL;
	ControlID controlID;
	ControlRef control=NULL;
	//get control hit by event
	GetEventParameter(inEvent,kEventParamDirectObject,typeControlRef,NULL,sizeof(ControlRef),NULL,&control);
	wind=GetControlOwner(control);
	GetControlID(control,&controlID);
	switch(controlID.id) {
		case kColorSettingID:
			gColorFlag = GetControlValue(control);
			break;
		case kInvertSettingID:
			gInvertFlag = GetControlValue(control);
			break;
		case kBandSettingID:
			gBandFlag = GetControlValue(control);
			break;
		case kScrollSettingID:
			gScrollFlag = GetControlValue(control);
			break;
		case kDirSettingID:
			gDirection = GetControlValue(control)-1;
			break;
		case kSpeedSettingID:
		{
			UInt32 speeds[5] = {0, SG_MINDELAY, SG_FASTDELAY, SG_NORMDELAY, SG_SLOWDELAY};
			gDelay = speeds[GetControlValue(control)];
		}
			break;
		case kOKSettingID:
			HideWindow(wind);
			break;
	}
	return noErr;
}
#endif
#endif // SpectroGraph


#pragma mark -

#if USE_SUBVIEW

@implementation VisualView

@synthesize visualPluginData = _visualPluginData;

//-------------------------------------------------------------------------------------------------
//	isOpaque
//-------------------------------------------------------------------------------------------------
//
- (BOOL)isOpaque
{
	// your custom views should always be opaque or iTunes will waste CPU time drawing behind you
	return YES;
}

//-------------------------------------------------------------------------------------------------
//	drawRect
//-------------------------------------------------------------------------------------------------
//
-(void)drawRect:(NSRect)dirtyRect
{
	if ( _visualPluginData != NULL )
	{
		DrawVisual( _visualPluginData );
	}
}

//-------------------------------------------------------------------------------------------------
//	acceptsFirstResponder
//-------------------------------------------------------------------------------------------------
//
- (BOOL)acceptsFirstResponder
{
	return YES;
}

//-------------------------------------------------------------------------------------------------
//	becomeFirstResponder
//-------------------------------------------------------------------------------------------------
//
- (BOOL)becomeFirstResponder
{
	return YES;
}

//-------------------------------------------------------------------------------------------------
//	resignFirstResponder
//-------------------------------------------------------------------------------------------------
//
- (BOOL)resignFirstResponder
{
	return YES;
}

//-------------------------------------------------------------------------------------------------
//	keyDown
//-------------------------------------------------------------------------------------------------
//
-(void)keyDown:(NSEvent *)theEvent
{
	// Handle key events here.
	// Do not eat the space bar, ESC key, TAB key, or the arrow keys: iTunes reserves those keys.

	// if the 'i' key is pressed, reset the info timeout so that we draw it again
	if ( [[theEvent charactersIgnoringModifiers] isEqualTo:@"i"] )
	{
		UpdateInfoTimeOut( _visualPluginData );
		return;
	}

	// Pass all unhandled events up to super so that iTunes can handle them.
	[super keyDown:theEvent];
}

@end

#endif	// USE_SUBVIEW

#pragma mark -

//-------------------------------------------------------------------------------------------------
//	GetVisualName
//-------------------------------------------------------------------------------------------------
//
void GetVisualName( ITUniStr255 name )
{
	CFIndex length = CFStringGetLength( kTVisualPluginName );

	name[0] = (UniChar)length;
	CFStringGetCharacters( kTVisualPluginName, CFRangeMake( 0, length ), &name[1] );
}

//-------------------------------------------------------------------------------------------------
//	GetVisualOptions
//-------------------------------------------------------------------------------------------------
//
OptionBits GetVisualOptions( void )
{
	OptionBits		options = (kVisualSupportsMuxedGraphics | kVisualWantsIdleMessages | kVisualWantsConfigure);
	
#if USE_SUBVIEW
	options |= kVisualUsesSubview;
#endif

	return options;
}

//-------------------------------------------------------------------------------------------------
//	iTunesPluginMainMachO
//-------------------------------------------------------------------------------------------------
//
OSStatus iTunesPluginMainMachO( OSType message, PluginMessageInfo * messageInfo, void * refCon )
{
	OSStatus		status;
	
	(void) refCon;
	
	switch ( message )
	{
		case kPluginInitMessage:
			status = RegisterVisualPlugin( messageInfo );
			break;
			
		case kPluginCleanupMessage:
			status = noErr;
			break;
			
		default:
			status = unimpErr;
			break;
	}
	
	return status;
}

#pragma mark -
#pragma mark OLD SpectroGraph CODE
#if 0
/*
 * File:       iTunesPlugIn.c
 *
 * Abstract:   SpectroGraph, a visual plug-in for iTunes
 *
 * Version:    2.0
 *
 * Author:     Alexander Thomas (http://www.dr-lex.be)
 *
 * License: You may modify this source code and publish the modified plug-in, at the
 *          condition that the modified source code is also made available to the public.
 *          This requirement holds as long as the resulting plug-in is similar to
 *          SpectroGraph, i.e. the basic functionality, displaying a moving spectrogram,
 *          possibly with separate colors for left and right channels, is preserved.
 *          If you make improvements to this plug-in, I would like to hear from you so
 *          I can update the SpectroGraph webpage. Please contact me at:
 *          http://www.dr-lex.be/mailform.html?subject=SpectroGraph
 *          This plug-in and its source code are provided without any implied warranties
 *          of fitness for a particular purpose. Use at your own risk.
 *
 * Change History (most recent first):
 *   08/08/16   Lex     Complete rewrite, using OpenGL for rendering, added scrolling
 *   06/12/26   Lex     fixed overflow bug in speed limiter (released 1.2.1)
 *   06/11/25   Lex     added speed limiter, Universal Binary, released SpectroGraph 1.2
 *   06/06/06   Lex     added anti-banding, released SpectroGraph 1.1
 *   04/07/02   Lex     made SpectroGraph source available to public
 *   01/06/20   Lex     released SpectroGraph 1.0 conversion
 *   01/06/06   KG      moved to project builder on Mac OS X
 *   01/04/17   DTS     first checked in.
 *
 * TODO: adapt for Windows. Some parts are provided, but a lot of work remains.
 *
 */

//########################################
//	includes
//########################################

#include <unistd.h>
#include <math.h>
#include "iTunesVisualAPI.h"

#if TARGET_OS_MAC
#include <AGL/agl.h>
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>
#include <sys/time.h> // this may be tricky to get working under Windows
#endif


// Define to enable extra tests and console messages
//#define SG_DEBUG

//########################################
//	typedef's, struct's, enum's, etc.
//########################################

#define kTVisualPluginName              "\014SpectroGraph"
#define	kTVisualPluginCreator			'hook'

#define	kTVisualPluginMajorVersion		2
#define	kTVisualPluginMinorVersion		0
#define	kTVisualPluginReleaseStage		finalStage
//#define	kTVisualPluginReleaseStage		developStage
#define	kTVisualPluginNonFinalRelease	0

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


#define SG_USLEEP		1000
#define SG_FACTOR		1.1
/* SG_MINDELAY must be such that SG_FACTOR*SG_MINDELAY >= SG_MINDELAY+1 */
#define SG_MINDELAY		10 // 100000lps
#define SG_FASTDELAY	1000 // 1000lps
#define SG_NORMDELAY	7500  // 133lps
#define SG_SLOWDELAY	100000 // 10lps
#define SG_MAXDELAY		1000000 // 1lps

// Choosing the right types here is crucial for optimal speed of glCopyTexSubImage2D
#if __BIG_ENDIAN__
#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8_REV
#else
#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8
#endif


// These IDs correspond to the IDs in Interface Builder
enum {
	kColorSettingID  = 1, 
	kInvertSettingID = 2,
	kBandSettingID   = 3,
	kScrollSettingID = 4,
	kDirSettingID    = 5,
	kSpeedSettingID  = 6,
	kOKSettingID     = 7
};

struct VisualPluginData {
	void *				appCookie;
	ITAppProcPtr		appProc;
    
#if TARGET_OS_MAC
	CGrafPtr			destPort;
#else
	HWND				destPort;
#endif
	Rect				destRect;
	OptionBits			destOptions;
	UInt32				destBitDepth;
    
	RenderVisualData	renderData;
	UInt32				renderTimeStampID;
	
	ITTrackInfo			trackInfo;
	ITStreamInfo		streamInfo;
    
	Boolean				playing;
	Boolean				padding[3];
    
    //	Plugin-specific data
	UInt8				minLevel[kVisualMaxDataChannels];		// 0-128
	UInt8				maxLevel[kVisualMaxDataChannels];		// 0-128
    
	UInt8				min, max;
};
typedef struct VisualPluginData VisualPluginData;

#if TARGET_OS_MAC
static AGLContext myContext = NULL;
// not sure if I'll need this, gives all kinds of info about monitor
//static CGDirectDisplayID directDisplayId;
#else
// TODO! Windows stuff comes here
#endif

//########################################
//	local ( static ) globals
//########################################

static Boolean	gColorFlag   = TRUE;
static Boolean	gInvertFlag  = FALSE;
static Boolean	gBandFlag    = TRUE;
static Boolean	gScrollFlag  = FALSE;
static UInt8	gDirection   = 0;
static GLuint	*pnTextureID = NULL; // Array with IDs
static UInt8	gnTexID;    // current texture index
static UInt32	gnPosition; // position inside texture
static UInt8	gnLPU;      // number of lines per update

static UInt32	gDelay = SG_NORMDELAY;
static struct timeval	gLineTimeStamp = {0,0};
static struct timeval	gFrameTimeStamp = {0,0};
#ifdef SG_DEBUG
static struct timeval	gFPSTimeStamp = {0,0};
#endif


//########################################
//	static ( local ) functions
//########################################

/* Set time reference */
static inline void startuSec( struct timeval *tv )
{
	gettimeofday(tv, NULL);
}

/* Return number of microseconds since last call of startuSec.
 * This will overflow after 1 hour, 11 minutes and 34.967 seconds. */
static inline UInt32 getuSec( struct timeval tv )
{
	UInt32 result;
	struct timeval timeNow;
	gettimeofday(&timeNow, NULL);
	result = timeNow.tv_sec-tv.tv_sec;
	return 1000000*result+(timeNow.tv_usec-tv.tv_usec);
}


/* Returns the nearest speed menu setting to the current setting */
static UInt8 delayToSpeed( UInt32 delay )
{
	/* As with many things, a logarithmic scale is better here than a linear one.
	 * It's a bit stupid to recalculate the sqrts every time because they're known
	 * at compile time. But hey, this code is not executed 1000 times per second. */
	if( delay <= SG_MINDELAY )
		return 1;
	else if( delay <= sqrt(SG_FASTDELAY*SG_NORMDELAY) )
		return 2;
	else if( delay <= sqrt(SG_NORMDELAY*SG_SLOWDELAY) )
		return 3;
	else
		return 4;
}


#ifdef SG_DEBUG
static int checkGLError( const char *funcName )
{
 	GLenum suckage = glGetError();
	if( suckage == GL_NO_ERROR ) {
		//fprintf(stderr, "%s says GL_NO_ERROR\n", funcName ); // DEBUG
		return 0;
	}
	if( suckage == GL_INVALID_ENUM )
		fprintf(stderr, "%s barfs: GL_INVALID_ENUM\n", funcName );
	else if( suckage == GL_INVALID_VALUE )
		fprintf(stderr, "%s barfs: GL_INVALID_VALUE\n", funcName );
	else if( suckage == GL_INVALID_OPERATION )
		fprintf(stderr, "%s barfs: GL_INVALID_OPERATION\n", funcName );
	else if( suckage == GL_STACK_OVERFLOW )
		fprintf(stderr, "%s barfs: GL_STACK_OVERFLOW\n", funcName );
	else if( suckage == GL_STACK_UNDERFLOW )
		fprintf(stderr, "%s barfs: GL_STACK_UNDERFLOW\n", funcName );
	else if( suckage == GL_OUT_OF_MEMORY )
		fprintf(stderr, "%s barfs: GL_OUT_OF_MEMORY\n", funcName );
	else
		fprintf(stderr, "%s barfs an unknown error: %d\n", funcName, (int)suckage );
	return 1;
}
#endif


//########################################
// setupTextures
//########################################
static void setupTextures( void )
{
	unsigned int i;
	unsigned char *blankTexture = malloc(SG_TEXWIDTH*SG_TEXHEIGHT*4);
	memset( blankTexture, 0, SG_TEXWIDTH*SG_TEXHEIGHT*4 );
	if(pnTextureID)
		free(pnTextureID);
	// Strictly spoken, we only need to alloc enough textures to cover the viewport,
	// but this would make resizing complicated.
	pnTextureID = malloc(SG_NTEXTURES*sizeof(GLuint));
	glEnable(GL_TEXTURE_2D);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glGenTextures(SG_NTEXTURES, pnTextureID);
#ifdef SG_DEBUG
	checkGLError("glGenTextures");
#endif
	for( i=0; i<SG_NTEXTURES; i++ ) {
		glBindTexture(GL_TEXTURE_2D, pnTextureID[i]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		// Turn off texture repeating
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB,    //target, LOD (for mipmaps), internalFormat
		             SG_TEXWIDTH, SG_TEXHEIGHT,   //w, h
		             0, GL_BGRA, ARGB_IMAGE_TYPE, //border, format, type
		             blankTexture);               //data
	}
	free(blankTexture);
	glEnable(GL_TEXTURE_2D);
	gnPosition = 0;
	gnTexID = 0;
}

//########################################
// initOpenGL
//########################################
static void initOpenGL( void )
{
#if TARGET_OS_MAC
	AGLPixelFormat fmt;
	GLint attrib[] = {AGL_RGBA, AGL_RED_SIZE, 8, AGL_GREEN_SIZE, 8, AGL_BLUE_SIZE, 8, AGL_ALPHA_SIZE, 8, AGL_ACCELERATED, AGL_DOUBLEBUFFER, AGL_DEPTH_SIZE, 24, AGL_CLOSEST_POLICY, AGL_NONE};
	
	//directDisplayId = CGMainDisplayID();
	fmt = aglChoosePixelFormat(NULL, 0, attrib);
	// should test if fmt == NULL
	// create AGL context
	myContext = aglCreateContext(fmt, NULL);
	// should test if myContext == NULL
	aglDestroyPixelFormat(fmt);
#else
	// TODO: add stuff for Windows WGL
#endif
}	


static void UInt8ToARGB(UInt8 pValueL, UInt8 pValueR, UInt8 *pARGBPtr)
{
	if(gInvertFlag) {
		pValueL = 0xFF-pValueL;
		pValueR = 0xFF-pValueR;
	}
	
	pARGBPtr[0] = 0xFF;
	if(gColorFlag)	{
		pARGBPtr[1] = pValueL;
		pARGBPtr[2] = pValueR;
		pARGBPtr[3] = 0x00;
	}
	else
		pARGBPtr[3] = pARGBPtr[2] = pARGBPtr[1] = (pValueL+pValueR)/2;
}

static UInt8 freshPixels[SG_TEXWIDTH*4*SG_MAXCHUNK];
static int nStored = 0;
#ifdef SG_DEBUG
static unsigned int nFps = 0;
#endif




/*
 Restart drawing (only in scan mode)
 */
void rewindDisplay()
{
	if(!gScrollFlag) {
		gnPosition = 0;
		gnTexID = 0;
	}
}


#endif