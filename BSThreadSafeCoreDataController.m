//
//  BSThreadSafeContextController.m
//
//
//  Created by Brian Semiglia on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import "BSThreadSafeCoreDataController.h"

@interface BSThreadSafeCoreDataController ()
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
+ (NSManagedObjectModel *)managedObjectModel;
+ (NSURL *)applicationDocumentsDirectory;
@end

@implementation BSThreadSafeCoreDataController

- (void)performBlockWithSharedContext:(void (^)(NSManagedObjectContext *context))block
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^
    {
        block([BSThreadSafeCoreDataController managedObjectContext]);
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
    managedObjectContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
    
    return managedObjectContext;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{    
    NSManagedObjectModel *model = [BSThreadSafeCoreDataController managedObjectModel];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSURL *storeURL = [[BSThreadSafeCoreDataController applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
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
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

@end