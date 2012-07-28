//
//  BSConcurrentFetchedResultsController.h
//  CoreDataThreading
//
//  Created by Brian on 7/27/12.
//  Copyright (c) 2012 Brian. All rights reserved.
//

#import <CoreData/CoreData.h>

@class BSConcurrentManagedObjectContext;

@interface BSConcurrentFetchedResultsController : NSFetchedResultsController <NSFetchedResultsControllerDelegate>

- (void)performAsynchronousFetchWithCompletionHandler:(void(^)(NSError *error))completionHandler;

@end
