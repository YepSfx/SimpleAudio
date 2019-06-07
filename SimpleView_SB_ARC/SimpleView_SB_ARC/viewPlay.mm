//
//  viewPlay.m
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-20.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "viewPlay.h"
#import "GlobalMsg.h"
#import "filter.h"
#import "viewAudioWave.h"

#define DEF_TIMER_TIME          0.05
#define DEF_TIMER_DELAY         0.15
#define DEF_SCREEN_WIDTH        310 //240

#define DEF_NUM_UNCOMPFILE      1
#define DEF_COMP_AUDBYTE        2

@implementation viewPlay

char *OSTypeToStr(char *buf, OSType t)
{
	char *p = buf;
	char str[4], *q = str;
	*(UInt32 *)str = CFSwapInt32(t);
	for (int i = 0; i < 4; ++i) {
		if (isprint(*q) && *q != '\\')
			*p++ = *q++;
		else {
			sprintf(p, "\\x%02x", *q++);
			p += 4;
		}
	}
	*p = '\0';
	return buf;
}

- (void)setupAudio 
{
#if 0
    [[AVAudioSession sharedInstance] setDelegate: (__bridge id)player];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error:&activationError];
    
    CWJLog(@"setupAudio ACTIVATION ERROR IS %@", activationError);
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:0.5 error:&activationError];
    CWJLog(@"setupAudio BUFFER DURATION ERROR IS %@", activationError);
#endif    
}

- (BOOL)isHeadsetPluggedIn {
    UInt32 routeSize = sizeof (CFStringRef);
    CFStringRef route;
    
    OSStatus error = AudioSessionGetProperty (kAudioSessionProperty_AudioRoute,
                                              &routeSize,
                                              &route);
    
    /* Known values of route:
     * "Headset"
     * "Headphone"
     * "Speaker"
     * "SpeakerAndMicrophone"
     * "HeadphonesAndMicrophone"
     * "HeadsetInOut"
     * "ReceiverAndMicrophone"
     * "Lineout"
     */
    
    if (!error && (route != NULL)) {
        
        NSString* routeStr = (__bridge_transfer  NSString*)route;
        
        NSRange headphoneRange = [routeStr rangeOfString : @"Head"];
        
        
        if (headphoneRange.location != NSNotFound) return YES;
        
    }

    return NO;
}

-(IBAction)ToggleLeft:(id)sender;
{
    BOOL Ans[2];
    
    Ans[0] = switchLeft.on;
    Ans[1] = switchRight.on;
    
    [viewWaveForm SelectLChannel:Ans[0] SetRChannel:Ans[1]];
}

-(IBAction)ToggleRight:(id)sender
{
    BOOL Ans[2];

    Ans[0] = switchLeft.on;
    Ans[1] = switchRight.on;

    [viewWaveForm SelectLChannel:Ans[0] SetRChannel:Ans[1]];
}

-(void)ClearViewWave
{
    //[viewWaveForm setBackgroundColor:[UIColor blackColor]];    
    [viewWaveForm SetPlaying:FALSE];
    [viewWaveForm setNeedsDisplay];    
}

-(void)UpdateMonoView:(SAMPLE *)pBuffer
{
    //[viewWaveForm setBackgroundColor:[UIColor blackColor]];
    
    [viewWaveForm SetPlaying:TRUE];
    [viewWaveForm SetWindowPacket: nPacketsWindow];
    [viewWaveForm SetChannels:1];
    [viewWaveForm SetScaleInc:UpdateSampleWidthInScale];
    [viewWaveForm SetUpdateMovingWindow:UpdateSampleWidthInReal];
    [viewWaveForm SetBuffer:(BYTE*)pBuffer];    
    [viewWaveForm setNeedsDisplay];
}

-(void)UpdateStereoView:(RAWDATA *)pBuffer
{
    //[viewWaveForm setBackgroundColor:[UIColor blackColor]];
    [viewWaveForm SetPlaying:TRUE];
    [viewWaveForm SetWindowPacket: nPacketsWindow];
    [viewWaveForm SetChannels:2];
    [viewWaveForm SetScaleInc:UpdateSampleWidthInScale];
    [viewWaveForm SetUpdateMovingWindow:UpdateSampleWidthInReal];
    [viewWaveForm SetBuffer:(BYTE*)pBuffer];    
    [viewWaveForm setNeedsDisplay];
}

-(void)timerDelayStartProc:(NSTimer*)theTimer
{
#if 1
    if (!bIsDelayed)
    {
        bIsDelayed = TRUE;
        return;
    }
#endif

    [timerDelayStart invalidate];
    
    timerUpdateWav  = [NSTimer scheduledTimerWithTimeInterval:DEF_TIMER_TIME target:self selector:@selector(timerUpdateWavProc:) userInfo:nil repeats:YES];
}

