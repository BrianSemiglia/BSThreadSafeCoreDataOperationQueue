BSConcurrentManagedObjectContext
==============================
A custom NSManagedObjectContext for concurrent saving and fetching with Core Data. iOS 4+
- - -

BSConcurrentManagedObjectContext comes with its very own parent context baked into it. The parent context is created on demand the first time a BSCMOC is created and remains a singleton for the remaining session. From then on any BSCMOCs created save to that parent context. The parent context runs on a singleton serial NSOperationQueue (also baked in) in the background. This removes the need for a shared NSManagedObjectContext within your application delegate. A BSCMOC also has the components for assigning it's perisistentStoreCoordinator within it. This was done for convenience and to ensure that the child and parent contexts are on the same page.

All saves and fetches are executed asynchronously but dispatched to a serial queue, ensuring that saves happen in the order that they were submitted. The completion handler is run on the thread that it's method was called on.


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