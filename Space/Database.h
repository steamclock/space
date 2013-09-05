//
//  Database.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Note.h"

@interface Database : NSObject

+(Database*)sharedDatabase;

-(void)save;
-(void)deleteAllNotesInCanvas:(int)canvas;

-(Note*)createNote;
-(NSArray*)notesInCanvas:(int)canvas;
-(NSArray*)trashedNotesInCanvas:(int)canvas;

@end
