//
//  NSURL+SkipBackupAttribute.m
//  EX2Kit
//
//  Created by Benjamin Baron on 11/21/12.
//
//

#import "NSURL+SkipBackupAttribute.h"
#import "Defines.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <sys/xattr.h>

LOG_LEVEL_ISUB_DEFAULT

@implementation NSURL (SkipBackupAttribute)

- (BOOL)addOrRemoveSkipAttribute:(BOOL)isAdd {
    // This URL must point to a file
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
        return NO;
    }
    
    NSError *error = nil;
    BOOL success = NO;
    @try {
        success = [self setResourceValue:@(isAdd) forKey:NSURLIsExcludedFromBackupKey error:&error];
        if (!success) {
            DDLogError(@"Error excluding %@ from backup: %@", self.lastPathComponent, error);
        }
    } @catch (NSException *exception) {
        DDLogError(@"Exception excluding %@ from backup: %@", self.lastPathComponent, exception);
    }
    return success;
}

- (BOOL)addSkipBackupAttribute {
    return [self addOrRemoveSkipAttribute:YES];
}

- (BOOL)removeSkipBackupAttribute {
    return [self addOrRemoveSkipAttribute:NO];
}

@end
