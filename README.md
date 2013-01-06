BSThreadSafeCoreDataOperationQueue
==============================
A custom NSOperationQueue for concurrent, thread-safe operations with Core Data. iOS 4+
- - -
Operations are submitted to a static, shared, concurrent operations queue.
Operations are not guaranteed to run in any particular order.
Operations do not block the thread they were submitted from.
A managed object context is created for each operation.
The managed object context provided to the block can be access from any thread/queue but not concurrently.
The confinement of the MOC to the block makes it easy to manage accessing the context from only one thread/queue at a time.

    [[BSThreadSafeCoreDataOperationQueue sharedInstance] performBlockWithSharedContext:^(NSManagedObjectContext *context)
     {
         // 1. Allowed: SYNC operations submitted to other threads/queues.
         {
              // Operation will block until completed.
              // Safe to access context after operation.
 
              dispatch_sync(dispatch_get_main_queue(), ^{
                  // Access context on main queue.
              });
     
              [context message];
         }
 
         // 2. Disallowed: ASYNC operations submitted to other threads/queues BEFORE any additional messages to the context.
         {
              // Operation will not block.
              // Because of the message to context below the block, a situation is created 
              // where the context might be accessed by two different threads/queues at the same time.
 
              dispatch_async(dispatch_get_main_queue(), ^{
                  // Access context on main queue.
              });
     
              [context message];
         }
 
         // 3. Allowed: ASYNC operations submitted to other threads/queues AFTER any additional messages to the context.
         {
              // Operation will not block but is last to message context thus
              // guaranteeing the context will not be accessed by any other threads/queues.
              
              dispatch_async(dispatch_get_main_queue(), ^{
                  // Access context on main queue.
              });
 
              // No additional messages to the context.
         }
     }];

    - (void)sampleSave
    {
        [[BSThreadSafeContextController sharedInstance] addOperationWithContext:^(NSManagedObjectContext *context)
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
        [[BSThreadSafeContextController sharedInstance] addOperationWithContext:^(NSManagedObjectContext *context)
        {
            NSLog(@"Fetching...");

            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:context];        
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
            
            request.entity = entity;
            request.sortDescriptors = @[sortDescriptor];
            
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
