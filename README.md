BSThreadSafeManagedObjectContext
==============================
A custom NSManagedObjectContext for concurrent/asynchronous/threaded saving and fetching with Core Data. iOS 4+
- - -
BSThreadSafeManagedObjectContext serves as a proxy to it's underlying parent context. 
The parent context is created on demand the first time a thread-safe managed object context is created and remains a singleton for the remaining session. 
From then on any thread-safe contexts created save to that parent context. 
The parent context runs on a static serial NSOperationQueue in the background. 
This removes the need for a shared NSManagedObjectContext within your application delegate.
The thread-safe context also has the components for assigning it's perisistentStoreCoordinator within it. This was done for convenience and to ensure that the child and parent contexts are on the same page.

All saves and fetches are executed asynchronously but dispatched to a serial queue, ensuring that saves happen in the order that they were submitted. The completion
handler is run on the thread that it's method was called on.


    - (void)sampleSave
    {
        BSThreadSafeManagedObjectContext *context = [[BSThreadSafeManagedObjectContext alloc] init];
        [context performBlockOnParentContext:^(NSManagedObjectContext *parentContext)
        {
            NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" 
                                                                    inManagedObjectContext:parentContext];
            NSError *error = nil;
            [parentContext save:&error];
        }
        withCompletionHandler:^
        {
            
        }];
    
        [context release];
    }
    
    - (void)sampleFetch
    {
        BSThreadSafeManagedObjectContext *context = [[BSThreadSafeManagedObjectContext alloc] init];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSManagedObject *entity = [NSEntityDescription entityForName:@"Entity" 
                                              inManagedObjectContext:context];    
        request.entity = entity;
        
        // Completion handler will run on thread that this method is called from.
        // Make sure to call this method on the same thread that the context was created on.
        [context executeAsynchronousFetchRequest:request
                           withCompletionHandler:^(NSArray *fetchedObjects, NSError *error) {
                                NSLog(@"%@", fetchedObjects);
                           }];
        [context release];
    }