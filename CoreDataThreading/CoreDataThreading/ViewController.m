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
             entity.title = [NSString stringWithFormat:@"title"];
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
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:self.context];
    request.entity = entity;
    
    [self.context executeAsynchronousFetchRequest:request
                            withCompletionHandler:^(NSArray *fetchedObjects, NSError *error){
                                dispatch_async(dispatch_get_main_queue(), ^
                                               {
                                                   NSLog(@"Fetched %i items.", fetchedObjects.count);
                                                   [self.fetchSpinner stopAnimating];
                                               });
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
