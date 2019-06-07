//
//  viewAudioWave.m
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-26.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "viewAudioWave.h"

#define DEF_AMP_CENTER          (81)
#define DEF_AMP_SCALE(a)        (DEF_AMP_CENTER - ( (a) >> 8 ))

@implementation viewAudioWave

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        ChSw[0] = TRUE;
        ChSw[1] = FALSE;
    }
    return self;
}

-(void)SetWindowPacket:(UInt32) nPacks
{
    nPacketsWindow = nPacks;
}

-(void)SetChannels:(int)Chs
{
    nChs = Chs;     
}

-(void)SetScaleInc:(int)Scale
{
    ScaleInc = Scale;
}

-(void)SetBuffer:(BYTE *)pBuffer
{
    pAudBuffer = pBuffer;
}

-(void)SetPlaying:(BOOL)sw
{
    isPlaying = sw;
}
-(void)SetUpdateMovingWindow:(int)movingWindow
{
    UpdateMovingWindow = movingWindow; 
}
-(void)SelectLChannel:(BOOL)swL SetRChannel:(BOOL)swR;
{
    ChSw[0] = swL;
    ChSw[1] = swR;
}

-(void)SetVCON:(BOOL)sw
{
    isVCON = sw; 
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    int     i, xpos, ypos;
    SAMPLE  Data[2], Mono, *pMono;
    RAWDATA *pRaw;    
    CGContextRef context    = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    UIRectFill(rect);
    switch(nChs)
    {
        case 1:
            pMono = (SAMPLE*)pAudBuffer;
            if (ChSw[0] == TRUE)
            {
                CGContextSetStrokeColorWithColor(context, [UIColor greenColor]. CGColor);
                CGContextSetLineWidth(context, 1.0);
                CGContextMoveToPoint(context, 0, DEF_AMP_CENTER);            
                for(i = 0, xpos = 0 ; i < UpdateMovingWindow ; i += ScaleInc)
                {
                    Mono = pMono[i]; 
                    ypos = DEF_AMP_SCALE(Mono);
                    CGContextAddLineToPoint(context, xpos, ypos );                
                    xpos++;
                }            
                CGContextStrokePath(context);                           
            }
            break;
        case 2:
            pRaw = (RAWDATA*)pAudBuffer;
            if (ChSw[0] == TRUE)
            {
                CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
                CGContextSetLineWidth(context, 1.0);
                CGContextMoveToPoint(context, 0, DEF_AMP_CENTER);            
                for(i = 0, xpos = 0 ; i < UpdateMovingWindow ; i += ScaleInc)
                {
                    Data[0] = pRaw[i]&(0x0000FFFF);
                    ypos = DEF_AMP_SCALE(Data[0]);
                    CGContextAddLineToPoint(context, xpos, ypos );                
                    xpos++;
                }
                CGContextStrokePath(context);                  
            }
            if (ChSw[1] == TRUE)
            {    
                CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
                CGContextSetLineWidth(context, 1.0);
                CGContextMoveToPoint(context, 0, DEF_AMP_CENTER);                        

                for(i = 0 , xpos = 0 ; i < UpdateMovingWindow ; i += ScaleInc)
                {
                    if (!isVCON)
                    {
                        Data[1] = (SAMPLE)(pRaw[i]>>16);
                        ypos    = DEF_AMP_SCALE(Data[1]);
                        CGContextAddLineToPoint(context, xpos, ypos ); 
                    }
                    else
                    {
                        Data[1] = pRaw[i]&(0x0000FFFF);
                        ypos    = DEF_AMP_SCALE(Data[1]);
                        CGContextAddLineToPoint(context, xpos, ypos );                         
                    }
                    xpos++;
                }            
                CGContextStrokePath(context);         
            }
            break;
    }
    
    if (!isPlaying)
    {
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        UIRectFill(rect);        
    }
}

@end