-(void)timerUpdateWavProc:(NSTimer*)theTimer
{
    SAMPLE  *pSample,  *pSrcSample;
    RAWDATA *pRawData, *pSrcRaw;
    
#if 1
    static int MaxCount;

#if 0
    if (!bIsDelayed)
    {
        bIsDelayed = TRUE;
        return;
    }
#endif
    MaxCount++;
    
    if (MaxCount == 19)
    {
        if (![self isHeadsetPluggedIn])
        {
            player->SetSpeaker(1);
        }else
        {
            player->SetSpeaker(0);
        }
        CurrentPacket = player->GetCurrentPacketsNumber();
        
        progressBar.progress = (float)(CurrentPacket)/TotalAudioPackets;

        MaxCount = 0;
    }
#endif    
    if (UpdateWindowOrder < UpdateSpeed)
    {
        switch(nCh)
        {
            case 1:
                pSrcSample = (SAMPLE*)waveForm;
                pSample    = &pSrcSample[UpdateCurrentIndex];
                [self UpdateMonoView: pSample];
                break;
            case 2:
                pSrcRaw   = (RAWDATA*)waveForm;
                pRawData  = &pSrcRaw[UpdateCurrentIndex];
                [self UpdateStereoView: pRawData];
                break;
        }
    }
    UpdateCurrentIndex += UpdateSampleWidthInReal; 
    UpdateWindowOrder++;  
}

-(void)NotifyBufferDone:(NSNotification *)pNotification
{
    UInt32 nBytes;
    
    memset(waveForm, 0, sizeof(waveForm));
    player->PassAudioBuffer(waveForm, &nBytes);
    UpdateCurrentIndex = 0;
    UpdateWindowOrder  = 0;
}

-(void)NotifyGainChange:(NSNotification *)pNotification
{
    NSNumber *recvNum;
    SInt16   vol;
    
    recvNum = (NSNumber*)[pNotification object];
    gain = [recvNum intValue];

    vol  = MakeMasterGain(gain);
    player->SetMasterGain(vol);
}

-(void)NotifySelectFile:(NSNotification *)pNotification
{
    NSString *filename, *Msg;
    
    filename = (NSString*)[pNotification object];

    Msg = [NSString stringWithFormat:@">> File %@ Selected!",filename];
    CWJLog(Msg);
    
    audioFileName   = filename;    
    bIsThisLibrary  = FALSE;
}

-(void)NotifySelectSong:(NSNotification *)pNotification
{
    MPMediaItem *SongObj;
    NSString    *Msg;
    
    SongObj = (MPMediaItem*)[pNotification object];
    
    Msg     = [NSString stringWithFormat:@">> Song %@ Selected!",[SongObj valueForProperty:MPMediaItemPropertyTitle]];
    CWJLog(Msg);
    
    audioSong       = SongObj;   
    bIsThisLibrary  = TRUE;
}

-(void)NotifySetVCON:(NSNotification*)pNotification
{
    player->SetSwitchVC(1);
    [viewWaveForm SetVCON:TRUE];
}

-(void)NotifySetVCOFF:(NSNotification*)pNotification
{
    
    player->SetSwitchVC(0);
    [viewWaveForm SetVCON:FALSE];
}

-(void)NotifySetLPFON:(NSNotification*)pNotification
{
    player->SetFilterType(1);
}

-(void)NotifySetLPFOFF:(NSNotification*)pNotification
{
    player->SetFilterType(0);
}

-(void)NotifySetHPFON:(NSNotification*)pNotification
{
    player->SetFilterType(2);
}

-(void)NotifySetHPFOFF:(NSNotification*)pNotification
{
    player->SetFilterType(0);
}

-(void)setFileDescriptionForFormat: (CAStreamBasicDescription)format withName:(NSString*)name
{
	char    buf[5];
	const   char *dataFormat = OSTypeToStr(buf, format.mFormatID);    
    NSString* Msg;
	NSString* description = [[NSString alloc] initWithFormat:@"(%d ch. %s @ %g Hz)", format.NumberChannels(), dataFormat, format.mSampleRate, nil];
	fileDescription = description;

    SampleRate = format.mSampleRate;
    nCh        = format.NumberChannels();
    nBytePerCh = format.SampleWordSize();
    nPacketsWindow = player->GetWindowPackets();
        
    float ratio1 = (float)nPacketsWindow/SampleRate;
    float ratio2 = ratio1/DEF_TIMER_TIME;
        
    int freq = (int)ratio2;
        
    UpdateSpeed = freq;
  
    UpdateSampleWidthInReal = nPacketsWindow / UpdateSpeed;
    UpdateSampleWidthInScale = UpdateSampleWidthInReal / DEF_SCREEN_WIDTH;
    
    Msg = [NSString stringWithFormat:@"UpdateSample : %d %d", UpdateSampleWidthInReal, UpdateSampleWidthInScale];
    CWJLog(Msg);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
#pragma mark Playback routines

-(void)stopPlayQueue
{
	player->StopQueue();    
}

-(void)pausePlayQueue
{
	player->PauseQueue();
	playbackWasPaused = YES;
}

#pragma mark AudioSession listeners
void interruptionListener(	void *	inClientData,
                          UInt32	inInterruptionState)
{
	viewPlay *THIS = (__bridge viewPlay*)inClientData;
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
		if (THIS->player->IsRunning()) {
			//the queue will stop itself on an interruption, we just need to update the UI			
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
            
			THIS->playbackWasInterrupted = YES;
            
		}
	}
	else if ((inInterruptionState == kAudioSessionEndInterruption) && THIS->playbackWasInterrupted)
	{
		// we were playing back when we were interrupted, so reset and resume now
		THIS->player->StartQueue(true);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:THIS];
		THIS->playbackWasInterrupted = NO;
	}
}

