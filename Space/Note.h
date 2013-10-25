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

// The canvas to which this note belongs to.
@property (nonatomic) int canvas;

@property (nonatomic) BOOL recovering;

// Indicates whether this note is trashed or not.
@property (nonatomic) BOOL trashed;

// When a note is dragged to trash, its new coordinates within the trash canvas needs to be calculated differently,
// so this flag can help trigger that different handling logic.
@property (nonatomic) BOOL draggedToTrash;

// The coordinates for this note at the beginning of every new touch/drag, in unnormalized form.
@property (nonatomic) float originalX;
@property (nonatomic) float originalY;

// Most recent coordinates for this note, in normalized form.
@property (nonatomic) float positionX;
@property (nonatomic) float positionY;

@property (nonatomic) NSString* title;
@property (nonatomic) NSString* content;

-(void)markAsTrashed;
-(void)removeFromDatabase;

@end
