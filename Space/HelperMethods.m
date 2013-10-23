//
//  HelperMethods.m
//  Space
//
//  Created by Jeremy Chiang on 2013-10-10.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "HelperMethods.h"
#import "Constants.h"

@implementation HelperMethods

+(CGColorRef)backgroundCircleColour {
    return [UIColor colorWithWhite:0.8 alpha:1].CGColor;
}

+(UIView*)drawCircleWithFrame:(CGRect)frame {
    
    UIView* circle = [[UIView alloc] initWithFrame:frame];
    circle.backgroundColor = [UIColor clearColor];
    
    CAShapeLayer* circleShape = [CAShapeLayer layer];
    
    CGRect circleFrame = circle.bounds;
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithRoundedRect:circleFrame cornerRadius:Key_NoteRadius];
    
    circleShape.path = circlePath.CGPath;
    
    circleShape.fillColor = [UIColor clearColor].CGColor;
    circleShape.strokeColor = [UIColor blackColor].CGColor;
    circleShape.lineWidth = 2.0f;
    
    circleShape.frame = circleFrame;
    
    [circle.layer addSublayer:circleShape];
    
    return circle;
}

+(CAShapeLayer*)drawCircleInView:(UIView*)view {
    UIView* circleView = [[UIView alloc] initWithFrame:view.frame];
    circleView.backgroundColor = [UIColor clearColor];
    [view addSubview:circleView];
    
    CAShapeLayer* circleShape = [CAShapeLayer layer];
    
    CGRect circleFrame = view.bounds;
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithRoundedRect:circleFrame cornerRadius:Key_NoteRadius];
    
    circleShape.path = circlePath.CGPath;
    circleShape.fillColor = [UIColor clearColor].CGColor;
    circleShape.strokeColor = [UIColor blackColor].CGColor;
    circleShape.lineWidth = 2.0f;
    circleShape.frame = view.bounds;
    
    [view.layer addSublayer:circleShape];
    
    return circleShape;
}

+(CAShapeLayer*)drawFocusCircleInView:(UIView*)view {
    UIView* circleView = [[UIView alloc] initWithFrame:view.frame];
    circleView.backgroundColor = [UIColor clearColor];
    [view addSubview:circleView];
    
    CAShapeLayer* circleShape = [CAShapeLayer layer];
    
    CGRect circleFrame = view.bounds;
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithRoundedRect:circleFrame cornerRadius:Key_FocusSize];
    
    circleShape.path = circlePath.CGPath;
    circleShape.fillColor = [HelperMethods backgroundCircleColour];
    circleShape.strokeColor = [UIColor blackColor].CGColor;
    circleShape.lineWidth = 0.0f;
    circleShape.frame = view.bounds;
    
    [view.layer addSublayer:circleShape];
    
    return circleShape;
}

@end
