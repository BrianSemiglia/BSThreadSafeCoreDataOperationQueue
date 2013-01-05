//
//  ViewController.m
//  CoreDataThreading
//
//  Created by Brian on 7/19/12.
//  Copyright (c) 2012 Brian. All rights reserved.
//

#import "ViewController.h"
#import "Entity.h"
#import "BSThreadSafeContextController.h"

@implementation ViewController

- (IBAction)save:(id)sender
{
    [self.saveSpinner startAnimating];

    [[BSThreadSafeContextController sharedInstance] performBlockWithSharedContext:^(NSManagedObjectContext *context)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.saveSpinner startAnimating];
        });

        NSLog(@"Saving...");
        NSInteger saveCount = 100000;
        
        for (int i = 0; i < saveCount; i++) {
            Entity *entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                           inManagedObjectContext:context];
            entity.title = [NSString stringWithFormat:@"%i", i];
        }
        
        NSError *error = nil;
        [context save:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Saved.");
            [self.saveSpinner stopAnimating];
        });
    }];
}

- (IBAction)fetch:(id)sender
{
    [self.fetchSpinner startAnimating];

    [[BSThreadSafeContextController sharedInstance] performBlockWithSharedContext:^(NSManagedObjectContext *context)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fetchSpinner startAnimating];
        });
        
        NSLog(@"Fetching...");
        // Required parameters
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
            [self.fetchSpinner stopAnimating];
            
            // Access the objects safely from another thread.
            NSLog(@"Sample: %@", fetchedObjects[0]);
        });
    }];
}

@end