//
//  Spectroincs.cpp
//  Spectronics
//
//  Created by Ivan Wick on 12/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//-------------------------------------------------------------------------------------------------
//	includes
//-------------------------------------------------------------------------------------------------

#include "Spectronics.h"

#include <string.h>

//-------------------------------------------------------------------------------------------------
// ProcessRenderData
//-------------------------------------------------------------------------------------------------
//
void ProcessRenderData( VisualPluginData * visualPluginData, UInt32 timeStampID, const RenderVisualData * renderData )
{
	SInt16		index;
	SInt32		channel;

	visualPluginData->renderTimeStampID	= timeStampID;

	if ( renderData == NULL )
	{
		memset( &visualPluginData->renderData, 0, sizeof(visualPluginData->renderData) );
		return;
	}

	visualPluginData->renderData = *renderData;
	
	for ( channel = 0;channel < renderData->numSpectrumChannels; channel++ )
	{
		visualPluginData->minLevel[channel] = 
			visualPluginData->maxLevel[channel] = 
			renderData->spectrumData[channel][0];

		for ( index = 1; index < kVisualNumSpectrumEntries; index++ )
		{
			UInt8		value;
			
			value = renderData->spectrumData[channel][index];

			if ( value < visualPluginData->minLevel[channel] )
				visualPluginData->minLevel[channel] = value;
			else if ( value > visualPluginData->maxLevel[channel] )
				visualPluginData->maxLevel[channel] = value;
		}
	}

	
    /* (SpectroGraph: originally gBandFlag)
	 * Anti-banding: we assume there is no frequency content in the highest
	 * frequency possible (which should be the case for all normal music).
	 * So if there is something there, we subtract it from all frequencies. */
    if (visualPluginData->biasNormFlag) {
        UInt8 *spectrumDataL = visualPluginData->renderData.spectrumData[0],
        *spectrumDataR = visualPluginData->renderData.spectrumData[1];
        SInt16 i;
        SInt16 biasL = spectrumDataL[kVisualNumSpectrumEntries/2-1],
        biasR = spectrumDataR[kVisualNumSpectrumEntries/2-1];
        for( i=0; i<kVisualNumSpectrumEntries/2; i++ ) {
            spectrumDataL[i] -= (spectrumDataL[i]-biasL > 0) ? biasL : spectrumDataL[i];
            spectrumDataR[i] -= (spectrumDataR[i]-biasR > 0) ? biasR : spectrumDataR[i];
        }
    }

    InternalizeRenderData(visualPluginData);
	/* This just finds the min & max values of the spectrum data, if
	 * there's no need for this, you can drop this to save some CPU */
    /*	for (channel = 0;channel < renderData->numSpectrumChannels;channel++)
     {
     visualPluginDataPtr->minLevel[channel] = 
     visualPluginDataPtr->maxLevel[channel] = 
     renderData->spectrumData[channel][0];
     
     for (index = 1; index < kVisualNumSpectrumEntries; index++)
     {
     UInt8		value;
     
     value = renderData->spectrumData[channel][index];
     
     if (value < visualPluginDataPtr->minLevel[channel])
     visualPluginDataPtr->minLevel[channel] = value;
     else if (value > visualPluginDataPtr->maxLevel[channel])
     visualPluginDataPtr->maxLevel[channel] = value;
     }
     }*/
}


//-------------------------------------------------------------------------------------------------
//	ResetRenderData
//-------------------------------------------------------------------------------------------------
//
void ResetRenderData( VisualPluginData * visualPluginData )
{
	memset( &visualPluginData->renderData, 0, sizeof(visualPluginData->renderData) );

	// ivan- the following line and then all the rest do the same thing w/e
    memset( visualPluginData->minLevel, 0, sizeof(visualPluginData->minLevel) );
    
	visualPluginData->minLevel[0] = 
    visualPluginData->minLevel[1] =
    visualPluginData->maxLevel[0] =
    visualPluginData->maxLevel[1] = 0;
}


//-------------------------------------------------------------------------------------------------
//	UpdateInfoTimeOut
//-------------------------------------------------------------------------------------------------
//
void UpdateInfoTimeOut( VisualPluginData * visualPluginData )
{
	// reset the timeout value we will use to show the info/artwork if we have it during DrawVisual()
	visualPluginData->drawInfoTimeOut = time( NULL ) + kInfoTimeOutInSeconds;
}

