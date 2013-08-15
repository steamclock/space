//
//  Database.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Circle;

@interface Database : NSObject

+(Database*)sharedDatabase;

-(void)save;

-(Circle*)createCircle;
-(NSArray*)circles;

@end
