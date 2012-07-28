//
//  Entity.h
//  CoreDataThreading
//
//  Created by Brian on 7/28/12.
//  Copyright (c) 2012 Brian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Entity : NSManagedObject

@property (nonatomic, retain) NSString * title;

@end
