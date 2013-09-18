//
//  Coordinate.m
//  Space
//
//  Created by Jeremy Chiang on 2013-09-18.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "Coordinate.h"

@implementation Coordinate

static float width;
static float height;

+ (CGRect)frameWithCenterXByFactor:(CGFloat)xFactor
                   centerYByFactor:(CGFloat)yFactor
                             width:(CGFloat)frameWidth
                            height:(CGFloat)frameHeight
               withReferenceBounds:(CGRect)bounds {
    
    width = bounds.size.width;
    height = bounds.size.height;
    
    CGFloat centerXCoord = [Coordinate xCoordByFactor:xFactor] - (frameWidth/2.0);
    CGFloat centerYCoord = [Coordinate yCoordByFactor:yFactor] - (frameHeight/2.0);
    
    return CGRectMake(centerXCoord, centerYCoord, frameWidth, frameHeight);
}

+ (CGFloat)xCoordByFactor:(CGFloat)factor {
    
    return width * factor;
}

+ (CGFloat)yCoordByFactor:(CGFloat)factor {
    
    return height * factor;
}

@end
