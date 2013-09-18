//
//  Coordinate.h
//  Space
//
//
//
//  Created by Jeremy Chiang on 2013-09-18.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Coordinate : NSObject

+ (CGRect)frameWithCenterXByFactor:(CGFloat)xFactor
                   centerYByFactor:(CGFloat)yFactor
                             width:(CGFloat)width
                            height:(CGFloat)height
               withReferenceBounds:(CGRect)bounds;

+ (CGFloat)xCoordByFactor:(CGFloat)factor;
+ (CGFloat)yCoordByFactor:(CGFloat)factor;

@end
