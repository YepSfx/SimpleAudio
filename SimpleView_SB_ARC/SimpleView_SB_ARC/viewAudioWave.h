//
//  viewAudioWave.h
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-26.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "filter.h"

@interface viewAudioWave : UIView
{
    UInt32       nPacketsWindow;
    int          nChs;
    int          ScaleInc;
    int          UpdateMovingWindow; 
    BYTE         *pAudBuffer;
    BOOL         isPlaying;
    BOOL         ChSw[2];
    BOOL         isVCON;
}
-(void)SetWindowPacket:(UInt32)nPacks;
-(void)SetChannels:(int)Chs;
-(void)SetScaleInc:(int)Scale;
-(void)SetBuffer:(BYTE*)pBuffer;
-(void)SetPlaying:(BOOL)sw;
-(void)SetUpdateMovingWindow:(int)movingWindow;
-(void)SelectLChannel:(BOOL)swL SetRChannel:(BOOL)swR;
-(void)SetVCON:(BOOL)sw;
@end
