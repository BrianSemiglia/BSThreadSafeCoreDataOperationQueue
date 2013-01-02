//
//  BSConcurrentManagedObjectContext.h
//
//
//  Created by Brian on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import <CoreData/CoreData.h>

// The first time a BSConcurrentManagedObjectContext is created, a singleton parent context is also
// created. From then on any BSConcurrentManagedObjectContext's created save to that parent context.
// The singleton parent context runs on a private serial queue in the background. This removes the need for
// a NSManagedObjectContext within your application delegate. A BSConcurrentManagedObjectContext has the
// components for assigning it perisistentStoreCoordinator within it. This was done for convenience and to
// ensure that the child and parent contexts are on the same page.

// All saves and fetches are executed asynchronously from the main thread but dispatched to a serial queue,
// ensuring that saves happen in the order that they were submitted. The completion handler is run on the
// thread that it's method was called on.

typedef void (^FetchCompletionHandler)(NSArray *fetchedObjects, NSError *error);
typedef void (^ParentContextOperationBlock)(NSManagedObjectContext *parentContext);
typedef void (^ParentContextOperationCompletionHandler)(void);

@interface BSThreadSafeManagedObjectContext : NSManagedObjectContext

@property (nonatomic, assign) BOOL shouldListenForOtherContextChanges;
@property (nonatomic, strong) NSManagedObjectContext *parentContext;

- (void)performBlockOnParentContext:(ParentContextOperationBlock)block
              withCompletionHandler:(ParentContextOperationCompletionHandler)completionHandler;

- (void)executeAsynchronousFetchRequest:(NSFetchRequest *)request
                  withCompletionHandler:(FetchCompletionHandler)completionHandler;

@end