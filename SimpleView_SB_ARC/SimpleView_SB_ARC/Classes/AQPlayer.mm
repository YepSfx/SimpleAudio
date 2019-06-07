/*
 
    File: AQPlayer.mm
Abstract: n/a
 Version: 2.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2009 Apple Inc. All Rights Reserved.

 
*/

#include "AQPlayer.h"
#include "GlobalMsg.h"


#define DEF_ASSET_NCH           2
#define DEF_ASSET_SAMPRATE      44100.0    
#define DEF_LIB_READOFFSET      32768
#define DEF_QUE_MAXBUFFER       0x10000     //65536

static BYTE InterimAudBuffer[(DEF_QUE_MAXBUFFER<<1)] = {0,};
static BYTE GarbageAudBuffer[DEF_QUE_MAXBUFFER]      = {0,};
static unsigned int LenGarbage                       = 0;

void AQPlayer::PassAudioBuffer(BYTE *pBuffer, UInt32 *nBytes)
{
    memcpy(pBuffer, mThisAudiobuffer, mNReadBytes);
    *nBytes = mNReadBytes;
}

void AQPlayer::AQBufferCallback(void *					inUserData,
								AudioQueueRef			inAQ,
								AudioQueueBufferRef		inCompleteAQBuffer) 
{
    UInt32              numBytes = 0,readlib = 0;
    int                 nCh = 0, nBytesPerSamp = 0;
    BYTE                *pBuffer, *pWrkBuffer;
    CMSampleBufferRef   nextBuffer;
    CMBlockBufferRef    ByteBuffer;
    char                *pPointer;
    size_t              lengthAtOffset = 0;
    size_t              totalLength = 0;    
    OSStatus            result;
    AVAssetReaderStatus stat;
    
    AQPlayer    *THIS = (AQPlayer *)inUserData;
    
    nCh = THIS->mOutFormat.NumberChannels();
    
    nBytesPerSamp = THIS->mOutFormat.SampleWordSize();
    
	if (THIS->mIsDone) 
        return;

	UInt32 nPackets = THIS->GetNumPacketsToRead();
    AudioBufferList bufList;
    bufList.mNumberBuffers = 1;
    bufList.mBuffers[0].mNumberChannels = nCh;
    bufList.mBuffers[0].mData = inCompleteAQBuffer->mAudioData;
    bufList.mBuffers[0].mDataByteSize = DEF_QUE_MAXBUFFER;
    
    // perform a synchronous sequential read of the audio data out of the file into our allocated data buffer

    switch(THIS->mIsLibrary)
    {
        case FALSE:    
            result = ExtAudioFileRead(THIS->mAudRef, &nPackets, &bufList);
            numBytes = nPackets * nCh * nBytesPerSamp;
            break;
        case TRUE:            
            stat = [THIS->mAssetReader status];
            if (stat == AVAssetReaderStatusReading)
            {
                pWrkBuffer = InterimAudBuffer;
                memcpy(pWrkBuffer, GarbageAudBuffer, LenGarbage );
                pWrkBuffer  += LenGarbage;
                numBytes     = LenGarbage;
                LenGarbage   = 0;
                do{
                    nextBuffer  = [THIS->mAssetReaderOutput copyNextSampleBuffer];
                    if (nextBuffer == NULL)
                    {
                        break;
                    }
                    readlib     = CMSampleBufferGetTotalSampleSize(nextBuffer);
                    ByteBuffer  = CMSampleBufferGetDataBuffer(nextBuffer);
                    result      = CMBlockBufferGetDataPointer(ByteBuffer, 0, &lengthAtOffset, &totalLength, &pPointer);
                    
                    memcpy(  pWrkBuffer , pPointer, readlib );
                    
                    pWrkBuffer += readlib;
                    numBytes   += readlib;
                    
                    CFRelease(nextBuffer);

                    if (numBytes >= DEF_QUE_MAXBUFFER)
                        break;
                   

                }while ((numBytes < DEF_QUE_MAXBUFFER)||(readlib!=0));
                
                if (numBytes >= DEF_QUE_MAXBUFFER)
                {
                    memcpy( (unsigned char*)inCompleteAQBuffer->mAudioData, InterimAudBuffer, DEF_QUE_MAXBUFFER );
                
                    pWrkBuffer = InterimAudBuffer;
                    pWrkBuffer += DEF_QUE_MAXBUFFER;
                    LenGarbage = numBytes - DEF_QUE_MAXBUFFER;
                    if (LenGarbage >= 0)
                    {
                        memcpy( GarbageAudBuffer, pWrkBuffer, LenGarbage);
                        numBytes = DEF_QUE_MAXBUFFER;
                    }
                }else{
                    memcpy( (unsigned char*)inCompleteAQBuffer->mAudioData, InterimAudBuffer, DEF_QUE_MAXBUFFER );
                   
                }
            }
            
            nPackets    = numBytes / (nCh * nBytesPerSamp);
                
            break;
    }
#if 0
	NSString *debugStr;    
    debugStr = [NSString stringWithFormat:@"Data nByte: %d, nPackets: %d",numBytes, nPackets];
    CWJLog(debugStr);
#endif    
    
	if (result)
    {
		printf("AudioFileReadPackets failed: %ld\n", result);
    }
    
    if (nPackets > 0) {
		        
        THIS->mIsBusy = TRUE;
        
        pBuffer = (BYTE*)inCompleteAQBuffer->mAudioData;
                
        ProcVocalRemove(pBuffer, nCh, numBytes, nBytesPerSamp,THIS->mVC, THIS->mSpeaker, THIS->mIsLibraryMono);
        ProcFilter(pBuffer, nCh, numBytes, nBytesPerSamp,THIS->mFilterType);
        ProcMasterGain(pBuffer, nCh, numBytes, nBytesPerSamp,THIS->mGain);
        
        inCompleteAQBuffer->mAudioDataByteSize = numBytes;		
		inCompleteAQBuffer->mPacketDescriptionCount = nPackets;		
		AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL);
		THIS->mCurrentPacket = (THIS->GetCurrentPacket() + nPackets);
                
        THIS->mIsBusy = FALSE;
        
        THIS->mNReadBytes  = numBytes;
        THIS->mNReadPackets = nPackets;
        THIS->mThisAudiobuffer = (BYTE*)inCompleteAQBuffer->mAudioData;
        [[NSNotificationCenter defaultCenter] postNotificationName: DEF_SET_BUFFER_DONE object: nil];
        
	} 
	else 
	{
		if (THIS->IsLooping())
		{
			THIS->mCurrentPacket = 0;
			AQBufferCallback(inUserData, inAQ, inCompleteAQBuffer);
		}
		else
		{
			// stop
			THIS->mIsDone = true;
			AudioQueueStop(inAQ, false);
		}
	}
}

