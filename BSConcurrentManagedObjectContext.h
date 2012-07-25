//
//  MFConcurrentManagedObjectContext.h
//
//
//  Created by Brian on 7/24/12.
//  Copyright (c) 2012 Brian Semiglia. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface BSConcurrentManagedObjectContext : NSManagedObjectContext

@property (nonatomic, assign) BOOL shouldNotifyOtherContexts;
@property (nonatomic, assign) BOOL shouldListenForOtherContextChanges;
@property (nonatomic, retain) NSManagedObjectContext *parentContext;

- (void)executeFetchRequest:(NSFetchRequest *)request
      withCompletionHandler:(void (^)(NSArray *fetchedObjects))completionHandler;

- (void)saveObjectsUsingObjectIDs:(NSArray *)objectIDs
            withCompletionHandler:(void (^)(NSError *error))completionHandler;
@end
