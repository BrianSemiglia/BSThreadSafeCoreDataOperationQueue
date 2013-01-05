BSThreadSafeCoreDataController
==============================
A custom NSOperationQueue for non-blocking, thread-safe operations with Core Data. iOS 4+
- - -
Operations are submitted to a static, serial, background operations queue.
Operations are executed in the order they are submitted and block the operation queue.
Operations do not block the thread they were submitted from.
The managed object context can be accessed from any thread.
Accessing the context blocks the operation queue.

This approach allows for simple background saving that is thread safe.
This approach does not allow for concurrent operations that access the managed object context.


    - (void)sampleSave
    {
        [[BSThreadSafeContextController sharedInstance] performBlockWithSharedContext:^(NSManagedObjectContext *context)
        {
            NSLog(@"Saving...");
            NSEntityDescription *entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                                        inManagedObjectContext:context];

            NSError *error = nil;
            [context save:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Saved.");
            });
        }];
    }
    
    - (void)sampleFetch
    {
        [[BSThreadSafeContextController sharedInstance] performBlockWithSharedContext:^(NSManagedObjectContext *context)
        {
            NSLog(@"Fetching...");

            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:context];        
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
            
            request.entity = entity;
            request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            NSError *error = nil;
            NSArray *fetchedObjects = [context executeFetchRequest:request
                                                            error:&error];

            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSLog(@"Fetched %i items.", fetchedObjects.count);
                
                // Access the objects safely from another thread.
                NSLog(@"Sample: %@", fetchedObjects[0]);
            });
        }];
    }
