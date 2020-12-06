//
//  EX2Dispatch.h
//  EX2Kit
//
//  Created by Ben Baron on 4/26/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Static class that wraps various GCD functionality in a simple Objective-C interface
@interface EX2Dispatch : NSObject

/// @name Run after delay

/// Runs a block in a queue after a minimum delay
/// @param queue The GCD queue to place the block
/// @param delay The delay in seconds before running (only guaranteed as a minimum)
/// @param block The block to run
+ (void)runInQueue:(dispatch_queue_t)queue delay:(NSTimeInterval)delay block:(void (^)(void))block;

/// Runs a block in the main thread queue after a minimum delay
/// @param delay The delay in seconds before running (only guaranteed as a minimum)
/// @param block The block to run
+ (void)runInMainThreadAfterDelay:(NSTimeInterval)delay block:(void (^)(void))block;

/// Runs a block in a parallel background queue after a minimum delay
/// @param delay The delay in seconds before running (only guaranteed as a minimum)
/// @param block The block to run
+ (void)runInBackgroundAfterDelay:(NSTimeInterval)delay block:(void (^)(void))block;

/// @name Queue blocks either synchronously or asynchronously

/// Runs a block in a queue
/// @param queue The GCD queue to place the block
/// @param shouldWait Whether to queue the block async (NO) or sync (YES)
/// @param block The block to run
+ (void)runInQueue:(dispatch_queue_t)queue waitUntilDone:(BOOL)shouldWait block:(void (^)(void))block;

/// Runs a block in the main thread queue
/// @param shouldWait Whether to queue the block async (NO) or sync (YES)
/// @param block The block to run
+ (void)runInMainThreadAndWaitUntilDone:(BOOL)shouldWait block:(void (^)(void))block;

/// @name Async convenience methods to make code clearer

/// Runs a block asyncronously in a queue
/// @param queue The GCD queue to place the block
/// @param block The block to run
+ (void)runAsync:(dispatch_queue_t)queue block:(void (^)(void))block;

/// Runs a block asyncronously in a parallel background queue
/// @param block The block to run
+ (void)runInBackgroundAsync:(void (^)(void))block NS_SWIFT_NAME(runInBackgroundAsync(_:));

/// Runs a block asyncronously in the main thread queue
/// @param block The block to run
+ (void)runInMainThreadAsync:(void (^)(void))block NS_SWIFT_NAME(runInMainThreadAsync(_:));

@end

NS_ASSUME_NONNULL_END
