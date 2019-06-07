//
//  filter.h
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef SimpleView_SB_ARC_filter_h
#define SimpleView_SB_ARC_filter_h

#define BYTE                unsigned char
#define SAMPLE              signed short
#define RAWDATA             unsigned int
#define INT16               signed short
#define INT32               signed int

void InitFilter();
void ProcVocalRemove(BYTE* pBuffer, int nCh, int nBytes, int nBytesPerSamp, int sw, int speaker, BOOL isLibraryMono);
void ProcFilter(BYTE* pBuffer, int nCh, int nBytes, int nBytesPerSamp, int type);
void ProcMasterGain(BYTE* pBuffer, int nCh, int nBytes, int nBytesPerSamp, SAMPLE gain);

SInt16 MakeMasterGain(int vol);

#endif
