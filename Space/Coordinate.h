//
//  Coordinate.h
//  Space
//
//  Created by Jeremy Chiang on 2013-09-18.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//
//  This class primarily calculates normalized and unnormalized coordinates for the note circle views.
//

#import <Foundation/Foundation.h>

@interface Coordinate : NSObject

// Helps position a view relatively by creating a frame and pinning its center to the specified coordinate.
// (0.5, 0.5) will center the view in the middle of the reference bounds.
+(CGRect)frameWithCenterXByFactor:(CGFloat)xFactor
                   centerYByFactor:(CGFloat)yFactor
                             width:(CGFloat)width
                            height:(CGFloat)height
               withReferenceBounds:(CGRect)bounds;

+(CGFloat)normalizeXCoord:(CGFloat)xCoord withReferenceBounds:(CGRect)bounds;
+(CGFloat)normalizeYCoord:(CGFloat)yCoord withReferenceBounds:(CGRect)bounds;
+(CGPoint)unnormalizePoint:(CGPoint)pointToUnnormalize withReferenceBounds:(CGRect)bounds;

@end
