//
//  Circle.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Circle : NSManagedObject

@property (nonatomic) float positionX;
@property (nonatomic) float positionY;

-(void)removeFromDatabase;

@end
