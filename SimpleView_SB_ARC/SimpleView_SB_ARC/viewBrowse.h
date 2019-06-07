//
//  viewBrowse.h
//  SimpleView_SB_ARC
//
//  Created by Stemcell INS on 12-02-20.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface viewBrowse : UIViewController
<UITableViewDataSource, UITableViewDelegate,MPMediaPickerControllerDelegate>
{
    IBOutlet UITableView    *fileList;
    NSMutableArray          *FileNameList;
    NSMutableArray          *LibNameList;
    NSString                *DirName;
    BOOL                    *isDataFromLibrary;
}
-(void)selectSongsFromLibrary:(id)sender;
-(IBAction)SelectDocuments:(id)sender;
-(IBAction)SelectLibrary:(id)sender;
@end
