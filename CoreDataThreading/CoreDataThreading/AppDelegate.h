//
//  AppDelegate.h
//  CoreDataThreading
//
//  Created by Brian on 7/19/12.
//  Copyright (c) 2012 Brian. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;

@property (nonatomic, strong) NSManagedObjectContext *managedContextiOS5;
@property (nonatomic, strong) NSManagedObjectContext *managedContextIOS4;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *storeCoordinator;

@end
