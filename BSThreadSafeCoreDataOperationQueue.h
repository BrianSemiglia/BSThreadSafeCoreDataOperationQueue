//
//  BSThreadSafeCoreDataOperationQueue.h
//
//
//  Created by Brian on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import <CoreData/CoreData.h>

// Operations are submitted to a static, shared, concurrent operations queue.
// Operations are not guaranteed to run in any particular order.
// Operations do not block the thread they were submitted from.
// A managed object context is created for each operation.
// The managed object context provided to the block can be access from any thread/queue but not concurrently.
// The confinement of the MOC to the block makes it easy to manage accessing the context from only one thread/queue at a time.
/*
    [[BSThreadSafeCoreDataOperationQueue sharedInstance] performBlockWithSharedContext:^(NSManagedObjectContext *context)
     {
         // 1. Allowed: SYNC operations submitted to other threads/queues.
         {
              // Operation will block until completed.
              // Safe to access context after operation.
 
              dispatch_sync(dispatch_get_main_queue(), ^{
                  // Access context on main queue.
              });
     
              [context message];
         }
 
         // 2. Disallowed: ASYNC operations submitted to other threads/queues BEFORE any additional messages to the context.
         {
              // Operation will not block.
              // Because of the message to context below the block, a situation is created 
              // where the context might be accessed by two different threads/queues at the same time.
 
              dispatch_async(dispatch_get_main_queue(), ^{
                  // Access context on main queue.
              });
     
              [context message];
         }
 
         // 3. Allowed: ASYNC operations submitted to other threads/queues AFTER any additional messages to the context.
         {
              // Operation will not block but is last to message context thus
              // guaranteeing the context will not be accessed by any other threads/queues.
              
              dispatch_async(dispatch_get_main_queue(), ^{
                  // Access context on main queue.
              });
 
              // No additional messages to the context.
         }
     }];
 */

@interface BSThreadSafeCoreDataOperationQueue : NSOperationQueue

+ (id)sharedInstance;
- (void)addOperationWithContext:(void (^)(NSManagedObjectContext *context))operation;
+ (NSManagedObjectContext *)managedObjectContext;

@end