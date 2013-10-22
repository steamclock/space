//
//  HelperMethods.h
//  Space
//
//  Created by Jeremy Chiang on 2013-10-10.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HelperMethods : NSObject

// Change this method's implmentation to quickly change the background circle colour for the focus view (text editor).
+(CGColorRef)backgroundCircleColour;

+(CAShapeLayer*)drawCircleInView:(UIView*)view;
+(CAShapeLayer*)drawFocusCircleInView:(UIView*)view;

@end