void propListener(	void *                  inClientData,
                  AudioSessionPropertyID	inID,
                  UInt32                  inDataSize,
                  const void *            inData)
{
	viewPlay *THIS = (__bridge viewPlay*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		CFDictionaryRef routeDictionary = (CFDictionaryRef)inData;			
		//CFShow(routeDictionary);
		CFNumberRef reason = (CFNumberRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		SInt32 reasonVal;
		CFNumberGetValue(reason, kCFNumberSInt32Type, &reasonVal);
		if (reasonVal != kAudioSessionRouteChangeReason_CategoryChange)
		{
			if (reasonVal == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
			{			
				if (THIS->player->IsRunning()) {                    
                    if (![THIS isHeadsetPluggedIn])
                    {
                        THIS->player->SetSpeaker(1);
                    }else
                    {
                        THIS->player->SetSpeaker(0);
                    }                    
					[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
				}		
			}            
		}	
	}
}

#pragma mark - View lifecycle

- (void)awakeFromNib
{
    player = new AQPlayer();

    
	OSStatus error = AudioSessionInitialize(NULL, NULL, interruptionListener, (__bridge void*)self);
	if (error) printf("ERROR INITIALIZING AUDIO SESSION! %ld\n", error);
	else 
	{
		UInt32 category = kAudioSessionCategory_PlayAndRecord;	
		error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
		if (error) printf("couldn't set audio category!");
        
		error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, (__bridge void*)self);
		if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %ld\n", error);
		UInt32 inputAvailable = 0;
		UInt32 size = sizeof(inputAvailable);
		
		// we do not want to allow recording if input is not available
		error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
		if (error) printf("ERROR GETTING INPUT AVAILABILITY! %ld\n", error);

		
		// we also need to listen to see if input availability changes
		error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, (__bridge void*)self);
		if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %ld\n", error);
        
		error = AudioSessionSetActive(true); 
		if (error) printf("AudioSessionSetActive (true) failed");
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueStopped:) name:@"playbackQueueStopped" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueResumed:) name:@"playbackQueueResumed" object:nil];
    
	
	// disable the play button since we have no recording to play yet
	playbackWasInterrupted = NO;
	playbackWasPaused = NO;
    
#if 0
    NSString *DataPath = [[NSBundle mainBundle] pathForResource:@"Sample_22k_mono" ofType:@"wav"]; 
    audioFileName = DataPath;
    CWJLog(audioFileName);

    player->DisposeQueue(true);
    
    player->CreateQueueForFile((__bridge CFStringRef)audioFileName);    
#endif
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifySelectFile:) 
     name:DEF_SEL_FILENAME object:nil];
    
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifySelectSong:) 
     name:DEF_SET_LIBSONG object:nil];

    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifySetLPFON:) 
     name:DEF_SET_LPF_ON object:nil];

    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifySetLPFOFF:) 
     name:DEF_SET_LPF_OFF object:nil];    
    
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifySetHPFON:) 
     name:DEF_SET_HPF_ON object:nil];
    
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifySetHPFOFF:) 
     name:DEF_SET_HPF_OFF object:nil];    

    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifyGainChange:) 
     name:DEF_SET_MASTERGAIN object:nil];   

    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifySetVCON:) 
     name:DEF_SET_VC_ON object:nil];    
    
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifySetVCOFF:) 
     name:DEF_SET_VC_OFF object:nil];    
    
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(NotifyBufferDone:) 
     name:DEF_SET_BUFFER_DONE object:nil];        
    
    [viewWaveForm SetPlaying:FALSE];
    bIsThisLibrary  = FALSE;
    audioSong       = nil;
    audioFileName   = nil;
    bIsThisLibrary  = FALSE;
    
    [self setupAudio];
}

