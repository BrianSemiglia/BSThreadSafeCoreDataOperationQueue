//
//  ViewController.h
//  CoreDataThreading
//
//  Created by Brian on 7/19/12.
//  Copyright (c) 2012 Brian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *fetchSpinner, *saveSpinner, *downloadSpinner;

- (IBAction)contextFetch:(id)sender;
- (IBAction)fetchedResultsControllerFetch:(id)sender;
- (IBAction)saveTenThousandItems:(id)sender;

@end
