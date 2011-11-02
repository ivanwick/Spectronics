//
// File:       iTunesPlugIn.cpp
//
// Abstract:   Visual plug-in for iTunes.  Cross-platform code.
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

#include "Spactrograph.h"

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
}

#if 0 // SpectroGraph
//########################################
// ProcessRenderData from SpectroGraph
//########################################
static void ProcessRenderData( VisualPluginData *visualPluginDataPtr, const RenderVisualData *renderData )
{
    //	SInt16		index;
    //	SInt32		channel;
    
	if(renderData == nil) {
		MyMemClear(&visualPluginDataPtr->renderData,sizeof(visualPluginDataPtr->renderData));
		return;
	}
    
	visualPluginDataPtr->renderData = *renderData;
	
	/* Anti-banding: we assume there is no frequency content in the highest
	 * frequency possible (which should be the case for all normal music).
	 * So if there is something there, we subtract it from all frequencies. */
	if(gBandFlag) {
		UInt8 *spectrumDataL = visualPluginDataPtr->renderData.spectrumData[0],
        *spectrumDataR = visualPluginDataPtr->renderData.spectrumData[1];
		SInt16 i;
		SInt16 biasL = spectrumDataL[kVisualNumSpectrumEntries/2-1],
        biasR = spectrumDataR[kVisualNumSpectrumEntries/2-1];
		for( i=0; i<kVisualNumSpectrumEntries/2; i++ ) {
			spectrumDataL[i] -= (spectrumDataL[i]-biasL > 0) ? biasL : spectrumDataL[i];
			spectrumDataR[i] -= (spectrumDataR[i]-biasR > 0) ? biasR : spectrumDataR[i];
		}
	}		
	
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
#endif // SpectroGraph





//-------------------------------------------------------------------------------------------------
//	ResetRenderData
//-------------------------------------------------------------------------------------------------
//
void ResetRenderData( VisualPluginData * visualPluginData )
{
	memset( &visualPluginData->renderData, 0, sizeof(visualPluginData->renderData) );
	memset( visualPluginData->minLevel, 0, sizeof(visualPluginData->minLevel) );
}

#if 0 // SpectroGraph
/*
 ResetRenderData from SpectroGraph
 */
static void ResetRenderData(VisualPluginData *visualPluginData)
{
	MyMemClear(&visualPluginData->renderData,sizeof(visualPluginData->renderData));
    
	visualPluginData->minLevel[0] = 
    visualPluginData->minLevel[1] =
    visualPluginData->maxLevel[0] =
    visualPluginData->maxLevel[1] = 0;
}
#endif // SpectroGraph



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

	switch ( message )
	{
		/*
			Sent when the visual plugin is registered.  The plugin should do minimal
			memory allocations here.
		*/		
		case kVisualPluginInitMessage:
		{
			visualPluginData = (VisualPluginData *)calloc( 1, sizeof(VisualPluginData) );
			if ( visualPluginData == NULL )
			{
				status = memFullErr;
				break;
			}

			visualPluginData->appCookie	= messageInfo->u.initMessage.appCookie;
			visualPluginData->appProc	= messageInfo->u.initMessage.appProc;

			messageInfo->u.initMessage.refCon = (void *)visualPluginData;
			break;
		}
		/*
			Sent when the visual plugin is unloaded.
		*/		
		case kVisualPluginCleanupMessage:
		{
			if ( visualPluginData != NULL )
				free( visualPluginData );
			break;
		}
		/*
			Sent when the visual plugin is enabled/disabled.  iTunes currently enables all
			loaded visual plugins at launch.  The plugin should not do anything here.
		*/
		case kVisualPluginEnableMessage:
		case kVisualPluginDisableMessage:
		{
			break;
		}
		/*
			Sent if the plugin requests idle messages.  Do this by setting the kVisualWantsIdleMessages
			option in the RegisterVisualMessage.options field.
			
			DO NOT DRAW in this routine.  It is for updating internal state only.
		*/
		case kVisualPluginIdleMessage:
		{
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
			It's time for the plugin to draw a new frame.
			
			For plugins using custom subviews, you should ignore this message and just
			draw in your view's draw method.  It will never be called if your subview 
			is set up properly.
		*/
		case kVisualPluginDrawMessage:
		{
			#if !USE_SUBVIEW
			DrawVisual( visualPluginData );
			#endif
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
			is used when the information about a track changes.
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
			UpdateArtwork(	visualPluginData,
							messageInfo->u.coverArtMessage.coverArt,
							messageInfo->u.coverArtMessage.coverArtSize,
							messageInfo->u.coverArtMessage.coverArtFormat );
			
			InvalidateVisual( visualPluginData );
			break;
		}
		/*
			Sent when the player stops or pauses.
		*/
		case kVisualPluginStopMessage:
		{
			visualPluginData->playing = false;
			
			ResetRenderData( visualPluginData );

			InvalidateVisual( visualPluginData );
			break;
		}
		/*
			Sent when the player changes the playback position.
		*/
		case kVisualPluginSetPositionMessage:
		{
			break;
		}
		default:
		{
			status = unimpErr;
			break;
		}
	}

	return status;	
}

#if 0 // SpectroGraph
/*
 VisualPluginHandler from SpectroGraph
 */
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
			if (visualPluginData == nil)
			{
				status = memFullErr;
				break;
			}
            
			visualPluginData->appCookie	= messageInfo->u.initMessage.appCookie;
			visualPluginData->appProc	= messageInfo->u.initMessage.appProc;
            
			messageInfo->u.initMessage.refCon	= (void*) visualPluginData;
#ifdef SG_DEBUG
			fprintf(stderr, "SpectroGraph inited\n");
#endif
			break;
		}
			
            /*
             Sent when the visual plugin is unloaded
             */		
		case kVisualPluginCleanupMessage:
#ifdef SG_DEBUG
			fprintf(stderr, "Unloading SpectroGraph...\n");
#endif
			if (visualPluginData != nil)
				free(visualPluginData);
			break;
			
            /*
             Sent when the visual plugin is enabled.  iTunes currently enables all
             loaded visual plugins.  The plugin should not do anything here.
             */
		case kVisualPluginEnableMessage:
		case kVisualPluginDisableMessage:
			break;
            
            /*
             Sent if the plugin requests idle messages.  Do this by setting the kVisualWantsIdleMessages
             option in the RegisterVisualMessage.options field.
             */
		case kVisualPluginIdleMessage:
			/* This is where it gets nasty. Idle messages can be sent at any time: while iTunes is playing
			 * (frequently), when paused (constantly), and even when the visualizer is off (a few times
			 * per second). Moreover, _all_ plug-ins receive idle messages even if another one is active.
			 * Because I used 0xFFFFFFFF for timeBetweenData, iTunes will use 100% cpu, both during playback
			 * and while paused. This is why I included the usleep calls. Mind that usleep will pause the
			 * _entire_ iTunes process, so a sensible value must be used (1msec doesn't seem to interfere
			 * with normal operation).
			 * I need to check if iTunes is paused to avoid messing up the timing of the rendering routine,
			 * and check if the plug-in is active to avoid rendering a non-existing port. */
			if( visualPluginData->playing == false && visualPluginData->destPort != nil ) {
				if( getuSec(gLineTimeStamp) > gDelay ) {
					startuSec(&gLineTimeStamp);
					RenderVisualPort(visualPluginData,visualPluginData->destPort,&visualPluginData->destRect,false);
				}
				else
					usleep(SG_USLEEP); // TODO: find Windows equivalent
			}
			break;
			
            /*
             Sent if the plugin requests the ability for the user to configure it.  Do this by setting
             the kVisualWantsConfigure option in the RegisterVisualMessage.options field.
             */