//-------------------------------------------------------------------------------------------------
//	UpdatePulseRate
//-------------------------------------------------------------------------------------------------
//
void UpdatePulseRate( VisualPluginData * visualPluginData, UInt32 * ioPulseRate )
{
	// vary the pulse rate based on whether or not iTunes is currently playing
	if ( visualPluginData->playing )
		*ioPulseRate = kPlayingPulseRateInHz;
	else
		*ioPulseRate = kStoppedPulseRateInHz;
}

//-------------------------------------------------------------------------------------------------
//	UpdateTrackInfo
//-------------------------------------------------------------------------------------------------
//
void UpdateTrackInfo( VisualPluginData * visualPluginData, ITTrackInfo * trackInfo, ITStreamInfo * streamInfo )
{
	if ( trackInfo != NULL )
		visualPluginData->trackInfo = *trackInfo;
	else
		memset( &visualPluginData->trackInfo, 0, sizeof(visualPluginData->trackInfo) );

	if ( streamInfo != NULL )
		visualPluginData->streamInfo = *streamInfo;
	else
		memset( &visualPluginData->streamInfo, 0, sizeof(visualPluginData->streamInfo) );

	UpdateInfoTimeOut( visualPluginData );
}

//-------------------------------------------------------------------------------------------------
//	RequestArtwork
//-------------------------------------------------------------------------------------------------
//
static void RequestArtwork( VisualPluginData * visualPluginData )
{
	// only request artwork if this plugin is active
	if ( visualPluginData->destView != NULL )
	{
		OSStatus		status;

		status = PlayerRequestCurrentTrackCoverArt( visualPluginData->appCookie, visualPluginData->appProc );
	}
}

//-------------------------------------------------------------------------------------------------
//	PulseVisual
//-------------------------------------------------------------------------------------------------
//
void PulseVisual( VisualPluginData * visualPluginData, UInt32 timeStampID, const RenderVisualData * renderData, UInt32 * ioPulseRate )
{
	// update internal state
	ProcessRenderData( visualPluginData, timeStampID, renderData );

	// if desired, adjust the pulse rate
	UpdatePulseRate( visualPluginData, ioPulseRate );
}

