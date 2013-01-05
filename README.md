BSThreadSafeManagedObjectContext
==============================
A custom NSManagedObjectContext for non-blocking, thread-safe operations with Core Data. iOS 4+
- - -
BSThreadSafeManagedObjectContext serves as a read-only proxy to it's underlying parent context. 
The parent context is created on demand the first time a thread-safe managed object context is created and remains a singleton for the remaining session. 
From then on any thread-safe contexts created save to that parent context. 
The parent context runs on a static serial NSOperationQueue in the background. 
This removes the need for a shared NSManagedObjectContext within your application delegate.
The thread-safe context also has the components for assigning it's perisistentStoreCoordinator within it. This was done for convenience and to ensure that the child and parent contexts are on the same page.

All saves and fetches are executed asynchronously but dispatched to a serial queue, ensuring that saves happen in the order that they were submitted. The completion
handler is run on the thread that it's method was called on.

You might ask why you need the proxy context and not just an NSObject that contains a parent context.
A proxy context allows for the use of a NSFetchedResultsController.
A fetched results controller can only observe objects of a context that was created on the same thread.
Using a proxy context that reflects the state of it's parent context allows safe observation.


    - (void)sampleSave
    {
        [[BSThreadSafeContextController sharedInstance] performBlockWithSharedContext:^(NSManagedObjectContext *context)
        {
            Entity *entity = (Entity *)[NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                                     inManagedObjectContext:context];

            NSError *error = nil;
            [context save:&error];
            
            // Make sure to dispatch sync.
            // Dispatch async could cause the accessing thread to hang 
            // until operation queue has completed all of it's operations.
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"Save completed.");
            });
        }];
    }
    
    - (void)sampleFetch
    {
        BSThreadSafeManagedObjectContext *context = [[BSThreadSafeManagedObjectContext alloc] init];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSManagedObject *entity = [NSEntityDescription entityForName:@"Entity" 
                                              inManagedObjectContext:context];    
        request.entity = entity;
        
        // Completion handler will run on thread that this method is called from.
        [context executeAsynchronousFetchRequest:request
                           withCompletionHandler:^(NSArray *fetchedObjects, NSError *error) 
        {
            NSLog(@"%@", fetchedObjects);
        }];
        
        [context release];
    }