void AQPlayer::isRunningProc (  void *              inUserData,
								AudioQueueRef           inAQ,
								AudioQueuePropertyID    inID)
{
	AQPlayer *THIS = (AQPlayer *)inUserData;
	UInt32 size = sizeof(THIS->mIsRunning);
	OSStatus result = AudioQueueGetProperty (inAQ, kAudioQueueProperty_IsRunning, &THIS->mIsRunning, &size);
	
	if ((result == noErr) && (!THIS->mIsRunning))
		[[NSNotificationCenter defaultCenter] postNotificationName: @"playbackQueueStopped" object: nil];
}

void AQPlayer::CalculateBytesForTime (CAStreamBasicDescription & inDesc, UInt32 inMaxPacketSize, Float64 inSeconds, UInt32 *outBufferSize, UInt32 *outNumPackets)
{
	// we only use time here as a guideline
	// we're really trying to get somewhere between 16K and 64K buffers, but not allocate too much if we don't need it
	static const int maxBufferSize = 0x10000; // limit size to 64K
	static const int minBufferSize = 0x4000; // limit size to 16K
	
	if (inDesc.mFramesPerPacket) {
		if (!mIsLibrary)
        {
            Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
            *outBufferSize = numPacketsForTime * inMaxPacketSize;
        }
        else 
        {
            *outBufferSize = maxBufferSize;
        }
	} else {
		// if frames per packet is zero, then the codec has no predictable packet == time
		// so we can't tailor this (we don't know how many Packets represent a time period
		// we'll just return a default buffer size
		*outBufferSize = maxBufferSize > inMaxPacketSize ? maxBufferSize : inMaxPacketSize;
	}
	
	// we're going to limit our size to our default
	if (*outBufferSize > maxBufferSize && *outBufferSize > inMaxPacketSize)
		*outBufferSize = maxBufferSize;
	else {
		// also make sure we're not too small - we don't want to go the disk for too small chunks
		if (*outBufferSize < minBufferSize)
			*outBufferSize = minBufferSize;
	}
	*outNumPackets = *outBufferSize / inMaxPacketSize;
}

AQPlayer::AQPlayer() :
	mQueue(0),
	mAudioFile(0),
	mFilePath(NULL),
	mIsRunning(false),
	mIsInitialized(false),
	mNumPacketsToRead(0),
    mNumPacketsToFileRead(0),
	mCurrentPacket(0),
	mIsDone(false),
	mIsLooping(false) 
{ 
    mFilterType     = 0;
    mGain           = 0x4000;
    mVC             = 0;
    mSpeaker        = 0;
    mAudRef         = 0;
    mSong           = 0;
    mIsLibrary      = FALSE;
    mIsLibraryMono  = FALSE;
}

