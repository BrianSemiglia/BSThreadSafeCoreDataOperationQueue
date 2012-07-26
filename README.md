ConcurrentManagedObjectContext
==============================
Custom NSManagedObjectContext for concurrent saving and fetching with Core Data.
--------------------------------------------------------------------------------

The first time a BSConcurrentManagedObjectContext is created, a singleton parent context is also created. From then on any BSConcurrentManagedObjectContext's created save to that parent context. The singleton parent context runs on a private serial queue in the background. This removes the need for a shared NSManagedObjectContext within your application delegate. A BSConcurrentManagedObjectContext has the components for assigning it's perisistentStoreCoordinator within it. This was done for convenience and to ensure that the child and parent contexts are on the same page.

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