#if TARGET_OS_MAC					
		case kVisualPluginConfigureMessage:
		{
			static EventTypeSpec controlEvent={kEventClassControl,kEventControlHit};
			static const ControlID kColorSettingControlID ={'cbox',kColorSettingID};
			static const ControlID kInvertSettingControlID={'cbox',kInvertSettingID};
			static const ControlID kBandSettingControlID  ={'cbox',kBandSettingID};
			static const ControlID kScrollSettingControlID={'cbox',kScrollSettingID};
			static const ControlID kDirSettingControlID   ={'popm',kDirSettingID};
			static const ControlID kSpeedSettingControlID ={'popm',kSpeedSettingID};
			
			static WindowRef settingsDialog;
			static ControlRef color =NULL;
			static ControlRef invert=NULL;
			static ControlRef band  =NULL;
			static ControlRef scroll=NULL;
			static ControlRef dirm  =NULL;
			static ControlRef speedm=NULL;
			
			IBNibRef 		nibRef;
			//we have to find our bundle to load the nib inside of it
			CFBundleRef iTunesPlugin;
			
			iTunesPlugin=CFBundleGetBundleWithIdentifier(CFSTR("be.dr-lex.SpectroGraph"));
			if( iTunesPlugin == NULL ) {
				fprintf( stderr, "SpectroGraph error: could not find bundle\n" );
				SysBeep(2);
			}
			else {
				CreateNibReferenceWithCFBundle(iTunesPlugin,CFSTR("SettingsDialog"), &nibRef);
                
				if( nibRef != nil ) {
					CreateWindowFromNib(nibRef, CFSTR("PluginSettings"), &settingsDialog);
					DisposeNibReference(nibRef);
                    
					if(settingsDialog) {
						InstallWindowEventHandler(settingsDialog,NewEventHandlerUPP(settingsControlHandler),
						                          1,&controlEvent,0,NULL);
						GetControlByID(settingsDialog,&kColorSettingControlID, &color);
						GetControlByID(settingsDialog,&kInvertSettingControlID,&invert);
						GetControlByID(settingsDialog,&kBandSettingControlID,  &band);
						GetControlByID(settingsDialog,&kScrollSettingControlID,&scroll);
						GetControlByID(settingsDialog,&kDirSettingControlID,   &dirm);
						GetControlByID(settingsDialog,&kSpeedSettingControlID, &speedm);
						
						SetControlValue(color, gColorFlag);
						SetControlValue(invert,gInvertFlag);
						SetControlValue(band,  gBandFlag);
						SetControlValue(scroll,gScrollFlag);
						SetControlValue(dirm,  gDirection+1);
						SetControlValue(speedm,delayToSpeed(gDelay));
						ShowWindow(settingsDialog);
					}
				}
			}
		}
			break;
#endif // TARGET_OS_MAC
            
            /*
             * Apple says:
             Sent when iTunes is going to show the visual plugin in a port.  At
             this point, the plugin should allocate any large buffers it needs.
             * I say:
             This message is called when the plugin is 'activated', i.e. when
             the iTunes visualizer is enabled and this plugin is selected. This
             is where you need to do all initializations you didn't do before.
             */
		case kVisualPluginShowWindowMessage:
		{
			initOpenGL();
			
			visualPluginData->destOptions = messageInfo->u.showWindowMessage.options;
			
			status = ChangeVisualPort(	visualPluginData,
#if TARGET_OS_WIN32
                                      messageInfo->u.setWindowMessage.window,
#endif
#if TARGET_OS_MAC
                                      messageInfo->u.setWindowMessage.port,
#endif
                                      &messageInfo->u.showWindowMessage.drawRect);
			
			/* this HAS to be done after setting up the viewport. Otherwise it will do
			 * just nothing, it won't even produce any errors, your textures will just be white. */
			setupTextures();
			
#ifdef SG_DEBUG
			startuSec(&gFPSTimeStamp);
#endif
			if(status == noErr)
				RenderVisualPort(visualPluginData,visualPluginData->destPort,&visualPluginData->destRect,true);
#ifdef SG_DEBUG
			fprintf(stderr, "SpectroGraph started\n");
#endif
			break;
		}
            /*
             * Apple says:
             Sent when iTunes is no longer displayed.
             * I say:
             Sent when the _visualizer_ is no longer displayed.  In other words:
             when the user disables the visualizer, swtiches to another visualizer,
             closes the iTunes window, or minimizes iTunes to the Dock.
             */
		case kVisualPluginHideWindowMessage:
#ifdef SG_DEBUG
			fprintf(stderr, "Hiding SpectroGraph\n");
#endif
			(void) ChangeVisualPort(visualPluginData,nil,nil);
			
			aglSetCurrentContext(NULL);
			if( myContext != NULL ) {
				aglSetDrawable(myContext, NULL);
				aglDestroyContext(myContext);
				myContext = NULL;
			}
			
			MyMemClear(&visualPluginData->trackInfo,sizeof(visualPluginData->trackInfo));
			MyMemClear(&visualPluginData->streamInfo,sizeof(visualPluginData->streamInfo));
			break;
            
            /*
             Sent when iTunes needs to change the port or rectangle of the currently
             displayed visual.
             */
		case kVisualPluginSetWindowMessage:
			visualPluginData->destOptions = messageInfo->u.setWindowMessage.options;
            
			status = ChangeVisualPort(	visualPluginData,
#if TARGET_OS_WIN32
                                      messageInfo->u.showWindowMessage.window,
#endif
#if TARGET_OS_MAC
                                      messageInfo->u.showWindowMessage.port,
#endif
                                      &messageInfo->u.setWindowMessage.drawRect);
            
			if (status == noErr)
				RenderVisualPort(visualPluginData,visualPluginData->destPort,&visualPluginData->destRect,true);
			break;
            
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
        }
			break;
