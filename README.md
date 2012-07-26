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
        
        // Completion handler will run on thread that this method is called from.
        // Make sure to call this method on the same thread that the context was created on.
        [context executeAsynchronousFetchRequest:request
                           withCompletionHandler:^(NSArray *fetchedObjects) {
                                NSLog(@"%@", fetchedObjects);
                           }];
        [context release];
    }