//-------------------------------------------------------------------------------------------------
//	VisualPluginHandler
//-------------------------------------------------------------------------------------------------
//
static OSStatus VisualPluginHandler(OSType message,VisualPluginMessageInfo *messageInfo,void *refCon)
{
	OSStatus			status;
	VisualPluginData *	visualPluginData;
    
	visualPluginData = (VisualPluginData*) refCon;
	
	status = noErr;
    
	switch (message)
	{
            /*
             * Apple says:
             Sent when the visual plugin is registered.  The plugin should do minimal
             memory allocations here.  The resource fork of the plugin is still available.
             * I say:
             iTunes will 'register' each plugin when iTunes is started. Even though your plug-in
             will not necessarily be shown on this occasion, you can still do some initializations.
             However, don't do anything that will hog memory or take ages.
             */		
		case kVisualPluginInitMessage:
        {
			visualPluginData = (VisualPluginData*) calloc(1, sizeof(VisualPluginData));
			if (visualPluginData == NULL)
			{
				status = memFullErr;
				break;
			}
            
			visualPluginData->appCookie	= messageInfo->u.initMessage.appCookie;
			visualPluginData->appProc	= messageInfo->u.initMessage.appProc;
            
			messageInfo->u.initMessage.refCon	= (void*) visualPluginData;
            InitPlugin(visualPluginData);
            
            #ifdef SG_DEBUG
                fprintf(stderr, "SpectroGraph inited\n");
            #endif
			break;
		}	
        /*
             Sent when the visual plugin is unloaded
        */
		case kVisualPluginCleanupMessage:
        {
            #ifdef SG_DEBUG
                fprintf(stderr, "Unloading SpectroGraph...\n");
            #endif
            CleanupPlugin(visualPluginData);
			if (visualPluginData != NULL)
				free(visualPluginData);
			break;
		}
            
            /*
             Sent when the visual plugin is enabled.  iTunes currently enables all
             loaded visual plugins.  The plugin should not do anything here.
             */
		case kVisualPluginEnableMessage:
		case kVisualPluginDisableMessage:
        {
			break;
        }
            
            /*
             Sent if the plugin requests idle messages.  Do this by setting the kVisualWantsIdleMessages
             option in the RegisterVisualMessage.options field.
             */
		case kVisualPluginIdleMessage:
        {
			/* This is where it gets nasty. Idle messages can be sent at any time: while iTunes is playing
			 * (frequently), when paused (constantly), and even when the visualizer is off (a few times
			 * per second). Moreover, _all_ plug-ins receive idle messages even if another one is active.
			 * Because I used 0xFFFFFFFF for timeBetweenData, iTunes will use 100% cpu, both during playback
			 * and while paused. This is why I included the usleep calls. Mind that usleep will pause the
			 * _entire_ iTunes process, so a sensible value must be used (1msec doesn't seem to interfere
			 * with normal operation).
			 * I need to check if iTunes is paused to avoid messing up the timing of the rendering routine,
			 * and check if the plug-in is active to avoid rendering a non-existing port. */
            
            #if 0 // ivan
			if( visualPluginData->playing == false && visualPluginData->destPort != nil ) {
				if( getuSec(gLineTimeStamp) > gDelay ) {
					startuSec(&gLineTimeStamp);
					RenderVisualPort(visualPluginData,visualPluginData->destPort,&visualPluginData->destRect,false);
				}
				else
					usleep(SG_USLEEP); // TODO: find Windows equivalent
			}
            #endif
			break;
		}
            
            /*
             Sent if the plugin requests the ability for the user to configure it.  Do this by setting
             the kVisualWantsConfigure option in the RegisterVisualMessage.options field.
             */
		case kVisualPluginConfigureMessage:
        {
			status = ConfigureVisual( visualPluginData );
			break;
		}

        /*
             Sent when iTunes is going to show the visual plugin.  At this
             point, the plugin should allocate any large buffers it needs.
        */
        /* this is mostly platform-specific so the original SpectroGraph code
           got moved into the SpactrographMac.mm file.
        */
		case kVisualPluginActivateMessage:
        {
			status = ActivateVisual( visualPluginData, messageInfo->u.activateMessage.view, messageInfo->u.activateMessage.options );
            
			// note: do not draw here if you can avoid it, a draw message will be sent as soon as possible
			
			if ( status == noErr )
				RequestArtwork( visualPluginData );
			break;
		}	

        /*
            Sent when this visual is no longer displayed.
        */
        /* ivan - copied from example code. the original was platform-specific
               and went into the SpactrographMac.mm file.
        */
		case kVisualPluginDeactivateMessage:
		{
			UpdateTrackInfo( visualPluginData, NULL, NULL );
            
			status = DeactivateVisual( visualPluginData );
			break;
		}

        /*
            Sent when iTunes is moving the destination view to a new parent window (e.g. to/from fullscreen).
        */
		case kVisualPluginWindowChangedMessage:
		{
			status = MoveVisual( visualPluginData, messageInfo->u.windowChangedMessage.options );
			break;
		}
        /*
             Sent when iTunes has changed the rectangle of the currently displayed visual.
             
             Note: for custom NSView subviews, the subview's frame is automatically resized.
        */
		case kVisualPluginFrameChangedMessage:
		{
			status = ResizeVisual( visualPluginData );
			break;
		}
            
        /*
             It's time for the plugin to draw a new frame.
             
             For plugins using custom subviews, you should ignore this message and just
             draw in your view's draw method.  It will never be called if your subview 
             is set up properly.
        */
        /* We're using a subview on MacOS but in Windows, you'll need to call DrawVisual from here. */
		case kVisualPluginDrawMessage:
		{
            #if !USE_SUBVIEW
			DrawVisual( visualPluginData );
            #endif
			break;
		}

        /*
             Sent for the visual plugin to update its internal animation state.
             Plugins are allowed to draw at this time but it is more efficient if they
             wait until the kVisualPluginDrawMessage is sent OR they simply invalidate
             their own subview.  The pulse message can be sent faster than the system
             will allow drawing to support spectral analysis-type plugins but drawing
             will be limited to the system refresh rate.
         */
		case kVisualPluginPulseMessage:
		{
			PulseVisual( visualPluginData,
                        messageInfo->u.pulseMessage.timeStampID,
                        messageInfo->u.pulseMessage.renderData,
                        &messageInfo->u.pulseMessage.newPulseRateInHz );
            
			InvalidateVisual( visualPluginData );
			break;
		}

        /*
             Sent when the player starts.
        */
		case kVisualPluginPlayMessage:
		{
			visualPluginData->playing = true;
			
			UpdateTrackInfo( visualPluginData, messageInfo->u.playMessage.trackInfo, messageInfo->u.playMessage.streamInfo );
            
			RequestArtwork( visualPluginData );
			
			InvalidateVisual( visualPluginData );
			break;
		}            
            
        /*
             Sent when the player changes the current track information.  This
             is used when the information about a track changes,or when the CD
             moves onto the next track.  The visual plugin should update any displayed
             information about the currently playing song.
         */
		case kVisualPluginChangeTrackMessage:
        {
			UpdateTrackInfo( visualPluginData, messageInfo->u.changeTrackMessage.trackInfo, messageInfo->u.changeTrackMessage.streamInfo );
            
			RequestArtwork( visualPluginData );
            
			InvalidateVisual( visualPluginData );
			break;
		}
        /*
             Artwork for the currently playing song is being delivered per a previous request.
             
             Note that NULL for messageInfo->u.coverArtMessage.coverArt means the currently playing song has no artwork.
        */
        case kVisualPluginCoverArtMessage:
        {
            UpdateArtwork(  visualPluginData,
                          messageInfo->u.coverArtMessage.coverArt,
                          messageInfo->u.coverArtMessage.coverArtSize,
                          messageInfo->u.coverArtMessage.coverArtFormat );
            
            InvalidateVisual( visualPluginData );
            break;
        }            
        /*
             Sent when the player stops.
        */
		case kVisualPluginStopMessage:
        {
			visualPluginData->playing = false;
			
			ResetRenderData( visualPluginData );
            
			InvalidateVisual( visualPluginData );
			break;
		}
            
        /*
             Sent when the player changes position.
        */
		case kVisualPluginSetPositionMessage:
        {
            break;
        }

		default:
			status = unimpErr;
			break;
	}
	return status;
}



