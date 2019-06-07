//
//  viewPlay.h
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-20.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AQPlayer.h"
#import "viewBrowse.h"

#define BYTE    unsigned char

@class viewAudioWave;

@interface viewPlay : UIViewController <MPMediaPickerControllerDelegate>
{
    AQPlayer     *player;   
    NSString     *fileDescription;
	BOOL		 playbackWasInterrupted;
	BOOL		 playbackWasPaused;  
    BOOL         bIsThisLibrary;
    BOOL         bIsDelayed;
    NSString     *audioFileName;
    NSTimer      *timerUpdateWav;
    NSTimer      *timerDelayStart;
    MPMediaItem  *audioSong;
    IBOutlet     UIButton *btn_SelectSong;
    IBOutlet     UIButton *btn_PlayStop;
    IBOutlet     UILabel  *descriptionLabel;
    IBOutlet     UIProgressView *progressBar;
    IBOutlet     viewAudioWave  *viewWaveForm; 
    IBOutlet     UISwitch       *switchLeft;
    IBOutlet     UISwitch       *switchRight;
    unsigned int SampleRate;
    int          nCh;
    int          nBytePerCh;
    int          gain;    
    int          nUpdatesPerPacket;
    int          UpdateSpeed;
    int          UpdateSampleWidthInReal;
    int          UpdateSampleWidthInScale;
    unsigned int UpdateCurrentIndex;        
    int          UpdateWindowOrder;
    UInt32       nPacketsWindow;
    UInt64       TotalAudioPackets;
    SInt64       CurrentPacket;
    BYTE         waveForm[0x10000];
}

-(IBAction)selectSong: (id) sender;
-(IBAction)play: (id) sender;
-(IBAction)ToggleLeft:(id)sender;
-(IBAction)ToggleRight:(id)sender;

@end
