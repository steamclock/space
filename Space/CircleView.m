//
//  CircleView.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CircleView.h"
#import "Circle.h"

@interface CircleView () {
    Circle* _circle;
}

@property UILabel* titleLabel;

@end

@implementation CircleView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) {
        [self commonSetup];
    }
    return self;
}

-(void)dealloc {
    [_circle removeObserver:self forKeyPath:@"title"];
}

-(void)commonSetup {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 20)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.titleLabel];
    self.clipsToBounds = NO;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"title"]) {
        self.titleLabel.text = self.circle.title;
    }
}

-(void)setCircle:(Circle *)circle {
    [_circle removeObserver:self forKeyPath:@"title"];
    _circle = circle;
    self.titleLabel.text = circle.title;
    [_circle addObserver:self forKeyPath:@"title" options:0 context:NULL];
}

-(Circle*)circle {
    return _circle;
}

-(void)setCenter:(CGPoint)center {
    [super setCenter:center];
    
    self.circle.positionX = center.x;
    self.circle.positionY = center.y;
}


@end