#if 0			
            /*
             Sent for the visual plugin to render directly into a port.  Not necessary for normal
             visual plugins.
             */
		case kVisualPluginRenderToPortMessage:
			status = unimpErr;
			break;
#endif //0
            /*
             Sent in response to an update event.  The visual plugin should update
             into its remembered port.  This will only be sent if the plugin has been
             previously given a ShowWindow message.
             */	
		case kVisualPluginUpdateMessage:
			RenderVisualPort(visualPluginData,visualPluginData->destPort,&visualPluginData->destRect,true);
			break;
            
            /*
             Sent when the player starts.
             */
		case kVisualPluginPlayMessage:
			if (messageInfo->u.playMessage.trackInfo != nil)
				visualPluginData->trackInfo = *messageInfo->u.playMessage.trackInfoUnicode;
			else
				MyMemClear(&visualPluginData->trackInfo,sizeof(visualPluginData->trackInfo));
            
			if (messageInfo->u.playMessage.streamInfo != nil)
				visualPluginData->streamInfo = *messageInfo->u.playMessage.streamInfoUnicode;
			else
				MyMemClear(&visualPluginData->streamInfo,sizeof(visualPluginData->streamInfo));
            
			visualPluginData->playing = true;
			break;
            
            /*
             Sent when the player changes the current track information.  This
             is used when the information about a track changes,or when the CD
             moves onto the next track.  The visual plugin should update any displayed
             information about the currently playing song.
             */
		case kVisualPluginChangeTrackMessage:
			if (messageInfo->u.changeTrackMessage.trackInfo != nil)
				visualPluginData->trackInfo = *messageInfo->u.changeTrackMessage.trackInfoUnicode;
			else
				MyMemClear(&visualPluginData->trackInfo,sizeof(visualPluginData->trackInfo));
            
			if (messageInfo->u.changeTrackMessage.streamInfo != nil)
				visualPluginData->streamInfo = *messageInfo->u.changeTrackMessage.streamInfoUnicode;
			else
				MyMemClear(&visualPluginData->streamInfo,sizeof(visualPluginData->streamInfo));
			break;
            
            /*
             Sent when the player stops.
             */
		case kVisualPluginStopMessage:
			visualPluginData->playing = false;
			
			ResetRenderData(visualPluginData);
            
			RenderVisualPort(visualPluginData,visualPluginData->destPort,&visualPluginData->destRect,true);
			break;
            
            /*
             Sent when the player changes position.
             */
		case kVisualPluginSetPositionMessage:
			break;
            
            /*
             Sent when the player pauses.  iTunes does not currently use pause or unpause.
             A pause in iTunes is handled by stopping and remembering the position.
             */
		case kVisualPluginPauseMessage:
			visualPluginData->playing = false;
            
			ResetRenderData(visualPluginData);
            
			RenderVisualPort(visualPluginData,visualPluginData->destPort,&visualPluginData->destRect,true);
			break;
			
            /*
             Sent when the player unpauses.  iTunes does not currently use pause or unpause.
             A pause in iTunes is handled by stopping and remembering the position.
             */
		case kVisualPluginUnpauseMessage:
			visualPluginData->playing = true;
			break;
            
            /*
             Sent to the plugin in response to a MacOS event.  The plugin should return noErr
             for any event it handles completely,or an error (unimpErr) if iTunes should handle it.
             */
#if TARGET_OS_MAC
            // TODO: what's the equivalent under Windows? Just disabling all controls is unacceptable!
		case kVisualPluginEventMessage:
        {
            EventRecord* tEventPtr = messageInfo->u.eventMessage.event;
            if ((tEventPtr->what == keyDown) || (tEventPtr->what == autoKey))
            {    // charCodeMask,keyCodeMask;
                char theChar = tEventPtr->message & charCodeMask;
                
                switch (theChar) {
                    case	'b':
                    case	'B':
                        gBandFlag = !gBandFlag;
                        status = noErr;
                        break;
                    case	'c':
                    case	'C':
                        gColorFlag = !gColorFlag;
                        status = noErr;
                        break;
                    case	'h':
                    case	'H':
                        if(++gDirection > 1)
                            gDirection = 0;
                        rewindDisplay();
                        status = noErr;
                        break;							
                    case	'i':
                    case	'I':
                        gInvertFlag = !gInvertFlag;
                        status = noErr;
                        break;
                    case	'l':
                    case	'L':
                        gScrollFlag = !gScrollFlag;
                        status = noErr;
                        break;							
                    case	'r':
                    case	'R':
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
#endif // TARGET_OS_MAC
            
		default:
			status = unimpErr;
			break;
	}
	return status;
}
#endif // SpectroGraph



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
}

