ConcurrentManagedObjectContext
==============================

Subclass of NSManagedObjectContext for concurrent saving and fetching with Core Data.

    - (void)sampleSave
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            BSConcurrentManagedObjectContext *context = [BSConcurrentManagedObjectContext alloc] init];
            NSEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:context];
        
            [context saveObjectsUsingObjectIDs:[NSArray arrayWithObject:entry.objectID]
                                 withCompletionHandler:^(NSError *error) {
                                    if (error)
                                        NSLog(@"%@" error);
                                 }];
            [context release];
        }
    }

    - (void)sampleFetch
    {
        MFConcurrentManagedObjectContext *context = [[MFConcurrentManagedObjectContext alloc] init];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entry" inManagedObjectContext:context];
        
        request.entity = entity;
        request.returnsObjectsAsFaults = YES;
        request.fetchBatchSize = 4;
        
        [context executeFetchRequest:request
               withCompletionHandler:^(NSArray *fetchedObjectIDs)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:fetchedObjectIDs.count];
                for (NSManagedObjectID *objectID in fetchedObjectIDs)
                {
                    [results addObject:[self.mainQueueContext objectWithID:objectID]];
                }
                
                // Returned results can now be accessed by the main thread.
            });
        }];
    }