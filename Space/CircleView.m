//
//  CircleView.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CircleView.h"
#import "Circle.h"

@implementation CircleView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


-(void)setCenter:(CGPoint)center {
    [super setCenter:center];
    
    self.circle.positionX = center.x;
    self.circle.positionY = center.y;
}


@end
