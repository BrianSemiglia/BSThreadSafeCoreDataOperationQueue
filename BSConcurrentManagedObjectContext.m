//
//  BSConcurrentManagedObjectContext.m
//  
//
//  Created by Brian Semiglia on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import "BSConcurrentManagedObjectContext.h"

static NSOperationQueue *staticOperationQueue;
static NSManagedObjectContext *staticParentContext;
static NSString *contextDidSaveNotification = @"contextDidSaveNotification";

@interface BSConcurrentManagedObjectContext ()
@property (nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@end

@implementation BSConcurrentManagedObjectContext

@synthesize parentContext = _parentContext;
@synthesize shouldListenForOtherContextChanges = _shouldListenForOtherContextChanges;
@synthesize shouldNotifyOtherContexts = _shouldNotifyOtherContexts;

- (void)executeAsynchronousFetchRequest:(NSFetchRequest *)request
                  withCompletionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    dispatch_queue_t returnQueue = dispatch_get_current_queue();
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^
    {
        NSError *error = nil;
        NSArray *fetchedObjects = [self.parentContext executeFetchRequest:request error:&error];
        
        if (error) {
            dispatch_async(returnQueue, ^{
                completionHandler(nil, error);
            });
            dispatch_release(returnQueue);
            return;
        }
        
        NSMutableArray *objectIDs = [[NSMutableArray alloc] initWithCapacity:fetchedObjects.count];
        for (NSManagedObject *object in fetchedObjects) {
            [objectIDs addObject:object.objectID];
        }
        
        dispatch_async(returnQueue, ^
        {
            NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:fetchedObjects.count];
            for (NSManagedObjectID *objectID in objectIDs) {
                [results addObject:[self objectWithID:objectID]];
            }
            
            completionHandler(results, error);
            [results release];
        });
    }];
    dispatch_release(returnQueue);
    
    blockOperation.threadPriority = 0;
    [self.operationQueue addOperation:blockOperation];
}

- (void)saveObjectsUsingObjectIDs:(NSArray *)objectIDs
            withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    dispatch_queue_t returnQueue = dispatch_get_current_queue();
    NSArray *objectIDsCopy = [[objectIDs copy] autorelease];
    
    NSError *error = nil;
    [self save:&error];
    
    if (error) {
        dispatch_async(returnQueue, ^{
            completionHandler(error);
        });
        dispatch_release(returnQueue);
        return;
    }
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^
    {
        if (self.shouldNotifyOtherContexts)
            for (NSManagedObjectID *objectID in objectIDsCopy)
                [[self.parentContext objectWithID:objectID] willAccessValueForKey:nil];

        [self.parentContext mergeChangesFromContextDidSaveNotification:[NSNotification notificationWithName:@"" object:objectIDs]];
        
        if (self.shouldNotifyOtherContexts) {
            // Self notifies all other child contexts of change but removes itself as a listener b/c self has already been updated for the changes
            self.shouldListenForOtherContextChanges = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:contextDidSaveNotification object:objectIDsCopy];
            self.shouldListenForOtherContextChanges = YES;
        }
        
        dispatch_async(returnQueue, ^{
            completionHandler(error);
        });
    }];
    
    dispatch_release(returnQueue);
    blockOperation.threadPriority = 0;
    [self.operationQueue addOperation:blockOperation];
}

- (void)contextDidSaveWithNotification:(NSNotification *)notification
{
    if (self.shouldListenForOtherContextChanges)
        [self mergeChangesFromContextDidSaveNotification:notification];
}

#pragma mark - Custom Synthesizers

- (void)createParentContext
{
    [self parentContext];
}

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

- (void)setShouldListenForOtherContextChanges:(BOOL)shouldListenForOtherContextChanges
{
    if (shouldListenForOtherContextChanges == YES)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSaveWithNotification:)
                                                     name:contextDidSaveNotification
                                                   object:nil];
    else
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:contextDidSaveNotification
                                                      object:nil];
}

#pragma mark - Initializers

- (id)init
{
    self = [super init];
    if (self)
    {
        self.persistentStoreCoordinator = self.storeCoordinator;
        self.undoManager = nil;
        self.shouldListenForOtherContextChanges = YES;
        self.shouldNotifyOtherContexts = YES;
        
        // Parent context must be created on the thread it will run on.
        NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{ [self createParentContext]; }];
        [self.operationQueue addOperations:[NSArray arrayWithObject:blockOperation] waitUntilFinished:YES];        
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
                                                    name:contextDidSaveNotification
                                                  object:nil];
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
                                                 error:&error]) {
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

@end
