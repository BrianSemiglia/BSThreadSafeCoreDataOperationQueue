//
//  BSConcurrentFetchedResultsController.m
//  CoreDataThreading
//
//  Created by Brian on 7/27/12.
//  Copyright (c) 2012 Brian. All rights reserved.
//

#import "BSConcurrentFetchedResultsController.h"
#import "BSConcurrentManagedObjectContext.h"

@interface BSConcurrentFetchedResultsController ()
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) BSConcurrentManagedObjectContext *context;
@property dispatch_queue_t returnQueue;
@end

@implementation BSConcurrentFetchedResultsController

- (id)initWithAsynchronousFetchRequest:(NSFetchRequest *)fetchRequest
                  managedObjectContext:(NSManagedObjectContext *)context
                    sectionNameKeyPath:(NSString *)sectionNameKeyPath
                             cacheName:(NSString *)name
{
    self = [super initWithFetchRequest:fetchRequest
                  managedObjectContext:(NSManagedObjectContext *)context
                    sectionNameKeyPath:sectionNameKeyPath
                             cacheName:name];
    if (self)
    {
        self.returnQueue = dispatch_get_current_queue();
        self.context = (BSConcurrentManagedObjectContext *)context;
        
        NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^
        {
            self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.context.parentContext
                                                                                   sectionNameKeyPath:sectionNameKeyPath
                                                                                            cacheName:name] autorelease];
            self.fetchedResultsController.delegate = self;
        }];
        
        blockOperation.threadPriority = 0;
        [self.context.operationQueue addOperations:[NSArray arrayWithObject:blockOperation] waitUntilFinished:YES];
    }
    return self;
}

- (void)performAsynchronousFetchWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^
    {
        NSError *error = nil;
        [self.fetchedResultsController performFetch:&error];
        completionHandler(error);
    }];
    
    blockOperation.threadPriority = 0;
    [self.context.operationQueue addOperation:blockOperation];
}

- (NSArray *)fetchedObjects
{
    return self.fetchedResultsController.fetchedObjects;
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    dispatch_async(self.returnQueue, ^
    {
        [self.delegate controller:self
                 didChangeSection:sectionInfo
                          atIndex:sectionIndex
                    forChangeType:type];
    });
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (![anObject isKindOfClass:[NSManagedObject class]])
        return;
    
    NSManagedObject *object = (NSManagedObject *)anObject;
    dispatch_async(self.returnQueue, ^
    {
        NSManagedObject *mainQueueObject = [self.context objectWithID:object.objectID];
        
        [self.delegate controller:self
                  didChangeObject:mainQueueObject
                      atIndexPath:indexPath
                    forChangeType:type
                     newIndexPath:newIndexPath];
    });
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    dispatch_async(self.returnQueue, ^{
        [self.delegate controllerDidChangeContent:self];
    });
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    dispatch_async(self.returnQueue, ^{
        [self.delegate controllerWillChangeContent:self];
    });
}

- (NSString *)       controller:(NSFetchedResultsController *)controller
sectionIndexTitleForSectionName:(NSString *)sectionName
{
    __block NSString *blockSectionName = nil;
    
    dispatch_sync(self.returnQueue, ^{
        blockSectionName = [self.delegate controller:self sectionIndexTitleForSectionName:sectionName];
    });
    
    return blockSectionName;
}

- (void)dealloc
{
    dispatch_release(self.returnQueue);
    [super dealloc];
}

@end
