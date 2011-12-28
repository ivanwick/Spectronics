//
//  SpectronicsMac.mm
//  Spectronics
//
//  Created by Ivan Wick on 12/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//-------------------------------------------------------------------------------------------------
//	includes
//-------------------------------------------------------------------------------------------------

#import "Spectronics.h"

#import <string.h>

#import "SettingsController.h"
#import "VisualView.h"

//-------------------------------------------------------------------------------------------------
//	constants, etc.
//-------------------------------------------------------------------------------------------------

#define kTVisualPluginName              CFSTR("Spectronics Visualizer")


//-------------------------------------------------------------------------------------------------
//	exported function prototypes
//-------------------------------------------------------------------------------------------------

extern "C" OSStatus iTunesPluginMainMachO( OSType inMessage, PluginMessageInfo *inMessageInfoPtr, void *refCon ) __attribute__((visibility("default")));


void InitPlugin( VisualPluginData * vpd )
{
    /* Load Settings */
    char databuffer[4096];
    UInt32 retrsize = 0;
    OSStatus result = noErr;
    
    vpd->settingsController = [[SettingsController alloc]
                                initWithWindowNibName:@"ConfigurePanel"];
    vpd->settingsController.visualPluginData = vpd;

    result = PlayerGetPluginData(vpd->appCookie, vpd->appProc, &databuffer, 4096, &retrsize);
    // TODO: add error checking
    
    if (result == noErr && retrsize > 0) {
        // We got some serialized data from iTunes, assume it's the prefs dictionary
        
        NSData *storedData = [NSData dataWithBytesNoCopy:databuffer length:retrsize freeWhenDone:NO];
        NSDictionary *retrDict;
        NSError *serializeErr = nil;
        NSPropertyListFormat plistFormat;
        
        retrDict =
            [NSPropertyListSerialization propertyListWithData:storedData
                                                      options:nil
                                                       format:&plistFormat
                                                        error:&serializeErr];

        // TODO: add error checking

        [vpd->settingsController setValuesForKeysWithDictionary:retrDict];
    }
}

void CleanupPlugin( VisualPluginData * vpd )
{
    NSData *plistData;
    NSError *serializeErr;
    OSStatus result = noErr;

    NSDictionary *savePrefs = [vpd->settingsController preferencesDictionary];

    plistData = [NSPropertyListSerialization dataWithPropertyList:savePrefs
                                                           format:NSPropertyListBinaryFormat_v1_0
                                                          options:nil
                                                            error:&serializeErr];

    result = PlayerSetPluginData(vpd->appCookie, vpd->appProc,
                                 (void*)[plistData bytes], // can't be const void *
                                 [plistData length]);

    // TODO: add error checking
    
    [vpd->settingsController release];
}

void InternalizeRenderData( VisualPluginData * vpd )
{
    if (vpd == NULL) {
        return;
    }
    
    [(vpd->subview) saveRenderData:&(vpd->renderData)];
}


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
    [visualPluginData->subview addObserversForSettings:visualPluginData->settingsController];
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

#ifdef SG_DEBUG
    startuSec(&gFPSTimeStamp);
    fprintf(stderr, "SpectroGraph started\n");
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
    [visualPluginData->subview removeObserversForSettings];
	
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


//-------------------------------------------------------------------------------------------------
//	ConfigureVisual
//-------------------------------------------------------------------------------------------------
//
OSStatus ConfigureVisual( VisualPluginData * visualPluginData )
{
	// Nib's already set up (see InitPlugin), so cause it to get the window out of it
    // load nib
    NSWindow* window = [visualPluginData->settingsController window];
    [window setDelegate:visualPluginData->settingsController];
    
	// show settings window
    [window makeKeyAndOrderFront:nil];
    
	return noErr;
}


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

