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