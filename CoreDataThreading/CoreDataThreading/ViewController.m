//
//  ViewController.m
//  CoreDataThreading
//
//  Created by Brian on 7/19/12.
//  Copyright (c) 2012 Brian. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "Entity.h"
#import "BSConcurrentManagedObjectContext.h"

@interface ViewController ()
@end

@implementation ViewController

- (IBAction)save:(id)sender
{
    [self.saveSpinner startAnimating];
    BSConcurrentManagedObjectContext *context = [[BSConcurrentManagedObjectContext alloc] init];
        
    [context performAsynchronousBlockOnParentContext:^(NSManagedObjectContext *parentContext)
    {
        NSMutableArray *objectIDs = [[[NSMutableArray alloc] initWithCapacity:1000] autorelease];
        for (int i = 0; i < 1000; i++)
        {
            Entity *entity = (Entity *)[NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                                   inManagedObjectContext:context];
            entity.title = [NSString stringWithFormat:@"title"];
            [objectIDs addObject:entity.objectID];
        }
        
        NSError *error = nil;
        [context save:&error];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"contextDidSaveNotification"
                                                            object:objectIDs];
        NSLog(@"%@", error ? error : @"Saved 1,000!");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.saveSpinner stopAnimating];
        });
    }];
    
    [context release];
}

- (IBAction)fetch:(id)sender
{
    [self.fetchSpinner startAnimating];
    BSConcurrentManagedObjectContext *context = [[BSConcurrentManagedObjectContext alloc] init];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:context];    
    request.entity = entity;
    
    [context executeAsynchronousFetchRequest:request
                       withCompletionHandler:^(NSArray *fetchedObjects, NSError *error) {
                           NSLog(@"Context fetch %i ITEMS", fetchedObjects.count);
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [self.fetchSpinner stopAnimating];
                           });
                       }];
    [request release];
    [context release];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
}

@end
