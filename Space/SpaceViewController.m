//
//  SpaceViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "SpaceViewController.h"
#import "Database.h"
#import "Circle.h"

#import <objc/objc-runtime.h>

static char associatedObjectKey;

@interface SpaceViewController ()

@end

@implementation SpaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spaceTap:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    NSArray* circles = [[Database sharedDatabase] circles];
    
    for(Circle* circle in circles) {
        [self addViewForCircle:circle];
    }
}

-(void)circleTap: (UITapGestureRecognizer *)recognizer {
    UIView* view = recognizer.view;
    Circle* circle = objc_getAssociatedObject(view, &associatedObjectKey);
    [view removeFromSuperview];
    [circle removeFromDatabase];
    [[Database sharedDatabase] save];
}

-(void)spaceTap:(UITapGestureRecognizer *)recognizer {
    Circle* circle = [[Database sharedDatabase] createCircle];
    
    CGPoint position = [recognizer locationInView:self.view];
    
    circle.positionX = position.x;
    circle.positionY = position.y;

    [self addViewForCircle:circle];
    
    [[Database sharedDatabase] save];
}

-(void)circleDrag:(UIPanGestureRecognizer*)recognizer {
    UIView* view = recognizer.view;
    CGPoint drag = [recognizer locationInView:self.view];
    view.frame = CGRectMake(drag.x - (view.frame.size.width / 2), drag.y - (view.frame.size.height / 2), view.frame.size.width, view.frame.size.height);
    
    Circle* circle = objc_getAssociatedObject(view, &associatedObjectKey);
    circle.positionX = drag.x;
    circle.positionY = drag.y;
    
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        [[Database sharedDatabase] save];
    }
}

-(void)addViewForCircle:(Circle*)circle {
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Circle"]];
    imageView.frame = CGRectOffset(imageView.frame, circle.positionX - (imageView.frame.size.width / 2), circle.positionY - (imageView.frame.size.height / 2));
    
    imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleTap:)];
    [imageView addGestureRecognizer:tapGestureRecognizer];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(circleDrag:)];
    [imageView addGestureRecognizer:panGestureRecognizer];
    
    objc_setAssociatedObject(imageView, &associatedObjectKey, circle, OBJC_ASSOCIATION_RETAIN);

    [self.view addSubview:imageView];
}
@end
