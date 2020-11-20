//
//  MenuViewController.m
//  StackScrollView
//
//  Created by Reefaq on 2/24/11.
//  Copyright 2011 raw engineering . All rights reserved.
//

#import "MenuViewController.h"
#import "iPadRootViewController.h"
#import "MenuTableViewCell.h"
#import "FoldersViewController.h"
#import "AllAlbumsViewController.h"
#import "AllSongsViewController.h"
#import "PlaylistsViewController.h"
#import "PlayingViewController.h"
#import "BookmarksViewController.h"
#import "GenresViewController.h"
#import "CacheViewController.h"
#import "ChatViewController.h"
#import "UIViewController+PushViewControllerCustom.h"
#import "ServerListViewController.h"
#import "CustomUINavigationController.h"
#import "iSubAppDelegate.h"
#import "Defines.h"
#import "SavedSettings.h"
#import "EX2Kit.h"
#import "Swift.h"

@interface MenuTableItem : NSObject
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *text;
+ (instancetype)itemWithImageName:(NSString *)imageName text:(NSString *)text;
@end

@implementation MenuTableItem
+ (instancetype)itemWithImageName:(NSString *)imageName text:(NSString *)text {
    MenuTableItem *item = [[MenuTableItem alloc] init];
    item.image = [UIImage imageNamed:imageName];
    item.text = text;
    return item;
}
@end

@implementation MenuViewController

#pragma mark View lifecycle

- (void)toggleOfflineMode {
	self.isFirstLoad = YES;
	[self loadCellContents];
	[self viewDidAppear:YES];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        self.view.frame = frame;
		
		// Create the background color
		UIView *background = [[UIView alloc] initWithFrame:self.view.frame];
		background.backgroundColor = [UIColor darkGrayColor];
		UIView *shade = [[UIView alloc] initWithFrame:self.view.frame];
		shade.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
		[background addSubview:shade];
		[self.view addSubview:background];
        
        // Create the menu
        [self loadCellContents];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 300) style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.view addSubview:_tableView];
        
        // Create the player holder
        _playerHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 667)];
        _playerHolder.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:_playerHolder];
        
        // Create the player
        _playerController = [[PlayerViewController alloc] init];
        _playerController.view.frame = _playerHolder.frame;
        [_playerHolder addSubview:_playerController.view];
				
		_isFirstLoad = YES;
		_lastSelectedRow = NSIntegerMax;
        
        [NSLayoutConstraint activateConstraints:@[
            [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [_tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [_playerHolder.heightAnchor constraintEqualToConstant:570.0],
            [_playerHolder.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [_playerHolder.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [_playerHolder.topAnchor constraintEqualToAnchor:_tableView.bottomAnchor],
            [_playerHolder.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        ]];
	}
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (_isFirstLoad) {
		_isFirstLoad = NO;
		[self showHome];
	}
}

- (void)loadCellContents {
	_tableView.scrollEnabled = NO;
	_cellContents = [NSMutableArray arrayWithCapacity:10];
	
    if (appDelegateS.referringAppUrl) {
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"back-tabbaricon.png" text:@"Back"]];
    }
    
	if (settingsS.isOfflineMode) {
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"settings-tabbaricon.png"    text:@"Settings"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"folders-tabbaricon.png"     text:@"Folders"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"genres-tabbaricon.png"      text:@"Genres"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"playlists-tabbaricon.png"   text:@"Playlists"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"bookmarks-tabbaricon.png"   text:@"Bookmarks"]];
	} else {
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"settings-tabbaricon.png"    text:@"Settings"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"home-tabbaricon.png"        text:@"Home"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"folders-tabbaricon.png"     text:@"Folders"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"playlists-tabbaricon.png"   text:@"Playlists"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"playing-tabbaricon.png"     text:@"Playing"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"bookmarks-tabbaricon.png"   text:@"Bookmarks"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"cache-tabbaricon.png"       text:@"Cache"]];
        [_cellContents addObject:[MenuTableItem itemWithImageName:@"chat-tabbaricon.png"        text:@"Chat"]];

		if (settingsS.isSongsTabEnabled)
		{
			_tableView.scrollEnabled = YES;
            [_cellContents addObject:[MenuTableItem itemWithImageName:@"genres-tabbaricon.png"   text:@"Genres"]];
            [_cellContents addObject:[MenuTableItem itemWithImageName:@"albums-tabbaricon.png"   text:@"Albums"]];
            [_cellContents addObject:[MenuTableItem itemWithImageName:@"songs-tabbaricon.png"    text:@"Songs"]];
		}
	}
	
	[_tableView reloadData];
}

