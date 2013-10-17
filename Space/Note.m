//
//  Note.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "Note.h"


@implementation Note

@dynamic canvas, content, contentData, originalX, originalY, positionX, positionY, title, trashed, draggedToTrash;

-(void)markAsTrashed {
    self.trashed = YES;
}

-(void)removeFromDatabase {
    [self.managedObjectContext deleteObject:self];
}

@end
