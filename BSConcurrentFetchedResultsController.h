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

- (id)initWithAsynchronousFetchRequest:(NSFetchRequest *)fetchRequest
                  managedObjectContext:(NSManagedObjectContext *)context
                    sectionNameKeyPath:(NSString *)sectionNameKeyPath
                             cacheName:(NSString *)name;

- (void)performAsynchronousFetchWithCompletionHandler:(void(^)(NSError *error))completionHandler;

@end