AQPlayer::~AQPlayer() 
{       
    DisposeQueue(true);
}

OSStatus AQPlayer::StartQueue(BOOL inResume)
{	
    InitFilter();
    // if we have a file but no queue, create one now
    switch(mIsLibrary)
    {
        case FALSE:
            if ((mQueue == NULL) && (mFilePath != NULL))
                CreateQueueForFile(mFilePath);
            break;
        case TRUE:
            if ((mQueue == NULL) && (mSong != NULL))
                CreateQueusForSong(mSong);
            break;
    }
	
	mIsDone = false;
	
	// if we are not resuming, we also should restart the file read index
	if (!inResume)
		mCurrentPacket = 0;	

	// prime the queue with some data before starting
	for (int i = 0; i < kNumberBuffers; ++i) {
		AQBufferCallback (this, mQueue, mBuffers[i]);			
	}
	return AudioQueueStart(mQueue, NULL);
}

OSStatus AQPlayer::StopQueue()
{
    [mAssetReader cancelReading];
 
    OSStatus result = AudioQueueStop(mQueue, true);
	if (result) printf("ERROR STOPPING QUEUE!\n");
    
    DisposeQueue(true);
    return result;
}

OSStatus AQPlayer::PauseQueue()
{
	OSStatus result = AudioQueuePause(mQueue);

	return result;
}

void AQPlayer::CreateQueusForSong(MPMediaItem* Song)
{
    mIsLibrary      = TRUE;
    mSong           = Song;   
    mIsLibraryMono  = FALSE;
    try 
    {					
        UInt32 SampRate, nChannels;
        mIsLooping = false;
        mAudioFile = 0;

        NSString        *msg;
        NSURL           *assetURL = [mSong valueForProperty:MPMediaItemPropertyAssetURL];
        AVURLAsset      *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];                    
        AVAssetTrack    *songTrack = [songAsset.tracks objectAtIndex:0];        
        NSArray         *formatDesc = songTrack.formatDescriptions;
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:0];
        const AudioStreamBasicDescription   *fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);            
        
        SampRate  = fmtDesc->mSampleRate;
        nChannels = fmtDesc->mChannelsPerFrame;

        msg = [NSString stringWithFormat:@">> SampleRate:%d , nChs: %d\n",(int)SampRate,(int)nChannels];
        CWJLog(msg);
        
        if (nChannels == 1)
        {
            mIsLibraryMono = TRUE; 
        }
        
        mDataFormat.SetCanonical(nChannels, true);
        mDataFormat.mSampleRate = SampRate;
        mOutFormat.SetCanonical(mDataFormat.mChannelsPerFrame, true);
        mOutFormat.mSampleRate = mDataFormat.mSampleRate;
    
		SetupNewQueue();		
    }
	catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
}

void AQPlayer::CreateQueueForFile(CFStringRef inFilePath) 
{	
	CFURLRef sndFile = NULL; 
    CAStreamBasicDescription debugFormat;
    
    mIsLibrary = FALSE;
	mIsLibraryMono = FALSE;
    
    try {					
		if (mFilePath == NULL)
		{
			mIsLooping = false;
			
			sndFile = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, inFilePath, kCFURLPOSIXPathStyle, false);
			if (!sndFile) { printf("can't parse file path\n"); return; }
			
			XThrowIfError(AudioFileOpenURL (sndFile, kAudioFileReadPermission, 0/*inFileTypeHint*/, &mAudioFile), "can't open file");
		
			UInt32 size = sizeof(mDataFormat);
			XThrowIfError(AudioFileGetProperty(mAudioFile, 
										   kAudioFilePropertyDataFormat, &size, &mDataFormat), "couldn't get file's data format");
            
            mOutFormat.SetCanonical(mDataFormat.mChannelsPerFrame, true);
            mOutFormat.mSampleRate = mDataFormat.mSampleRate;
         
			mFilePath = CFStringCreateCopy(kCFAllocatorDefault, inFilePath);
		}
		SetupNewQueue();		
	}
	catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
	if (sndFile)
		CFRelease(sndFile);
}

