//
//  viewFilter.h
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-21.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface viewFilter : UIViewController
{
    IBOutlet UISwitch *switchLPF;
    IBOutlet UISwitch *switchHPF;
    IBOutlet UISwitch *switchVC;
    IBOutlet UISlider *sliderGain;
}
-(IBAction)SetLPF:(id)sender;
-(IBAction)SetHPF:(id)sender;
-(IBAction)changeGain:(id)sender;
-(IBAction)SetVC:(id)sender;
@end
