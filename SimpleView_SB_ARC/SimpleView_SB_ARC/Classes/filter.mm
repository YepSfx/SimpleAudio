//
//  filter.c
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>
#include "filter.h"

#define MUL16(a,b,c)        ( (a *b) >> c )
#define MULGAIN(d, g)       ( MUL16(d, g, 14 ) )

#define MAXDIV(a)           (INT32)( (1 << (a) ) )
#define MAKEFIXED16(a,b)    (INT16)( (a) * MAXDIV(b) )
#define MAKECOEF(c)         MAKEFIXED16(c, 14)
#define VOCALREMOVE3DB      0x2CCC

static SAMPLE PrevData[2][7];
static SAMPLE PrevVCData[2][0];

void InitFilter()
{
    memset(PrevData, 0, sizeof(PrevData));  
    memset(PrevVCData, 0, sizeof(PrevVCData));
}

void ProcVocalRemove(BYTE* pBuffer, int nCh, int nBytes, int nBytesPerSamp, int sw, int speaker, BOOL isLibraryMono)
{
    int i;
    SAMPLE      Out[2], RawIn[2];
    RAWDATA     *pRaw;
    
    pRaw = (RAWDATA*)pBuffer;

    if (isLibraryMono)
        return;
    
    switch(nCh)
    {
        default:
        case 1:
            break;
        case 2:
            if (sw)
            {
                for (i = 0 ; i < ((nBytes/nBytesPerSamp)/nCh) ; i++)  
                {
                    RawIn[0] = (SAMPLE)(pRaw[i]&(0x0000FFFF));
                    RawIn[1] = (SAMPLE)(pRaw[i]>>16);
                    
                    RawIn[0] = MULGAIN(RawIn[0], VOCALREMOVE3DB);
                    RawIn[1] = MULGAIN(RawIn[1], VOCALREMOVE3DB);
                    
                    Out[0]  = RawIn[0] - RawIn[1];
                    Out[1]  = RawIn[1] - RawIn[0];
                    if (!speaker)
                        pRaw[i] = Out[0] + (Out[1]<<16);  
                    else
                        pRaw[i] = Out[0] + (Out[0]<<16);
                }
            }
            break;
    }
}

void ProcMasterGain(BYTE* pBuffer, int nCh, int nBytes, int nBytesPerSamp, SAMPLE gain)
{
    int i;
    SAMPLE      Out[2], *pWrk, RawIn[2];
    RAWDATA     *pRaw;
    
    pWrk = (SAMPLE*)pBuffer;
    pRaw = (RAWDATA*)pBuffer;

    switch(nCh)
    {
        case 1:
            for (i = 0 ; i < (nBytes/nBytesPerSamp) ; i++)
            {
                Out[0]  = MULGAIN(pWrk[i], gain);
                pWrk[i] = Out[0];
            }            
            break;
        case 2:
            for (i = 0 ; i < ((nBytes/nBytesPerSamp)/nCh) ; i++)
            {
                RawIn[0] = (SAMPLE)(pRaw[i]&(0x0000FFFF));
                RawIn[1] = (SAMPLE)(pRaw[i]>>16);
                
                Out[0]   = MULGAIN(RawIn[0], gain);
                Out[1]   = MULGAIN(RawIn[1], gain);
                                
                pRaw[i] = Out[0] + (Out[1]<<16); 
            }            
            break;
    }
}

