//
//  VisualView.m
//  Spectronics
//
//  Created by Ivan Wick on 12/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VisualView.h"

#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#import <sys/time.h>  // ivan- for all the SpectroGraph aux functions dealing with usec


#define SG_USLEEP		1000
#define SG_FACTOR		1.1
/* SG_MINDELAY must be such that SG_FACTOR*SG_MINDELAY >= SG_MINDELAY+1 */
#define SG_MINDELAY		10 // 100000lps
#define SG_FASTDELAY	1000 // 1000lps
#define SG_NORMDELAY	7500  // 133lps
#define SG_SLOWDELAY	100000 // 10lps
#define SG_MAXDELAY		1000000 // 1lps


#ifdef SG_DEBUG
static unsigned int nFps = 0;
#endif

// Choosing the right types here is crucial for optimal speed of glCopyTexSubImage2D
#if __BIG_ENDIAN__
#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8_REV
#else
#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8
#endif



static void UInt8ToARGB(UInt8 pValueL, UInt8 pValueR, UInt8 *pARGBPtr, BOOL gInvertFlag, BOOL gColorFlag)
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



#pragma mark -

@implementation VisualView

@synthesize visualPluginData = _visualPluginData;

@synthesize invertColors;
@synthesize color;
@synthesize scroll;

@synthesize settingsController;

//-------------------------------------------------------------------------------------------------
//	isOpaque
//-------------------------------------------------------------------------------------------------
//
- (BOOL)isOpaque
{
	// your custom views should always be opaque or iTunes will waste CPU time drawing behind you
	return YES;
}

- (void)initGL
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glFinish();
    
    [self setupTextures];
    
    m_glContextInitialized = YES;
}


//-------------------------------------------------------------------------------------------------
//	drawRect
//-------------------------------------------------------------------------------------------------
//
-(void)drawRect:(NSRect)dirtyRect
{
    if (!m_glContextInitialized) {
        [self initGL];
    }
    
	if ( _visualPluginData != NULL )
	{
        [(_visualPluginData->subview) DrawVisual:_visualPluginData];
	}
}

- (void)reshape // scrolled, moved or resized
{
    NSRect rect;
    [super reshape];
    
    rect = [self bounds];
    
    
    nTimePixels = (gDirection == 0) ? 
        rect.size.width :
        rect.size.height;
    nNumTiles = (int)ceil((float)nTimePixels/SG_TEXHEIGHT);
	if(self.scroll)
		nNumTiles++;
    
    
    glViewport(0, 0, rect.size.width, rect.size.height);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    glOrtho(-1.0, 1.0, -1.0, 1.0, 0.0, 10.0);
    
    glMatrixMode(GL_MODELVIEW);
    
    [self setNeedsDisplay:YES];
}

#if 0 // ivan - from SpectroGraph. Originally part of the plugin handler
/*
 Sent for the visual plugin to render a frame.
 */
case kVisualPluginRenderMessage:
{
    SInt32 timeLeft = gDelay-getuSec(gLineTimeStamp); /* Overflow hazard! Hence the third test below. */
    if( (gDelay == SG_MINDELAY) || timeLeft < 0 || (UInt32)timeLeft > gDelay ) {
        startuSec(&gLineTimeStamp);
        visualPluginData->renderTimeStampID	= messageInfo->u.renderMessage.timeStampID;
        
        ProcessRenderData(visualPluginData,messageInfo->u.renderMessage.renderData);
        
        RenderVisualPort(visualPluginData,visualPluginData->destPort,&visualPluginData->destRect,false);
    }
    else if( timeLeft > SG_USLEEP*1.3 )
        usleep(SG_USLEEP);
    break;
}

#endif

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
    
    SettingsController *sc = self.settingsController;
    
    if ( [[theEvent charactersIgnoringModifiers] isEqualTo:@"b"] ) {
        sc.bandBias = !sc.bandBias;
        return;
    }
    else if ( [[theEvent charactersIgnoringModifiers] isEqualTo:@"c"] ) {
        sc.color = !sc.color;
        return;
    }
    else if ( [[theEvent charactersIgnoringModifiers] isEqualTo:@"i"] ) {
        sc.invertColors = !sc.invertColors;
        return;
    }
    else if ( [[theEvent charactersIgnoringModifiers] isEqualTo:@"l"] ) {
        sc.scroll = !sc.scroll;
        return;
    }
    else if ( [[theEvent charactersIgnoringModifiers] isEqualTo:@"r"] ) {
        /* rewindDisplay(); */
        NSLog(@"rewindDisplay");
        return;
    }
    else if ( [[theEvent charactersIgnoringModifiers] isEqualTo:@"b"] ) {
        sc.bandBias = !sc.bandBias;
        return;
    }
    // if the 'i' key is pressed, reset the info timeout so that we draw it again
    else if ( [[theEvent charactersIgnoringModifiers] isEqualTo:@"i"] ) {
        // TODO
        // this conflicts with "i" above
        // UpdateInfoTimeOut( _visualPluginData );
        return;
    }


	// Pass all unhandled events up to super so that iTunes can handle them.
	[super keyDown:theEvent];
}

