//
//  DebugViewController.h
//  iSub
//
//  Created by Ben Baron on 4/9/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ISMSSong;

@interface DebugViewController : UIViewController 

@property (strong) IBOutlet UIProgressView *currentSongProgressView;
@property (strong) IBOutlet UILabel *nextSongLabel;
@property (strong) IBOutlet UIProgressView *nextSongProgressView;

@property (strong) IBOutlet UILabel *songsCachedLabel;
@property (strong) IBOutlet UILabel *cacheSizeLabel;
@property (strong) IBOutlet UILabel *cacheSettingLabel;
@property (strong) IBOutlet UILabel *cacheSettingSizeLabel;
@property (strong) IBOutlet UILabel *freeSpaceLabel;

@property (copy) ISMSSong *currentSong;
@property (copy) ISMSSong *nextSong;
@property float currentSongProgress;
@property float nextSongProgress;

@end
