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
#import "BSThreadSafeManagedObjectContext.h"

@interface ViewController ()
@property (nonatomic, strong) BSThreadSafeManagedObjectContext *context;
@end

@implementation ViewController

@synthesize context = _context;
@synthesize fetchSpinner = _fetchSpinner;
@synthesize saveSpinner = _saveSpinner;

- (IBAction)save:(id)sender
{
    [self.saveSpinner startAnimating];
    
    [self.context performBlockOnParentContextsQueue:^(NSManagedObjectContext *parentContext)
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@", error ? error : [NSString stringWithFormat:@"Saved %i items.", objectIDs.count]);
        });
        
        [objectIDs release];
    }
                              withCompletionHandler:^
    {
        [self.saveSpinner stopAnimating];
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
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    [self.context executeAsynchronousFetchRequest:request
                            withCompletionHandler:^(NSArray *fetchedObjects, NSError *error)
     {
         NSLog(@"Fetched %i items", fetchedObjects.count);
         [self.fetchSpinner stopAnimating];
     }];
    
    [request release];
}

- (BSThreadSafeManagedObjectContext *)context
{
    if (_context)
        return _context;
    
    return _context = [[BSThreadSafeManagedObjectContext alloc] init];
}

@end