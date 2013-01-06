//
//  FetchedResultsViewController.h
//  CoreDataThreading
//
//  Created by Brian on 1/5/13.
//  Copyright (c) 2013 Brian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface FetchedResultsViewController : UIViewController
<
    UITableViewDataSource,
    UITableViewDelegate,
    NSFetchedResultsControllerDelegate
>

@end
