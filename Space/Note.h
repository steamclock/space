//
//  Note.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Note : NSManagedObject

@property (nonatomic) int canvas;
@property (nonatomic) BOOL trashed;

@property (nonatomic) float positionX;
@property (nonatomic) float positionY;

@property (nonatomic) NSString* title;
@property (nonatomic) NSString* content;

-(void)markAsTrashed;
-(void)removeFromDatabase;

@end
