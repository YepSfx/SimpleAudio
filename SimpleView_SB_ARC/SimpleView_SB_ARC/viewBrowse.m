//
//  viewBrowse.m
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-20.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "viewBrowse.h"
#import "GlobalMsg.h"

@implementation viewBrowse

-(void)MakeFileList
{
    NSArray *dirPaths;
    NSString *docsDir;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                   NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    DirName = docsDir;
    FileNameList = [[NSFileManager defaultManager] directoryContentsAtPath:docsDir];
    LibNameList  = [[NSMutableArray alloc] init];
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString        *selFileName;
    MPMediaItem     *song;
    
    int index = indexPath.row;

    if (!isDataFromLibrary)
    {    
        selFileName = [NSString stringWithFormat:@"%@/%@",DirName,[FileNameList objectAtIndex:index]]; 
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:DEF_SEL_FILENAME object:selFileName ];    

    }else 
    {
        song = [LibNameList objectAtIndex:index];
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:DEF_SET_LIBSONG object:song ];            
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!isDataFromLibrary)
    {
       return [FileNameList count];     
    }else
    {
       return [LibNameList count];    
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    MPMediaItem     *song;

    if (!isDataFromLibrary)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"fileListCell"];
    
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileListCell"];
        }
    
        cell.textLabel.text = [FileNameList objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = @"From Documents";                       
    }else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"fileListCell"];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileListCell"];
        }                
                
        song = [LibNameList objectAtIndex:indexPath.row];
        cell.textLabel.text = [song valueForProperty:MPMediaItemPropertyTitle];
        cell.detailTextLabel.text = @"From Library";          
    }
    
    return cell;
}

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
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    isDataFromLibrary = FALSE;
    [self MakeFileList]; 
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

-(IBAction)SelectDocuments:(id)sender
{
    isDataFromLibrary = FALSE;
    [fileList reloadData];
}

-(IBAction)SelectLibrary:(id)sender
{
    [self selectSongsFromLibrary:sender];
}

-(void)selectSongsFromLibrary:(id)sender
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
        isDataFromLibrary = TRUE; 
        
        [LibNameList removeAllObjects];        
        count = mediaItemCollection.count;
        
        for(i = 0 ; i < count ; i++)
        {
            
            song = [mediaItemCollection.items objectAtIndex: i] ;
            [LibNameList addObject:song];
        }        
        
    }
	[self dismissModalViewControllerAnimated: YES];
    [fileList reloadData];
    
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker 
{
	[self dismissModalViewControllerAnimated: YES];
}

@end
