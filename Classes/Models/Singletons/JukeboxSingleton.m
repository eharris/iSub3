//
//  JukeboxSingleton.m
//  iSub
//
//  Created by Ben Baron on 2/24/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "JukeboxSingleton.h"
#import "NSMutableURLRequest+SUS.h"
#import "FMDatabaseQueueAdditions.h"
#import "SavedSettings.h"
#import "DatabaseSingleton.h"
#import "EX2Kit.h"
#import "ISMSSong+DAO.h"
#import "Swift.h"

@interface JukeboxXMLParserDelegate : NSObject <NSXMLParserDelegate>
@property NSUInteger currentIndex;
@property BOOL isPlaying;
@property float gain;
@property (strong) NSMutableArray *listOfSongs;
@end

@interface JukeboxSingleton()
@property (nonatomic, strong) NSURLSession *sharedSession;
@property (nonatomic, strong) SelfSignedCertURLSessionDelegate *sharedSessionDelegate;
@end

@implementation JukeboxSingleton

#pragma mark Jukebox Control methods

- (void)jukeboxPlaySongAtPosition:(NSNumber *)position {
    [self queueDataTaskWithAction:@"skip" parameters:@{@"index": n2N(position.stringValue)}];
    playlistS.currentIndex = position.intValue;
}


- (void)jukeboxPlay {
    [self queueDataTaskWithAction:@"start" parameters:nil];
	self.jukeboxIsPlaying = YES;
}

- (void)jukeboxStop {
    [self queueDataTaskWithAction:@"stop" parameters:nil];
    self.jukeboxIsPlaying = YES;
	self.jukeboxIsPlaying = NO;
}

- (void)jukeboxPrevSong {
	NSInteger index = playlistS.currentIndex - 1;
	if (index >= 0) {
		[self jukeboxPlaySongAtPosition:@(index)];
		self.jukeboxIsPlaying = YES;
	}
}

- (void)jukeboxNextSong {
	NSInteger index = playlistS.currentIndex + 1;
	if (index <= ([databaseS.currentPlaylistDbQueue intForQuery:@"SELECT COUNT(*) FROM jukeboxCurrentPlaylist"] - 1)) {
		[self jukeboxPlaySongAtPosition:@(index)];
		self.jukeboxIsPlaying = YES;
	} else {
		[NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_SongPlaybackEnded];
		[self jukeboxStop];
		self.jukeboxIsPlaying = NO;
	}
}

- (void)jukeboxSetVolume:(float)level {
    NSString *gainString = [NSString stringWithFormat:@"%f", level];
    [self queueDataTaskWithAction:@"setGain" parameters:@{@"gain": n2N(gainString)}];
}

- (void)jukeboxAddSong:(NSString *)songId {
    [self queueDataTaskWithAction:@"add" parameters:@{@"id": n2N(songId)}];
}

- (void)jukeboxAddSongs:(NSArray *)songIds {
	if (songIds.count > 0) {
        [self queueDataTaskWithAction:@"add" parameters:@{@"id": n2N(songIds)}];
	}
}

- (void)jukeboxReplacePlaylistWithLocal {
	[self jukeboxClearRemotePlaylist];
	
	__block NSMutableArray *songIds = [[NSMutableArray alloc] init];
	[databaseS.currentPlaylistDbQueue inDatabase:^(FMDatabase *db) {
        NSString *table = playlistS.isShuffle ? @"jukeboxShufflePlaylist" : @"jukeboxCurrentPlaylist";
        FMResultSet *result = [db executeQuery:[NSString stringWithFormat:@"SELECT songId FROM %@", table]];
		while ([result next]) {
			@autoreleasepool {
				NSString *songId = [result stringForColumnIndex:0];
				if (songId) [songIds addObject:songId];
			}
		}
		[result close];
	}];
	
	[self jukeboxAddSongs:songIds];
}

- (void)jukeboxRemoveSong:(NSString*)songId {
    [self queueDataTaskWithAction:@"remove" parameters:@{@"id": n2N(songId)}];
}

- (void)jukeboxClearPlaylist {
    [self queueDataTaskWithAction:@"clear" parameters:nil];
    [databaseS resetJukeboxPlaylist];
}

- (void)jukeboxClearRemotePlaylist {
    [self queueDataTaskWithAction:@"clear" parameters:nil];
}

- (void)jukeboxShuffle {
    [self queueDataTaskWithAction:@"shuffle" parameters:nil];
    [databaseS resetJukeboxPlaylist];
}

- (void)jukeboxGetInfoInternal {
    if (settingsS.isJukeboxEnabled) {
        [self queueGetInfoDataTask];
        if (playlistS.isShuffle) {
            [databaseS resetShufflePlaylist];
        } else {
            [databaseS resetJukeboxPlaylist];
        }
        
        // Keep reloading every 30 seconds if there is no activity so that the player stays updated if visible
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(jukeboxGetInfoInternal) object:nil];
        [self performSelector:@selector(jukeboxGetInfoInternal) withObject:nil afterDelay:30.0];
    }
}

