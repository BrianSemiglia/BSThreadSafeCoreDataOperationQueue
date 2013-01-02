//
//  BSConcurrentManagedObjectContext.m
//
//
//  Created by Brian Semiglia on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import "BSThreadSafeManagedObjectContext.h"

static NSOperationQueue *staticOperationQueue;
static NSManagedObjectContext *staticParentContext;

@interface BSThreadSafeManagedObjectContext ()
@property (nonatomic, assign) BOOL notifyParentContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation BSThreadSafeManagedObjectContext

- (void)executeAsynchronousFetchRequest:(NSFetchRequest *)request
                  withCompletionHandler:(FetchCompletionHandler)completionHandler
{
    dispatch_queue_t returnQueue = dispatch_get_current_queue();
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^
    {
        request.includesPropertyValues = NO;
        request.includesSubentities = NO;
        request.resultType = NSManagedObjectIDResultType;
        
        NSError *error = nil;
        NSArray *fetchedObjectIDs = [self.parentContext executeFetchRequest:request
                                                                      error:&error];
        
        if (error)
        {
            dispatch_async(returnQueue, ^
            {
                completionHandler(nil, error);
            });
            dispatch_release(returnQueue);
            return;
        }
        
        NSMutableArray *objectIDs = [[NSMutableArray alloc] initWithCapacity:fetchedObjectIDs.count];
        for (NSManagedObject *objectID in fetchedObjectIDs)
        {
            [objectIDs addObject:objectID];
        }
        
        // Deliver results immediately and allow operation queue to continue to next operation.
        dispatch_async(returnQueue, ^
        {
            NSMutableArray *results = [[[NSMutableArray alloc] initWithCapacity:fetchedObjectIDs.count] autorelease];
            for (NSManagedObjectID *objectID in objectIDs)
            {
                NSError *error = nil;
                NSManagedObject *object = [self existingObjectWithID:objectID
                                                               error:&error];
                
                if (!error)
                    [results addObject:object];
            }
            
            if (results.count == 0)
                results = nil;
            
            completionHandler(results, error);
        });
        
        [objectIDs release];
    }];
    dispatch_release(returnQueue);
    
    blockOperation.threadPriority = 0;
    [self.operationQueue addOperation:blockOperation];
}

- (void)performBlockOnParentContext:(ParentContextOperationBlock)block
              withCompletionHandler:(ParentContextOperationCompletionHandler)completionHandler
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^ {
        block(self.parentContext);
    }];
    
    dispatch_queue_t returnQueue = dispatch_get_current_queue();
    blockOperation.completionBlock = ^
    {
        dispatch_async(returnQueue, ^
        {
            completionHandler();
        });
    };
    [self.operationQueue addOperation:blockOperation];
}

- (void)contextDidSaveWithNotification:(NSNotification *)notification
{
    // Saves operation should only be performed on parent context.
    // This is just to double check that the saving context is the parent.
    if (notification.object == self.parentContext)
    {
        // Fault in all updated objects so any observing fetchControllers are notified of changes.
        NSArray* updates = [[notification.userInfo objectForKey:@"updated"] allObjects];
        for (NSInteger i = updates.count-1; i >= 0; i--)
            [[self objectWithID:[[updates objectAtIndex:i] objectID]] willAccessValueForKey:nil];
        
        [self mergeChangesFromContextDidSaveNotification:notification];
    }
}

#pragma mark - Custom Synthesizers

- (NSManagedObjectContext *)parentContext
{
    // A static parent context is created upon first call.
    // All child contexts save to the parent context.
    // The parent context then saves to disk.
    // The parent context runs on a serial queue on a background thread.
    
    if (staticParentContext != nil)
        return staticParentContext;
    
    staticParentContext = [[NSManagedObjectContext alloc] init];
    staticParentContext.persistentStoreCoordinator = self.storeCoordinator;
    staticParentContext.undoManager = self.undoManager;
    
    return staticParentContext;
}

- (NSOperationQueue *)operationQueue
{
    // Operation queue is static to ensure all operations run serially on one background queue.
    if (staticOperationQueue != nil)
        return staticOperationQueue;
    
    staticOperationQueue = [[NSOperationQueue alloc] init];
    staticOperationQueue.maxConcurrentOperationCount = 1;
    
    return staticOperationQueue;
}

#pragma mark - Initializers

- (id)init
{
    self = [super init];
    if (self)
    {
        self.persistentStoreCoordinator = self.storeCoordinator;        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSaveWithNotification:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
    }
    return self;
}

- (id)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)ct
{
    return [super initWithConcurrencyType:NSConfinementConcurrencyType];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:nil];
    
    [_managedObjectModel release];
    [_storeCoordinator release];
    [_operationQueue release];
    [_parentContext release];
    [super dealloc];
}

#pragma mark - Context Builders

- (NSPersistentStoreCoordinator *)storeCoordinator
{
    if (_storeCoordinator)
        return _storeCoordinator;
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
    NSError *error = nil;

    _storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                         configuration:nil
                                                   URL:storeURL
                                               options:nil
                                                 error:&error])
    {
        return nil;
    }
    
    return _storeCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}


- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
        return _managedObjectModel;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (BOOL)save:(NSError **)error
{
    NSAssert(@"Error: ", @"Use performBlockOnParentContext:WithCompletionHandler instead");
    return NO;
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request
                           error:(NSError **)error
{
    NSAssert(@"Error: ", @"Use executeAsynchronousFetchRequest:withCompletionHandler:");
    return nil;
}

@end