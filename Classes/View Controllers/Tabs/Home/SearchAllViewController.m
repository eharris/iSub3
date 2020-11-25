//
//  SearchAllViewController.m
//  iSub
//
//  Created by Ben Baron on 4/6/11.
//  Copyright 2011 Ben Baron. All rights reserved.
//

#import "SearchAllViewController.h"
#import "SearchSongsViewController.h"
#import "UIViewController+PushViewControllerCustom.h"
#import "Defines.h"
#import "SavedSettings.h"
#import "EX2Kit.h"
#import "Swift.h"

@implementation SearchAllViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.cellNames = [NSMutableArray arrayWithCapacity:3];
	
	if (self.listOfArtists.count > 0) {
		[self.cellNames addObject:@"Artists"];
	}
	
	if (self.listOfAlbums.count > 0) {
		[self.cellNames addObject:@"Albums"];
	}
	
	if (self.listOfSongs.count > 0) {
		[self.cellNames addObject:@"Songs"];
	}
    
    self.tableView.rowHeight = Defines.rowHeight;
    [self.tableView registerClass:UniversalTableViewCell.class forCellReuseIdentifier:UniversalTableViewCell.reuseId];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cellNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UniversalTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UniversalTableViewCell.reuseId];
    [cell updateWithPrimaryText:[self.cellNames objectAtIndexSafe:indexPath.row] secondaryText:nil];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!indexPath) return;
	
	SearchSongsViewController *searchView = [[SearchSongsViewController alloc] initWithNibName:@"SearchSongsViewController" bundle:nil];
	NSString *type = [self.cellNames objectAtIndexSafe:indexPath.row];
	if ([type isEqualToString:@"Artists"]) {
		searchView.listOfArtists = [NSMutableArray arrayWithArray:self.listOfArtists];
		searchView.searchType = ISMSSearchSongsSearchType_Artists;
	} else if ([type isEqualToString:@"Albums"]) {
		searchView.listOfAlbums = [NSMutableArray arrayWithArray:self.listOfAlbums];
		searchView.searchType = ISMSSearchSongsSearchType_Albums;
	} else if ([type isEqualToString:@"Songs"]) {
		searchView.listOfSongs = [NSMutableArray arrayWithArray:self.listOfSongs];
		searchView.searchType = ISMSSearchSongsSearchType_Songs;
	}
	searchView.query = self.query;
	[self pushViewControllerCustom:searchView];
}

@end