#if 0 // ivan - SpectroGraph code
        switch (theChar) {
            case	'h':
            case	'H':
                if(++gDirection > 1)
                    gDirection = 0;
                rewindDisplay();
                status = noErr;
                break;							
            case	'-':
                if( gDelay < SG_MAXDELAY )
                    gDelay *= SG_FACTOR;
                else
                    gDelay = SG_MAXDELAY;
                status = noErr;
                break;
            case	'+':
            case	'=':
                if( gDelay > SG_MINDELAY )
                    gDelay /= SG_FACTOR;
                else
                    gDelay = SG_MINDELAY;
                status = noErr;
                break;
            case	'u':
            case	'U':
                gDelay = SG_MINDELAY;
                status = noErr;
                break;
            case	'f':
            case	'F':
                gDelay = SG_FASTDELAY;
                status = noErr;
                break;
            case	'n':
            case	'N':
                gDelay = SG_NORMDELAY;
                status = noErr;
                break;
            case	's':
            case	'S':
                gDelay = SG_SLOWDELAY;
                status = noErr;
                break;
                
            default:
                status = unimpErr;
                break;
        }
    }
    else
        status = unimpErr;
}
break;
#endif // ivan - SpectroGraph code


-(id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        m_glContextInitialized = NO;
        
        // ivan- SpectroGraph vars initializers
        self.color         = TRUE;
        self.invertColors  = FALSE;
        self.scroll        = FALSE;
        gDirection   = 0;
        pnTextureID = NULL; // Array with IDs
        gnTexID = 0;    // current texture index
        gnPosition = 0; // position inside texture
        gnLPU = SG_MAXCHUNK;      // number of lines per update
        
        gDelay = SG_NORMDELAY;
        gLineTimeStamp = (struct timeval){0,0};
        gFrameTimeStamp = (struct timeval){0,0};
#ifdef SG_DEBUG
        gFPSTimeStamp = {0,0};
#endif
        
        // freshPixels[SG_TEXWIDTH*4*SG_MAXCHUNK]; // init not important.
        nStored = 0;
        nTimePixels = 0;
        nNumTiles = 0;
    }
    return self;
}

- (void) addObserversForSettings:(SettingsController*)sc
{
    [sc addObserver:self forKeyPath:@"invertColors"
            options:NSKeyValueObservingOptionInitial context:nil];
    
    [sc addObserver:self forKeyPath:@"color"
            options:NSKeyValueObservingOptionInitial context:nil];
    
    [sc addObserver:self forKeyPath:@"scroll"
            options:NSKeyValueObservingOptionInitial context:nil];
    
    // need to save this reference in order to properly remove ourself as an observer
    self.settingsController = sc;
}

- (void) removeObserversForSettings
{
    if (self.settingsController) {
        [self.settingsController removeObserver:self forKeyPath:@"invertColors"];
        [self.settingsController removeObserver:self forKeyPath:@"color"];
        [self.settingsController removeObserver:self forKeyPath:@"scroll"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setValue:[object valueForKeyPath:keyPath] forKeyPath:keyPath];
}


//########################################
// setupTextures
//########################################
- (void) setupTextures
{
	unsigned int i;
	unsigned char *blankTexture = (unsigned char*)malloc(SG_TEXWIDTH*SG_TEXHEIGHT*4); // ivan- TODO change to calloc
	memset( blankTexture, 0, SG_TEXWIDTH*SG_TEXHEIGHT*4 ); // ivan- TODO then you don't need to manually clear y0
	if(pnTextureID)
		free(pnTextureID);
	// Strictly spoken, we only need to alloc enough textures to cover the viewport,
	// but this would make resizing complicated.
	pnTextureID = (GLuint *)malloc(SG_NTEXTURES*sizeof(GLuint));   // ivan- TODO change to calloc
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


- (void)saveRenderData:(RenderVisualData*)rvd
{
	UInt8 *spectrumDataL = rvd->spectrumData[0];
    UInt8 *spectrumDataR = rvd->spectrumData[1];
    int i;
    // Update the texture and only draw if chunk is full, otherwise exit
	for( i=0; i<SG_TEXWIDTH; i++ ) {
		UInt8ToARGB( spectrumDataL[i], spectrumDataR[i],
                    &freshPixels[(nStored*SG_TEXWIDTH+i)*4],
                    self.invertColors,
                    self.color );
    }
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
    
    
	if( !self.scroll && gnTexID*SG_TEXHEIGHT+gnPosition >= nTimePixels ) {
        // wrap around again
		gnTexID = 0;
		gnPosition = 0;
	}
	else if( gnPosition >= SG_TEXHEIGHT ) {
		gnPosition = 0;
		gnTexID++;
		if( self.scroll && gnTexID >= nNumTiles )
			gnTexID = 0;
	}
    
    //    NSLog(@"gnTexID: %d gnPosition: %d", gnTexID, gnPosition);
}


-(void) DrawVisual:(VisualPluginData *)visualPluginData
{    
    /* ivan- TODO:
     - drawn in a uniform way, using OpenGL transforms to govern horiz/vert.
     */
    
    // this shouldn't happen but let's be safe
	if ( visualPluginData->destView == NULL )
		return;
    
	int i;
	
	glClearColor( 0.0, 0.0, 0.0, 0.0 );
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
    // ivan- TODO: probably move this into [reshape]
	float fTexWid = SG_TEXHEIGHT*2.0/nTimePixels; // width of a texture in OpenGL world-coordinates
	if(!self.scroll) {
		for( i=0; i<nNumTiles; i++ ) {
			glBindTexture( GL_TEXTURE_2D, pnTextureID[i] );
			glBegin(GL_QUADS);
			if(gDirection == 0) { // Horizontal
				float fLeft = -1.0f+i*fTexWid;
                float fRight = -1.0f+(i+1)*fTexWid;
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
    
    
#if 0
    /********************* ivan- moved artwork drawing code */
    /* doesn't work as-is I think because it's an NSOpenGLView now and drawing is handled differently */
    
    // should we draw the info/artwork in the bottom-left corner?
	time_t		theTime = time( NULL );
    CGPoint where;
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
    /********************* ivan- moved artwork drawing code */
#endif    
}


@end


#pragma mark -

#if 0 // orig from SpectroGraph, will incorporate later
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
