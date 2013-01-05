//
//  BSThreadSafeContextController.h
//
//
//  Created by Brian on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import <CoreData/CoreData.h>

// Operations are submitted to a static, serial operations queue.
// Operations are executed in the order they are submitted.
// Operations do not block the thread they were submitted from.
// The managed object context can be accessed from any thread.
// Accessing the context blocks the operation queue.

// This method allows for simple background saving that is thread safe.
// This method does not allow for concurrent save operations.

@interface BSThreadSafeContextController : NSOperationQueue

// Must be atomic. May cause crash if not.
@property (atomic, strong) NSManagedObjectContext *managedObjectContext;

+ (id)sharedInstance;
- (void)performBlockWithSharedContext:(void (^)(NSManagedObjectContext *context))block;

@end