- (void)jukeboxGetInfo {
	// Make sure this doesn't run a bunch of times in a row
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(jukeboxGetInfoInternal) object:nil];
	[self performSelector:@selector(jukeboxGetInfoInternal) withObject:nil afterDelay:0.5];
}

- (void)handleConnectionError:(NSError *)error {
    [EX2Dispatch runInMainThreadAsync:^{
        NSString *message = [NSString stringWithFormat:@"There was an error controlling the Jukebox.\n\nError %li: %@", (long)[error code], [error localizedDescription]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [UIApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)queueDataTaskWithAction:(NSString *)action parameters:(NSDictionary *)parameters {
    NSMutableDictionary *mutParams = [@{@"action": action} mutableCopy];
    if (parameters) [mutParams addEntriesFromDictionary:parameters];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithSUSAction:@"jukeboxControl" parameters:mutParams];
    NSURLSessionDataTask *dataTask = [self.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self handleConnectionError:error];
        } else {
            NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
            [xmlParser setDelegate:[[JukeboxXMLParserDelegate alloc] init]];
            [xmlParser parse];
            
            [EX2Dispatch runInMainThreadAsync:^{
                [jukeboxS jukeboxGetInfo];
            }];
        }
    }];
    [dataTask resume];
}

- (void)queueGetInfoDataTask {
    NSURLRequest *request = [NSMutableURLRequest requestWithSUSAction:@"jukeboxControl" parameters:@{@"action": @"get"}];
    NSURLSessionDataTask *dataTask = [self.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self handleConnectionError:error];
        } else {
            JukeboxXMLParserDelegate *parserDelegate = [[JukeboxXMLParserDelegate alloc] init];
            NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
            [xmlParser setDelegate:parserDelegate];
            [xmlParser parse];
                    
            [EX2Dispatch runInMainThreadAsync:^{
                playlistS.currentIndex = parserDelegate.currentIndex;
                jukeboxS.jukeboxGain = parserDelegate.gain;
                jukeboxS.jukeboxIsPlaying = parserDelegate.isPlaying;
                
                [NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_SongPlaybackStarted];
                [NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_JukeboxSongInfo];
            }];
        }
    }];
    [dataTask resume];
}

#pragma mark Singleton methods

- (void)setup {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.HTTPMaximumConnectionsPerHost = 1;
    self.sharedSessionDelegate = [[SelfSignedCertURLSessionDelegate alloc] init];
    self.sharedSession = [NSURLSession sessionWithConfiguration:configuration
                                                       delegate:self.sharedSessionDelegate
                                                  delegateQueue:nil];
}

+ (id)sharedInstance {
    static JukeboxSingleton *sharedInstance = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
		[sharedInstance setup];
	});
    return sharedInstance;
}

@end

#pragma mark JukeboxXMLParserDelegate

@implementation JukeboxXMLParserDelegate

- (instancetype)init {
    if (self = [super init]) {
        _listOfSongs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)subsonicErrorCode:(NSString *)errorCode message:(NSString *)message {
    [EX2Dispatch runInMainThreadAsync:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subsonic Error" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [UIApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }];
    
    if ([errorCode isEqualToString:@"50"]) {
        settingsS.isJukeboxEnabled = NO;
        [NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_JukeboxDisabled];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    [EX2Dispatch runInMainThreadAsync:^{
        NSString *message = @"There was an error parsing the Jukebox XML response.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subsonic Error" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [UIApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"error"]) {
        [self subsonicErrorCode:[attributeDict objectForKey:@"code"] message:[attributeDict objectForKey:@"message"]];
    } else if ([elementName isEqualToString:@"jukeboxPlaylist"]) {
        self.currentIndex = [[attributeDict objectForKey:@"currentIndex"] intValue];
        self.isPlaying = [[attributeDict objectForKey:@"playing"] boolValue];
        self.gain = [[attributeDict objectForKey:@"gain"] floatValue];
        
        if (playlistS.isShuffle) {
            [databaseS resetShufflePlaylist];
        } else {
            [databaseS resetJukeboxPlaylist];
        }
    } else if ([elementName isEqualToString:@"entry"]) {
        ISMSSong *aSong = [[ISMSSong alloc] initWithAttributeDict:attributeDict];
        if (aSong.path) {
            if (playlistS.isShuffle) {
                [aSong insertIntoTable:@"jukeboxShufflePlaylist" inDatabaseQueue:databaseS.currentPlaylistDbQueue];
            } else {
                [aSong insertIntoTable:@"jukeboxCurrentPlaylist" inDatabaseQueue:databaseS.currentPlaylistDbQueue];
            }
        }
    }
}

@end
