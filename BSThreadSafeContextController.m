//
//  BSThreadSafeContextController.m
//
//
//  Created by Brian Semiglia on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import "BSThreadSafeContextController.h"

@interface BSThreadSafeContextController ()
@end

@implementation BSThreadSafeContextController

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static NSOperationQueue *sharedOperationQueue = nil;
    
    dispatch_once(&pred, ^{
        sharedOperationQueue = [[self alloc] init];
        sharedOperationQueue.maxConcurrentOperationCount = 1;
    });
    
    return sharedOperationQueue;
}


- (void)performBlockWithSharedContext:(void (^)(NSManagedObjectContext *context))block
{    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^
    {
        if (!self.managedObjectContext) {
            self.managedObjectContext = [[NSManagedObjectContext alloc] init];
            self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        }
        
        block(self.managedObjectContext);
    }];
    
    [self addOperation:blockOperation];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
    NSError *error = nil;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                         configuration:nil
                                                   URL:storeURL
                                               options:nil
                                                 error:&error]) {
        return nil;
    }
    
    return persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

#pragma mark - Context Builders

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

@end