void AQPlayer::SetupNewQueue() 
{
	XThrowIfError(AudioQueueNewOutput(&mOutFormat, AQPlayer::AQBufferCallback, this, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &mQueue), "AudioQueueNew failed");
    UInt32 bufferByteSize;	
	NSString *Msg;
	// we need to calculate how many packets we read at a time, and how big a buffer we need
	// we base this on the size of the packets in the file and an approximate duration for each buffer
	// first check to see what the max size of a packet is - if it is bigger
	// than our allocation default size, that needs to become larger

	UInt32 maxPacketSize = mOutFormat.mBytesPerFrame;
	    
	CalculateBytesForTime (mOutFormat, maxPacketSize, kBufferDurationSeconds, &bufferByteSize, &mNumPacketsToRead);
    
    Msg = [NSString stringWithFormat:@"Buffer Byte Size: %d, Num Packets to Read: %d\n", (int)bufferByteSize, (int)mNumPacketsToRead];
    CWJLog(Msg);
    
	XThrowIfError(AudioQueueAddPropertyListener(mQueue, kAudioQueueProperty_IsRunning, isRunningProc, this), "adding property listener");
	
	bool isFormatVBR = (mDataFormat.mBytesPerPacket == 0 || mDataFormat.mFramesPerPacket == 0);
	for (int i = 0; i < kNumberBuffers; ++i) {
		XThrowIfError(AudioQueueAllocateBufferWithPacketDescriptions(mQueue, bufferByteSize, (isFormatVBR ? mNumPacketsToRead : 0), &mBuffers[i]), "AudioQueueAllocateBuffer failed");
	}	
    
	// set the volume of the queue
	XThrowIfError (AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0), "set queue volume");
	
	if (!mIsLibrary)
    {
        CFURLRef sndFile = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)mFilePath, kCFURLPOSIXPathStyle, false);
    
        XThrowIfError(ExtAudioFileOpenURL(sndFile, &mAudRef), "Open File");
        XThrowIfError(ExtAudioFileSetProperty(mAudRef, kExtAudioFileProperty_ClientDataFormat, sizeof(mOutFormat), &mOutFormat),"Set Output Format");

        UInt32 propSize = sizeof(mnumPackets);
        XThrowIfError(ExtAudioFileGetProperty(mAudRef, kExtAudioFileProperty_FileLengthFrames, &propSize, &mnumPackets),"Get Total Frames");
    
        CFRelease(sndFile);
    }
    else
    {
        NSURL *assetURL = [mSong valueForProperty:MPMediaItemPropertyAssetURL];
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    	NSError *assetError = nil;
        
        mAssetReader = [[AVAssetReader alloc] initWithAsset:songAsset error:&assetError];
        
        if (assetError) {
            NSString* Msg = [NSString stringWithFormat:@"error: %@", assetError];
            CWJLog(Msg);
            return;
        }

        NSNumber *Duration = [mSong valueForProperty:MPMediaItemPropertyPlaybackDuration];
        float TotalSamples = [Duration floatValue]*mOutFormat.mSampleRate; 
        float TotalPackets = TotalSamples;
        mnumPackets        = (UInt64)TotalPackets;

        AudioChannelLayout channelLayout;
        memset(&channelLayout, 0, sizeof(AudioChannelLayout));
        
        switch(mOutFormat.mChannelsPerFrame)
        {
            case 1:
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;  
            break;
            case 2:
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;  
            break;            
        }
        
        NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, 
                                        [NSNumber numberWithFloat:mOutFormat.mSampleRate], AVSampleRateKey,
                                        [NSNumber numberWithInt:mOutFormat.mChannelsPerFrame], AVNumberOfChannelsKey,
                                        [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                        [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                        nil];

        mAssetReaderOutput = [[AVAssetReaderAudioMixOutput alloc]initWithAudioTracks:songAsset.tracks audioSettings : outputSettings];
        
        if (! [mAssetReader canAddOutput: mAssetReaderOutput] ) 
        {
            CWJLog(@"can't add reader output... die!");
            return;
        }

        [mAssetReader addOutput: mAssetReaderOutput];
        [mAssetReader startReading];               
        
    }
    
    LenGarbage = 0;
    memset(GarbageAudBuffer, 0, sizeof(GarbageAudBuffer));
    memset(InterimAudBuffer, 0, sizeof(InterimAudBuffer));
    
    mIsInitialized = true;
}

void AQPlayer::DisposeQueue(Boolean inDisposeFile)
{
	if (mQueue)
	{
		AudioQueueDispose(mQueue, true);
		mQueue = NULL;
	}
	if (inDisposeFile)
	{
		if (mAudioFile)
		{		
			AudioFileClose(mAudioFile);
			mAudioFile = 0;
		}
		if (mFilePath)
		{
			CFRelease(mFilePath);
			mFilePath = NULL;
		}
        if (mAudRef)
        {
            ExtAudioFileDispose(mAudRef);
            mAudRef = NULL;
        }
        if (mSong)
        {
            //mSong = NULL;
        }
	}
	mIsInitialized = false;
    
    CWJLog(@"Que Disposed!\n");
}

void AQPlayer::StopAssetReading()
{
    [mAssetReader cancelReading];
    OSStatus result = AudioQueueStop(mQueue, true);
    if (result) printf("ERROR STOPPING QUEUE!\n");    
    DisposeQueue(true);
}


