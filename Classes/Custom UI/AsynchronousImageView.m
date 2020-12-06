//
//  AsynchronousImageView.m
//  GLOSS
//
//  Created by Слава on 22.10.09.
//  Copyright 2009 Slava Bushtruk. All rights reserved.
//  ---------------------------------------------------
//
//  Modified by Ben Baron for the iSub project.
//

#import "AsynchronousImageView.h"
#import "AsynchronousImageViewDelegate.h"
#import "iSubAppDelegate.h"
#import "MusicSingleton.h"
#import "SUSCoverArtDAO.h"
#import "Defines.h"
#import "EX2Kit.h"

LOG_LEVEL_ISUB_DEFAULT

@interface AsynchronousImageView() {
    NSString *_coverArtId;
}
@end

@implementation AsynchronousImageView

- (instancetype)initWithFrame:(CGRect)frame coverArtId:(NSString *)artId isLarge:(BOOL)large delegate:(NSObject<AsynchronousImageViewDelegate> *)theDelegate {
	if (self = [super initWithFrame:frame]) {
		_isLarge = large;
        [self setCoverArtId:artId];
		_delegate = theDelegate;
	}
	return self;
}

- (NSString *)coverArtId {
	@synchronized(self) {
		return _coverArtId;
	}
}

- (void)setCoverArtId:(NSString *)artId {
	@synchronized(self) {
		// Make sure old activity indicator is gone
		[self.activityIndicator removeFromSuperview];
		self.activityIndicator = nil;
		
		if (self.coverArtDAO) {
			[self.coverArtDAO cancelLoad];
			self.coverArtDAO.delegate = nil;
			self.coverArtDAO = nil;
		}
		
		_coverArtId = [artId copy];
		
		self.coverArtDAO = [[SUSCoverArtDAO alloc] initWithDelegate:self coverArtId:self.coverArtId isLarge:self.isLarge];
		if (self.coverArtDAO.isCoverArtCached) {
			self.image = self.coverArtDAO.coverArtImage;
		} else {
            BOOL usedSmallCoverArt = NO;
            if (self.isLarge) {
                // Try and use the small cover art temporarily
                SUSCoverArtDAO *coverArtDAOSmall = [[SUSCoverArtDAO alloc] initWithDelegate:self coverArtId:self.coverArtId isLarge:NO];
                if (coverArtDAOSmall.isCoverArtCached) {
                    self.image = coverArtDAOSmall.coverArtImage;
                    usedSmallCoverArt = YES;
                } else {
                    self.image = self.coverArtDAO.defaultCoverArtImage;
                }
            } else {
                self.image = self.coverArtDAO.defaultCoverArtImage;
            }
			
			if (_coverArtId && self.isLarge && !usedSmallCoverArt) {
                self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
				self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
				self.activityIndicator.center = CGPointMake(self.width/2, self.height/2);
				[self addSubview:self.activityIndicator];
				[self.activityIndicator startAnimating];
			}
            [self.coverArtDAO startLoad];
		}
	}
}

#pragma mark Handle User Input

- (void)reloadCoverArt {
	/*if (musicS.currentSongObject.coverArtId) {
		musicS.coverArtUrl = nil;
		if (UIScreen.mainScreen.scale >= 2.0) {
			musicS.coverArtUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@&size=640", [appDelegateS getBaseUrl:@"getCoverArt.view"], musicS.currentSongObject.coverArtId]];
		} else {
			musicS.coverArtUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@&size=320", [appDelegateS getBaseUrl:@"getCoverArt.view"], musicS.currentSongObject.coverArtId]];
		}
		[self loadImageFromURLString:[musicS.coverArtUrl absoluteString]];
	} else  {
		self.image = [UIImage imageNamed:@"default-album-art"];
	}*/
}

- (void)oneTap {
//DLog(@"Single tap");
}

- (void)twoTaps {
//DLog(@"Double tap");
	//[self reloadCoverArt];
}

-(void)threeTaps {
//DLog(@"Triple tap");
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event  {
	// Detect touch anywhere
	UITouch *touch = [touches anyObject];
	
	switch (touch.tapCount) {
		case 1:
			[self performSelector:@selector(oneTap) withObject:nil afterDelay:.5];
			break;
		case 2:
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(oneTap) object:nil];
			[self performSelector:@selector(twoTaps) withObject:nil afterDelay:.5];
			break;
		case 3:
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(twoTaps) object:nil];
			[self performSelector:@selector(threeTaps) withObject:nil afterDelay:.5];
			break;
		default:
			break;
	}
}

- (void)loadingFailed:(SUSLoader *)theLoader withError:(NSError *)error {
    DDLogError(@"[AsynchronousImageView] async cover art loading failed");
    
	[self.activityIndicator removeFromSuperview];
	self.activityIndicator = nil;
	
	self.coverArtDAO = nil;
	if ([self.delegate respondsToSelector:@selector(asyncImageViewLoadingFailed:withError:)]) {
		[self.delegate asyncImageViewLoadingFailed:self withError:error];
	}
}

- (void)loadingFinished:(SUSLoader *)theLoader {
    DDLogInfo(@"[AsynchronousImageView] async cover art loading finished for: %@", self.coverArtId);
    
	[self.activityIndicator removeFromSuperview];
	self.activityIndicator = nil;
	
   //DLog(@"isLarge: %@", NSStringFromBOOL(self.isLarge));
   //DLog(@"delegate: %@", self.delegate);
	
	self.image = self.coverArtDAO.coverArtImage;
    self.coverArtDAO = nil;
	
	if ([self.delegate respondsToSelector:@selector(asyncImageViewFinishedLoading:)]) {
		[self.delegate asyncImageViewFinishedLoading:self];
	}
}

@end