# pragma mark Notification routines
- (void)playbackQueueStopped:(NSNotification *)note
{
    CWJLog(@"Que Stop!");
    [btn_PlayStop setTitle:@"Play" forState:UIControlStateNormal]; 
    [timerUpdateWav invalidate];
    bIsDelayed = FALSE;
    
    descriptionLabel.text = @"";  
    
    progressBar.progress = 0.0;
    [self ClearViewWave];
    
    player->StopAssetReading();
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:FALSE];
}

- (void)playbackQueueResumed:(NSNotification *)note
{
    CWJLog(@"Que Resume!");
    
    [btn_PlayStop setTitle:@"Stop" forState:UIControlStateNormal];
    
    bIsDelayed = FALSE;
#if 1
    timerDelayStart = [NSTimer scheduledTimerWithTimeInterval:DEF_TIMER_DELAY target:self selector:@selector(timerDelayStartProc:) userInfo:nil repeats:YES];
#else
    timerUpdateWav  = [NSTimer scheduledTimerWithTimeInterval:DEF_TIMER_TIME target:self selector:@selector(timerUpdateWavProc:) userInfo:nil repeats:YES];
#endif
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
}

#pragma mark Cleanup
- (void)dealloc
{	
	delete player;
}

- (void) ShowMediaPicker
{
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAny];
    
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = NO;
    mediaPicker.prompt = @"Select songs to play";
    
    [self presentModalViewController:mediaPicker animated:YES];
}

- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection
{
    UInt32 i,count = 0;
    MPMediaItem *song;
    
    if (mediaItemCollection)
    {
        count = mediaItemCollection.count;
        
        for(i = 0 ; i < count ; i++)
        {
            song = [mediaItemCollection.items objectAtIndex: i] ;
        }
        
    }
    [self dismissModalViewControllerAnimated: YES];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DEF_SET_LIBSONG object:song ];
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [self dismissModalViewControllerAnimated: YES];
}

- (IBAction)selectSong:(id) sender
{
    CWJLog(@"selectSong pressed!");
    bIsThisLibrary = TRUE;
    [self ShowMediaPicker];
}

- (IBAction)play:(id)sender
{
    switch(bIsThisLibrary)
    {
        case FALSE:
            if (audioFileName == nil) 
            {
                UIAlertView *alet = [[UIAlertView alloc] initWithTitle:@"File Error" message:@"File is not selected!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alet show];
                return;
            }
#if 1
            if (player->IsRunning())
            {
                if (playbackWasPaused) 
                {
                    OSStatus result = player->StartQueue(true);
                    if (result == noErr)
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
                }
                else
                    [self stopPlayQueue];
            }
            else
            {		
                UInt64 maxPacket;
                
                progressBar.progress = 0.0;
                player->DisposeQueue(true);        
                player->CreateQueueForFile((__bridge CFStringRef)audioFileName);    
                
                maxPacket = player->GetNumOfPackets();
                TotalAudioPackets = maxPacket;
                
                [self setFileDescriptionForFormat:player->DataFormat() withName:@"Playing File"];
                descriptionLabel.text = fileDescription;
                
                OSStatus result = player->StartQueue(false);
                
                [viewWaveForm SelectLChannel:TRUE SetRChannel:FALSE];
                if (result == noErr)
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
            }
#endif    
            break;
        case TRUE:
            if (audioSong == nil) 
            {
                UIAlertView *alet = [[UIAlertView alloc] initWithTitle:@"Song Error" message:@"Song is not selected!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alet show];
                return;
            }
#if 1
            if (player->IsRunning())
            {
                if (playbackWasPaused) 
                {
                    OSStatus result = player->StartQueue(true);
                    if (result == noErr)
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
                }
                else
                    [self stopPlayQueue];
            }
            else
            {		
                UInt64 maxPacket;
                
                progressBar.progress = 0.0;
                player->DisposeQueue(true);        
                player->CreateQueusForSong(audioSong);    
               
                maxPacket = player->GetNumOfPackets();
                TotalAudioPackets = maxPacket;
                
                [self setFileDescriptionForFormat:player->DataFormat() withName:@"Playing File"];
                descriptionLabel.text = fileDescription;
                
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: nil];

#if 1
                OSStatus result = player->StartQueue(false);
                
                [viewWaveForm SelectLChannel:TRUE SetRChannel:FALSE];
                if (result == noErr)
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
#endif                
            }
#endif    
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    progressBar.progress = 0.0;    
    switchLeft.on = TRUE;
    switchRight.on = FALSE;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (player->IsRunning())
        [btn_PlayStop setTitle:@"Stop" forState:UIControlStateNormal];
    else
        [btn_PlayStop setTitle:@"Play" forState:UIControlStateNormal];        
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
