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
        BSConcurrentManagedObjectContext *context = [[BSConcurrentManagedObjectContext alloc] init];
    
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entry" inManagedObjectContext:context];    
        request.entity = entity;
        
        // Results will be delivered back to thread that this method is called from.
        // Make sure the return context is created on same thread that you call this method from.
        [context executeAsynchronousFetchRequest:request
                              andReturnOnContext:context
                           withCompletionHandler:^(NSArray *fetchedObjects) {
                                NSLog(@"%@", fetchedObjects);
                           }];
        [context release];
    }