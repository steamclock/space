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

+(CGRect)frameWithCenterXByFactor:(CGFloat)xFactor
                   centerYByFactor:(CGFloat)yFactor
                             width:(CGFloat)frameWidth
                            height:(CGFloat)frameHeight
               withReferenceBounds:(CGRect)bounds {
    
    width = bounds.size.width;
    height = bounds.size.height;
    
    CGFloat centerXCoord = (width * xFactor) - (frameWidth/2.0);
    CGFloat centerYCoord = (height * yFactor) - (frameHeight/2.0);
    
    return CGRectMake(centerXCoord, centerYCoord, frameWidth, frameHeight);
}

+(CGFloat)normalizeXCoord:(CGFloat)xCoord withReferenceBounds:(CGRect)bounds {    
    return xCoord / bounds.size.width;
}

+(CGFloat)normalizeYCoord:(CGFloat)yCoord withReferenceBounds:(CGRect)bounds {
    return yCoord / bounds.size.height;
}

+(CGPoint)unnormalizePoint:(CGPoint)pointToUnnormalize withReferenceBounds:(CGRect)bounds {
    return CGPointMake(pointToUnnormalize.x * bounds.size.width, pointToUnnormalize.y * bounds.size.height);
}

@end
