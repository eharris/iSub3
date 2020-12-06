//
//  SUSStatusLoader.m
//  iSub
//
//  Created by Ben Baron on 8/22/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "SUSStatusLoader.h"
#import "NSMutableURLRequest+SUS.h"
#import "RXMLElement.h"
#import "NSError+ISMSError.h"
#import "Defines.h"
#import "EX2Kit.h"

LOG_LEVEL_ISUB_DEFAULT

@implementation SUSStatusLoader

- (SUSLoaderType)type {
    return SUSLoaderType_Status;
}

- (NSURLRequest *)createRequest {
    if (!self.urlString || !self.username || !self.password)
        return nil;
    
    return [NSMutableURLRequest requestWithSUSAction:@"ping" urlString:self.urlString username:self.username password:self.password parameters:nil];
}

- (void)startLoad {
    if (![self createRequest]) {
        NSError *error = [NSError errorWithISMSCode:ISMSErrorCode_CouldNotCreateConnection];
        [self informDelegateLoadingFailed:error];
        return;
    }
    
    [super startLoad];
}

- (void)processResponse {    
    RXMLElement *root = [[RXMLElement alloc] initFromXMLData:self.receivedData];
    if (!root.isValid) {
        NSError *error = [NSError errorWithISMSCode:ISMSErrorCode_NotXML];
        [self informDelegateLoadingFailed:error];
        [NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_ServerCheckFailed];
    } else {
        if ([root.tag isEqualToString:@"subsonic-response"]) {
			self.versionString = [root attribute:@"version"];
			if (self.versionString) {
				NSArray *splitVersion = [self.versionString componentsSeparatedByString:@"."];
				if ([splitVersion count] > 0) {
					self.majorVersion = [[splitVersion objectAtIndexSafe:0] intValue];
					if (self.majorVersion >= 2) {
						self.isNewSearchAPI = YES;
                        self.isVideoSupported = YES;
                    }
					
					if ([splitVersion count] > 1) {
						self.minorVersion = [[splitVersion objectAtIndexSafe:1] intValue];
                        if (self.majorVersion >= 1 && self.minorVersion >= 4) {
							self.isNewSearchAPI = YES;
                        }
                        
                        if (self.majorVersion >= 1 && self.minorVersion >= 7) {
                            self.isVideoSupported = YES;
                        }
					}
				}
			}
            
            RXMLElement *error = [root child:@"error"];
            if (error.isValid) {
                NSString *code = [error attribute:@"code"];
                if ([code integerValue] == 40) {
                    // Incorrect credentials, so fail
                    NSError *anError = [NSError errorWithISMSCode:ISMSErrorCode_IncorrectCredentials];
                    [self informDelegateLoadingFailed:anError];
                    [NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_ServerCheckFailed];
                } else {
                    // This is a Subsonic server, so pass
                    [self informDelegateLoadingFinished];
                    [NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_ServerCheckPassed];
                }
            } else {
                // This is a Subsonic server, so pass
                [self informDelegateLoadingFinished];
                [NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_ServerCheckPassed];
            }
        } else {
            // This is not a Subsonic server, so fail
            NSError *anError = [NSError errorWithISMSCode:ISMSErrorCode_NotASubsonicServer];
			[self informDelegateLoadingFailed:anError];
			[NSNotificationCenter postNotificationToMainThreadWithName:ISMSNotification_ServerCheckFailed];
        }
    }
}

@end
