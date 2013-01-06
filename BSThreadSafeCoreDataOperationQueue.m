//
//  BSThreadSafeCoreDataOperationQueue.m
//
//
//  Created by Brian Semiglia on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import "BSThreadSafeCoreDataOperationQueue.h"

@interface BSThreadSafeCoreDataOperationQueue ()
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
+ (NSManagedObjectModel *)managedObjectModel;
+ (NSURL *)applicationDocumentsDirectory;
@end

@implementation BSThreadSafeCoreDataOperationQueue

- (void)addOperationWithContext:(void (^)(NSManagedObjectContext *context))operation
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        operation([BSThreadSafeCoreDataOperationQueue managedObjectContext]);
    }];
    
    [self addOperation:blockOperation];
}

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static NSOperationQueue *sharedOperationQueue = nil;
    
    dispatch_once(&pred, ^{
        sharedOperationQueue = [[self alloc] init];
    });
    
    return sharedOperationQueue;
}

+ (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
    managedObjectContext.persistentStoreCoordinator = [BSThreadSafeCoreDataOperationQueue persistentStoreCoordinator];
    
    return managedObjectContext;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    // NSPersistentStoreCoordinators are not thread-safe but NSManagedObjectContexts lock them
    // when necessary so it's permissable to share the same coordinator across multiple threads.
    
    static NSPersistentStoreCoordinator *staticPersistentStoreCoordinator;
    if (staticPersistentStoreCoordinator)
        return staticPersistentStoreCoordinator;
    
    NSManagedObjectModel *model = [BSThreadSafeCoreDataOperationQueue managedObjectModel];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSURL *storeURL = [[BSThreadSafeCoreDataOperationQueue applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
    NSError *error = nil;

    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:nil
                                                          error:&error]) {
        return nil;
    }
    
    return persistentStoreCoordinator;
}

+ (NSManagedObjectModel *)managedObjectModel
{
    static NSManagedObjectModel *staticManagedObjectModel;
    if (staticManagedObjectModel)
        return staticManagedObjectModel;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    staticManagedObjectModel = managedObjectModel;
    
    return staticManagedObjectModel;
}

+ (NSURL *)applicationDocumentsDirectory
{
    static NSURL *staticApplicationDocumentsDirectory;
    if (staticApplicationDocumentsDirectory)
        return staticApplicationDocumentsDirectory;
    
    staticApplicationDocumentsDirectory =  [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                                   inDomains:NSUserDomainMask] lastObject];
    
    return staticApplicationDocumentsDirectory;
}

@end