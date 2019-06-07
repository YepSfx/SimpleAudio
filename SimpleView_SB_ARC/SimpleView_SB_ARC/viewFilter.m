//
//  viewFilter.m
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-21.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "viewFilter.h"
#import "GlobalMsg.h"

@implementation viewFilter

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(IBAction)changeGain:(id)sender
{
    NSNumber *sendNum = [NSNumber numberWithInt:sliderGain.value];
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:DEF_SET_MASTERGAIN object:sendNum ];    
}
                              
-(IBAction)SetLPF:(id)sender
{
    if (switchLPF.on == TRUE)
    {
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:DEF_SET_LPF_ON object:nil ];    
        switchHPF.on = FALSE;
    }
    else 
    {
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:DEF_SET_LPF_OFF object:nil ];          
    }
}

-(IBAction)SetHPF:(id)sender
{
    if (switchHPF.on == TRUE)
    {
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:DEF_SET_HPF_ON object:nil ];     
        switchLPF.on = FALSE;
    }
    else 
    {
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:DEF_SET_HPF_OFF object:nil ];          
    }
    
}
-(IBAction)SetVC:(id)sender
{
    if (switchVC.on == TRUE)
    {
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:DEF_SET_VC_ON object:nil ];          
        
    }
    else
    {
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:DEF_SET_VC_OFF object:nil ];          
        
    }
}
#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    switchHPF.on = FALSE;
    switchLPF.on = FALSE;
    switchVC.on  = FALSE;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