//-------------------------------------------------------------------------------------------------
//	RegisterVisualPlugin
//-------------------------------------------------------------------------------------------------
//
OSStatus RegisterVisualPlugin( PluginMessageInfo * messageInfo )
{
	PlayerMessageInfo	playerMessageInfo;
	OSStatus			status;
		
	memset( &playerMessageInfo.u.registerVisualPluginMessage, 0, sizeof(playerMessageInfo.u.registerVisualPluginMessage) );

	GetVisualName( playerMessageInfo.u.registerVisualPluginMessage.name );

	SetNumVersion( &playerMessageInfo.u.registerVisualPluginMessage.pluginVersion, kTVisualPluginMajorVersion, kTVisualPluginMinorVersion, kTVisualPluginReleaseStage, kTVisualPluginNonFinalRelease );

	playerMessageInfo.u.registerVisualPluginMessage.options					= GetVisualOptions();
	playerMessageInfo.u.registerVisualPluginMessage.handler					= (VisualPluginProcPtr)VisualPluginHandler;
	playerMessageInfo.u.registerVisualPluginMessage.registerRefCon			= 0;
	playerMessageInfo.u.registerVisualPluginMessage.creator					= kTVisualPluginCreator;
	
	playerMessageInfo.u.registerVisualPluginMessage.pulseRateInHz			= kStoppedPulseRateInHz;	// update my state N times a second
	playerMessageInfo.u.registerVisualPluginMessage.numWaveformChannels		= 2;
	playerMessageInfo.u.registerVisualPluginMessage.numSpectrumChannels		= 2;
	
	playerMessageInfo.u.registerVisualPluginMessage.minWidth				= 64;
	playerMessageInfo.u.registerVisualPluginMessage.minHeight				= 64;
	playerMessageInfo.u.registerVisualPluginMessage.maxWidth				= 0;	// no max width limit
	playerMessageInfo.u.registerVisualPluginMessage.maxHeight				= 0;	// no max height limit
	
	status = PlayerRegisterVisualPlugin( messageInfo->u.initMessage.appCookie, messageInfo->u.initMessage.appProc, &playerMessageInfo );
    
	return status;
	
    /* some initialization left over from spectrograph */
    /*
	startuSec(&gLineTimeStamp);
	startuSec(&gFrameTimeStamp);
	gnLPU = SG_MAXCHUNK;
    */
	/* * * * * * * */
}
