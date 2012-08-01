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

@interface BSConcurrentManagedObjectContext ()
@property (nonatomic, assign) BOOL notifyParentContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@end

@implementation BSConcurrentManagedObjectContext

@synthesize parentContext = _parentContext;
@synthesize operationQueue = _operationQueue;
@synthesize storeCoordinator = _storeCoordinator;
@synthesize managedObjectModel = _managedObjectModel;

- (void)executeAsynchronousFetchRequest:(NSFetchRequest *)request
                  withCompletionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler
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
                                            
                                            if (error) {
                                                dispatch_async(returnQueue, ^{
                                                    completionHandler(nil, error);
                                                });
                                                dispatch_release(returnQueue);
                                                return;
                                            }
                                            
                                            NSMutableArray *objectIDs = [[NSMutableArray alloc] initWithCapacity:fetchedObjectIDs.count];
                                            for (NSManagedObject *objectID in fetchedObjectIDs) {
                                                [objectIDs addObject:objectID];
                                            }
                                            
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

- (void)performAsynchronousBlockOnParentContext:(void (^)(NSManagedObjectContext *parentContext))block
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^
                                        {
                                            block(self.parentContext);
                                        }];
    
    blockOperation.threadPriority = 0;
    [self.operationQueue addOperation:blockOperation];
}

- (void)contextDidSaveWithNotification:(NSNotification *)notification
{
    if (!self.shouldListenForOtherContextChanges)
        return;
    
    NSManagedObjectContext *context = nil;
    
    if (self.notifyParentContext)
    {
        // Child saved, update parent.
        context = self.parentContext;
    }
    else
    {
        // Parent saved, update child.
        context = self;
        
        // Fault in all updated objects so any observing fetchControllers are notified of changes.
        NSArray* updates = [[notification.userInfo objectForKey:@"updated"] allObjects];
        for (NSInteger i = updates.count-1; i >= 0; i--)
            [[context objectWithID:[[updates objectAtIndex:i] objectID]] willAccessValueForKey:nil];
    }
    
    [context mergeChangesFromContextDidSaveNotification:notification];
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
        self.undoManager = nil;
        self.shouldListenForOtherContextChanges = YES;
        
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

- (BOOL)save:(NSError **)error
{
    // Context is saving.
    // Update parentContext to match.
    
    self.notifyParentContext = YES;
    [super save:error];
    self.notifyParentContext = NO;
    
    if (error)
        return NO;
    
    return YES;
}

@end