void ProcFilter(BYTE* pBuffer, int nCh, int nBytes, int nBytesPerSamp, int filter)
{
    int i;
    SAMPLE      *pWrk, RawIn[2];
    RAWDATA     *pRaw;
    SAMPLE       Out[2];
    
    pWrk = (SAMPLE*)pBuffer;
    pRaw = (RAWDATA*)pBuffer;
    
    switch(nCh)
    {
        case 1:
            for (i = 0 ; i < (nBytes/nBytesPerSamp) ; i++)
            {
                switch(filter)
                {
                    default:
                    case 0:
                        break;
                    case 1:
                        Out[0]  = ( (pWrk[i]>>3) + 
                                    (PrevData[0][0]>>3) +
                                    (PrevData[0][1]>>3) + 
                                    (PrevData[0][2]>>3) + 
                                    (PrevData[0][3]>>3) + 
                                    (PrevData[0][4]>>3) +
                                    (PrevData[0][5]>>3) + 
                                    (PrevData[0][6]>>3) 
                                  );
                        PrevData[0][6] = PrevData[0][5];
                        PrevData[0][5] = PrevData[0][4];
                        PrevData[0][4] = PrevData[0][3];
                        PrevData[0][3] = PrevData[0][2]; 
                        PrevData[0][2] = PrevData[0][1];
                        PrevData[0][1] = PrevData[0][0];
                        PrevData[0][0] = pWrk[i];
                        pWrk[i]        = Out[0];
                        break;
                    case 2:
                        Out[0]  = ((pWrk[i]>>1) - (PrevData[0][0]>>1));
                        PrevData[0][0] = pWrk[i];
                        pWrk[i]        = Out[0];
                        break;                        
                }                
            }            
            break;
        case 2:
            for (i = 0 ; i < ((nBytes/nBytesPerSamp)/nCh) ; i++)
            {
                switch(filter)
                {
                    default:
                    case 0:
                        break;
                    case 1:
                        RawIn[0] = pRaw[i]&(0x0000FFFF);
                        RawIn[1] = pRaw[i]>>16;
                        
                        Out[0]  = ( (RawIn[0]>>3) + 
                                   (PrevData[0][0]>>3) +
                                   (PrevData[0][1]>>3) + 
                                   (PrevData[0][2]>>3) + 
                                   (PrevData[0][3]>>3) + 
                                   (PrevData[0][4]>>3) +
                                   (PrevData[0][5]>>3) + 
                                   (PrevData[0][6]>>3) 
                                   );
                        PrevData[0][6] = PrevData[0][5];
                        PrevData[0][5] = PrevData[0][4];
                        PrevData[0][4] = PrevData[0][3];
                        PrevData[0][3] = PrevData[0][2]; 
                        PrevData[0][2] = PrevData[0][1];
                        PrevData[0][1] = PrevData[0][0];
                        PrevData[0][0] = RawIn[0];
                        
                        Out[1]  = ( (RawIn[1]>>3) + 
                                   (PrevData[1][0]>>3) +
                                   (PrevData[1][1]>>3) + 
                                   (PrevData[1][2]>>3) + 
                                   (PrevData[1][3]>>3) + 
                                   (PrevData[1][4]>>3) +
                                   (PrevData[1][5]>>3) + 
                                   (PrevData[1][6]>>3) 
                                   );
                        PrevData[1][6] = PrevData[1][5];
                        PrevData[1][5] = PrevData[1][4];
                        PrevData[1][4] = PrevData[1][3];
                        PrevData[1][3] = PrevData[1][2]; 
                        PrevData[1][2] = PrevData[1][1];
                        PrevData[1][1] = PrevData[1][0];
                        PrevData[1][0] = RawIn[1];
                        
                        pRaw[i] = Out[0] + (Out[1]<<16); 
                        break;
                    case 2:
                        RawIn[0] = (SAMPLE)(pRaw[i]&(0x0000FFFF));
                        RawIn[1] = (SAMPLE)(pRaw[i]>>16);
                        
                        Out[0]  = ((RawIn[0]>>1) - (PrevData[0][0]>>1));
                        PrevData[0][0] = RawIn[0];
                        
                        Out[1]  = ((RawIn[1]>>1) - (PrevData[1][0])>>1);
                        PrevData[1][0] = RawIn[1];
                        
                        pRaw[i] = Out[0] + (Out[1]<<16);                         
                        break;
                }
           
            }            
            break;
    }
}

SInt16 MakeMasterGain(int vol)
{
    float tmpfloat;
    int tmp = vol;
    SInt16    gain = 0;
    if (tmp > 200)
        tmp = 200;
    
    if (tmp < 0)
        tmp = 0;
    
    if (tmp == 200){
        tmpfloat = 2.0;
        gain     = 0x8000; 
    }else{  
        tmpfloat = tmp * 0.01; 
        gain = MAKECOEF(tmpfloat);
    }
    return gain;
}
