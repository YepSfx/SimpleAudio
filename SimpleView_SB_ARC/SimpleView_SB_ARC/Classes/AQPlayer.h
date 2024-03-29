/*
 
    File: AQPlayer.h
Abstract: Helper class for playing audio files via the AudioQueue
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

#include <CoreFoundation/CoreFoundation.h>
#include <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>
#include <MediaPlayer/MediaPlayer.h>

#include "CAStreamBasicDescription.h"
#include "CAXException.h"

#include "filter.h"


#define kNumberBuffers 3
#define MAXBUFS  2

typedef struct {
    AudioStreamBasicDescription asbd;
    AudioSampleType *data;
	UInt32 numFrames;
} SoundBuffer, *SoundBufferPtr;

typedef struct {
	UInt32 frameNum;
    UInt32 maxNumFrames;
    SoundBuffer soundBuffer[MAXBUFS];
} SourceAudioBufferData, *SourceAudioBufferDataPtr;

class AQPlayer
	{
	public:
		AQPlayer();
		~AQPlayer();

		OSStatus						StartQueue(BOOL inResume);
		OSStatus						StopQueue();		
		OSStatus						PauseQueue();
		
		AudioQueueRef					Queue()					{ return mQueue; }
		CAStreamBasicDescription		DataFormat() const		{ return mDataFormat; }		
		Boolean							IsRunning()	const		{ return (mIsRunning) ? true : false; }
		Boolean							IsInitialized()	const	{ return mIsInitialized; }		
		CFStringRef						GetFilePath() const		{ return (mFilePath) ? mFilePath : CFSTR(""); }
		Boolean							IsLooping() const		{ return mIsLooping; }
		MPMediaItem                     *GetSong()              { return mSong; }; 
		void SetLooping(Boolean inIsLooping)	{ mIsLooping = inIsLooping; }
		void CreateQueueForFile(CFStringRef inFilePath);
		void CreateQueusForSong(MPMediaItem* Song); 
        void DisposeQueue(Boolean inDisposeFile);	
        void SetMasterGain(SInt16 gain) { mGain = gain; };       
		void SetFilterType(int filter) { mFilterType = filter; };
        void SetSwitchVC(int sw) { mVC = sw; };
        void SetSpeaker(BOOL sw) { mSpeaker = sw;};
        UInt64  GetNumOfPackets()  { return mnumPackets; }
        SInt64  GetCurrentPacketsNumber() {return mCurrentPacket;};
        void    PassAudioBuffer(BYTE *pBuffer, UInt32 *nBytes);
        UInt32  GetWindowPackets() {return mNumPacketsToRead; };
        void    StopAssetReading();
	private:
		UInt32							GetNumPacketsToFileRead()				{ return mNumPacketsToFileRead; }
		UInt32							GetNumPacketsToRead()				{ return mNumPacketsToRead; }
		SInt64							GetCurrentPacket()					{ return mCurrentPacket; }
		AudioFileID						GetAudioFileID()					{ return mAudioFile; }
		void							SetCurrentPacket(SInt64 inPacket)	{ mCurrentPacket = inPacket; }
		
		void							SetupNewQueue();
		
        AudioQueueRef					mQueue;
		AudioQueueBufferRef				mBuffers[kNumberBuffers];
		AudioFileID						mAudioFile;
		CFStringRef						mFilePath;
		CAStreamBasicDescription		mDataFormat;
        CAStreamBasicDescription        mOutFormat;
		Boolean							mIsInitialized;
		UInt32							mNumPacketsToRead;
        UInt32                          mNumPacketsToFileRead;
		SInt64							mCurrentPacket;
		UInt32							mIsRunning;
		Boolean							mIsDone;
		Boolean							mIsLooping;        
        UInt32                          mNReadPackets;
        UInt32                          mNReadBytes;
        BOOL                            mIsBusy;
        BOOL                            mIsLibrary;
        BOOL                            mIsLibraryMono;
        SInt16                          mGain;
        int                             mVC;
        int                             mFilterType;
        int                             mSpeaker;
        UInt64                          mnumPackets;
        BYTE                            *mThisAudiobuffer;
        ExtAudioFileRef                 mAudRef;
        MPMediaItem                     *mSong;
  
        AVAssetReader                   *mAssetReader;
        AVAssetReaderOutput             *mAssetReaderOutput; 
		static void isRunningProc(		void *              inUserData,
										AudioQueueRef           inAQ,
										AudioQueuePropertyID    inID);

		static void AQBufferCallback(	void *					inUserData,
										AudioQueueRef			inAQ,
										AudioQueueBufferRef		inCompleteAQBuffer); 
		void CalculateBytesForTime(		CAStreamBasicDescription & inDesc, 
										UInt32 inMaxPacketSize, 
										Float64 inSeconds, 
										UInt32 *outBufferSize, 
										UInt32 *outNumPackets);		
            
	};