//
//  ViewController.m
//  CoreDataThreading
//
//  Created by Brian on 7/19/12.
//  Copyright (c) 2012 Brian. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Entity.h"
#import "BSConcurrentManagedObjectContext.h"

@interface ViewController ()
@property (nonatomic, strong) BSConcurrentManagedObjectContext *context;
@end

@implementation ViewController

@synthesize context = _context;
@synthesize fetchSpinner = _fetchSpinner;
@synthesize saveSpinner = _saveSpinner;

- (IBAction)save:(id)sender
{
    [self.saveSpinner startAnimating];
    
    [self.context performAsynchronousBlockOnParentContext:^(NSManagedObjectContext *parentContext)
     {
         NSInteger saveCount = 10000;
         NSMutableArray *objectIDs = [[NSMutableArray alloc] initWithCapacity:saveCount];
         for (int i = 0; i < saveCount; i++)
         {
             Entity *entity = (Entity *)[NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                                      inManagedObjectContext:parentContext];
             entity.title = [NSString stringWithFormat:@"%i", i];
             [objectIDs addObject:entity.objectID];
         }
         
         NSError *error = nil;
         [parentContext save:&error];
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"contextDidSaveNotification"
                                                             object:objectIDs];
         
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.saveSpinner stopAnimating];
             NSLog(@"%@", error ? error : [NSString stringWithFormat:@"Saved %i items.", objectIDs.count]);
         });
         
         [objectIDs release];
     }];
}

- (IBAction)fetch:(id)sender
{
    [self.fetchSpinner startAnimating];
    
    // Required parameters
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    request.entity = entity;
    
    // Optional parameters
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == 999 || title == 666"];
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
    request.predicate = predicate;
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    [self.context executeAsynchronousFetchRequest:request
                            withCompletionHandler:^(NSArray *fetchedObjects, NSError *error)
    {
        NSLog(@"Fetched %i items", fetchedObjects.count);
        
        Entity *entity = [fetchedObjects objectAtIndex:0];
        if (entity.isFault)
            NSLog(@"Entity is faulted!");

        [self.fetchSpinner stopAnimating];
    }];
    
    [request release];
}

- (BSConcurrentManagedObjectContext *)context
{
    if (_context)
        return _context;
    
    return _context = [[BSConcurrentManagedObjectContext alloc] init];
}

@end
