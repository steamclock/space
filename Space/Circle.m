//
//  Circle.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "Circle.h"


@implementation Circle

@dynamic positionX;
@dynamic positionY;

-(void)removeFromDatabase {
    [self.managedObjectContext deleteObject:self];
}

@end
