//
//  HomeAlbumViewController.h
//  iSub
//
//  Created by Ben Baron on 2/28/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SUSLoaderDelegate.h"

@class ISMSArtist, ISMSAlbum, SUSQuickAlbumsLoader;

@interface HomeAlbumViewController : UITableViewController <SUSLoaderDelegate>

@property (nonatomic, strong) SUSQuickAlbumsLoader *loader;

@property (nonatomic, strong) NSMutableArray *listOfAlbums;
@property (nonatomic, copy) NSString *modifier;
@property (nonatomic) NSUInteger offset;
@property (nonatomic) BOOL isMoreAlbums;
@property (nonatomic) BOOL isLoading;

@end