- (void)showSettings {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	[self tableView:_tableView didSelectRowAtIndexPath:indexPath];
}

- (void)showHome {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    [_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	[self tableView:_tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section  {
    return _cellContents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    static NSString *cellIdentifier = @"MenuTableViewCell";
	MenuTableViewCell *cell = (MenuTableViewCell*)[_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[MenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    MenuTableItem *item = _cellContents[indexPath.row];
    cell.textLabel.text = item.text;
	cell.imageView.image = item.image;
//	cell.glowView.hidden = YES;
	cell.imageView.alpha = 0.6;

    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
	if (!indexPath) return;
    
    // Handle the special case of the back button / ref url
    if (appDelegateS.referringAppUrl) {
        if (indexPath.row == 0) {
            // Fix the cell highlighting
            [_tableView deselectRowAtIndexPath:indexPath animated:NO];
            [_tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelectedRow inSection:0]
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
            
            // Go back to the other app
            [UIApplication.sharedApplication openURL:appDelegateS.referringAppUrl options:@{} completionHandler:nil];
            return;
        }
    }
	
//	// Set the tabel cell glow
//	//
//	for (MenuTableViewCell *cell in _tableView.visibleCells) {
//		cell.glowView.hidden = YES;
//		cell.imageView.alpha = 0.6;
//	}
//
//    MenuTableViewCell *selectedCell = (MenuTableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
//	[selectedCell glowView].hidden = NO;
//	selectedCell.imageView.alpha = 1.0;
		
	[self performSelector:@selector(showControllerForIndexPath:) withObject:indexPath afterDelay:0.05];
}

- (void)showControllerForIndexPath:(NSIndexPath *)indexPath {
    // If we have the back button displayed, subtract 1 from the row to get the correct action
    NSUInteger row = appDelegateS.referringAppUrl ? indexPath.row - 1 : indexPath.row;
    
	// Present the view controller
	//
	UIViewController *controller;
	
	if (settingsS.isOfflineMode) {
		switch (row) {
            case 0: controller = [[ServerListViewController alloc] initWithNibName:@"ServerListViewController" bundle:nil]; break;
			case 1: controller = [[CacheViewController alloc] initWithNibName:@"CacheViewController" bundle:nil]; break;
			case 2: controller = [[GenresViewController alloc] initWithNibName:@"GenresViewController" bundle:nil]; break;
			case 3: controller = [[PlaylistsViewController alloc] initWithNibName:@"PlaylistsViewController" bundle:nil]; break;
			case 4: controller = [[BookmarksViewController alloc] initWithNibName:@"BookmarksViewController" bundle:nil]; break;
			
			default: controller = nil;
		}
	} else {
		switch (row) {
            case 0: controller = [[ServerListViewController alloc] initWithNibName:@"ServerListViewController" bundle:nil]; break;
            case 1: controller = [[HomeViewController alloc] initWithNibName:@"HomeViewController" bundle:nil]; break;
			case 2: controller = [[FoldersViewController alloc] initWithNibName:@"FoldersViewController" bundle:nil]; break;
			case 3: controller = [[PlaylistsViewController alloc] initWithNibName:@"PlaylistsViewController" bundle:nil]; break;
			case 4: controller = [[PlayingViewController alloc] initWithNibName:@"PlayingViewController" bundle:nil]; break;
			case 5: controller = [[BookmarksViewController alloc] initWithNibName:@"BookmarksViewController" bundle:nil]; break;
			case 6: controller = [[CacheViewController alloc] initWithNibName:@"CacheViewController" bundle:nil]; break;
			case 7: controller = [[ChatViewController alloc] initWithNibName:@"ChatViewController" bundle:nil]; break;
            
			case 8: controller = [[GenresViewController alloc] initWithNibName:@"GenresViewController" bundle:nil]; break;
			case 9: controller = [[AllAlbumsViewController alloc] initWithNibName:@"AllAlbumsViewController" bundle:nil]; break;
			case 10: controller = [[AllSongsViewController alloc] initWithNibName:@"AllSongsViewController" bundle:nil]; break;
			default: controller = nil;
		}
	}
	  
    [appDelegateS.ipadRootViewController switchContentViewController:controller];
    
    _lastSelectedRow = indexPath.row;
}

@end

