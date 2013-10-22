//
//  FocusView.m
//  Space
//
//  Created by Jeremy Chiang on 2013-10-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "FocusView.h"
#import "Constants.h"

@interface FocusView()

@property (strong, nonatomic) UIBezierPath* circlePath;

@end

@implementation FocusView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGRect circleFrame = self.bounds;
        self.circlePath = [UIBezierPath bezierPathWithRoundedRect:circleFrame cornerRadius:Key_FocusSize];
    }
    return self;
}

// Ignores touches outside of the focus view's circle.
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [self.circlePath containsPoint:point];
}

@end