#if 0 // SpectroGraph
/*
 RegisterVisualPlugin from SpectroGraph
 */
static OSStatus RegisterVisualPlugin(PluginMessageInfo *messageInfo)
{
	OSStatus			status;
	PlayerMessageInfo	playerMessageInfo;
	Str255				pluginName = kTVisualPluginName;
    
	MyMemClear(&playerMessageInfo.u.registerVisualPluginMessage,sizeof(playerMessageInfo.u.registerVisualPluginMessage));
	
	memcpy(&playerMessageInfo.u.registerVisualPluginMessage.name[0], &pluginName[0], pluginName[0] + 1);
    
#if TARGET_OS_MAC					
    CFStringRef tCFStringRef = CFStringCreateWithPascalString( kCFAllocatorDefault, pluginName, kCFStringEncodingUTF8 );
    if ( tCFStringRef ) 
    {
        CFIndex length = CFStringGetLength( tCFStringRef );
        if ( length > 255 ) 
        {
            length = 255;
        }
        playerMessageInfo.u.registerVisualPluginMessage.unicodeName[0] = CFStringGetBytes( tCFStringRef, CFRangeMake( 0, length ), kCFStringEncodingUnicode, 0, FALSE, (UInt8 *) &playerMessageInfo.u.registerVisualPluginMessage.unicodeName[1], 255, NULL );
        CFRelease( tCFStringRef );
    }
#endif //TARGET_OS_MAC					
    
	SetNumVersion(&playerMessageInfo.u.registerVisualPluginMessage.pluginVersion,kTVisualPluginMajorVersion,kTVisualPluginMinorVersion,kTVisualPluginReleaseStage,kTVisualPluginNonFinalRelease);
    
	playerMessageInfo.u.registerVisualPluginMessage.options					=	kVisualWantsIdleMessages 
#if TARGET_OS_MAC					
    | kVisualWantsConfigure | kVisualProvidesUnicodeName
#endif
    ;
	playerMessageInfo.u.registerVisualPluginMessage.handler					= (VisualPluginProcPtr)VisualPluginHandler;
	playerMessageInfo.u.registerVisualPluginMessage.registerRefCon			= 0;
	playerMessageInfo.u.registerVisualPluginMessage.creator					= kTVisualPluginCreator;
	
	/* This determines how often the plugin receives data. The name is deceiving because we can't
	 * get millisecond accuracy. Instead, ticks of 16msec are used, so it's impossible to go faster
	 * than 62.5 packets/second. For this plug-in that's still too slow, so I have to disable this
	 * by using 0xFFFFFFFF (= as fast as possible) and do my own speed control.
	 * If your own plug-in can do with 62.5 frames/second, by all means enable this, because otherwise
	 * you'll have to use similar ugly tricks as I to avoid 100% cpu usage. */	
	playerMessageInfo.u.registerVisualPluginMessage.timeBetweenDataInMS		= 0xFFFFFFFF;
	playerMessageInfo.u.registerVisualPluginMessage.numWaveformChannels		= 2;
	playerMessageInfo.u.registerVisualPluginMessage.numSpectrumChannels		= 2;
	
	playerMessageInfo.u.registerVisualPluginMessage.minWidth				= 64;
	playerMessageInfo.u.registerVisualPluginMessage.minHeight				= 64;
	playerMessageInfo.u.registerVisualPluginMessage.maxWidth				= 32767;
	playerMessageInfo.u.registerVisualPluginMessage.maxHeight				= 32767;
	playerMessageInfo.u.registerVisualPluginMessage.minFullScreenBitDepth	= 0;
	playerMessageInfo.u.registerVisualPluginMessage.maxFullScreenBitDepth	= 0;
	playerMessageInfo.u.registerVisualPluginMessage.windowAlignmentInBytes	= 0;
	
	status = PlayerRegisterVisualPlugin(messageInfo->u.initMessage.appCookie,messageInfo->u.initMessage.appProc,&playerMessageInfo);
	startuSec(&gLineTimeStamp);
	startuSec(&gFrameTimeStamp);
	gnLPU = SG_MAXCHUNK;
	
	return status;
	
}
#endif


