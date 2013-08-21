//
//  SpaceViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "SpaceViewController.h"
#import "FocusViewController.h"
#import "Database.h"
#import "Circle.h"
#import "CircleView.h"

@interface SpaceViewController ()

@property (nonatomic) UIDynamicAnimator* animator;
@property (nonatomic) UIGravityBehavior* gravity;
@property (nonatomic) UICollisionBehavior* collision;
@property (nonatomic) UIDynamicItemBehavior* drag;

@property BOOL simulating;

@end

@implementation SpaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    self.gravity = [[UIGravityBehavior alloc] initWithItems:self.view.subviews];
    self.gravity.gravityDirection = CGVectorMake(0, 0);
    self.collision = [[UICollisionBehavior alloc] initWithItems:self.view.subviews];
    self.collision.translatesReferenceBoundsIntoBoundary = YES;
    
    [self.animator addBehavior:self.gravity];
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.drag];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spaceTap:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spaceDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGestureRecognizer];
    
    NSArray* circles = [[Database sharedDatabase] circles];
    
    for(Circle* circle in circles) {
        [self addViewForCircle:circle];
    }
}

-(void)circleTap: (UITapGestureRecognizer *)recognizer {
    CircleView* view = (CircleView*)recognizer.view;
    Circle* circle = view.circle;
    [self.focus focusOn:circle];
    
    /*
    [view removeFromSuperview];
    [circle removeFromDatabase];
    [self.gravity removeItem:view];
    [self.collision removeItem:view];
    [[Database sharedDatabase] save];*/
}

-(void)spaceDoubleTap:(UITapGestureRecognizer *)recognizer {
    self.gravity.gravityDirection = CGVectorMake(0, 1);
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
    
    CircleView* view = (CircleView*)recognizer.view;
    CGPoint drag = [recognizer locationInView:self.view];

    if(recognizer.state == UIGestureRecognizerStateBegan) {
        self.drag = [[UIDynamicItemBehavior alloc] init];
        self.drag.density = 1000000.0f;
        [self.drag addItem:view];
        [self.gravity removeItem:view];
    }
    
    view.center = CGPointMake(drag.x, drag.y);
    
    [self.animator updateItemUsingCurrentState:view];
    
    Circle* circle = view.circle;
    circle.positionX = drag.x;
    circle.positionY = drag.y;

    if(recognizer.state == UIGestureRecognizerStateEnded) {
        [self.gravity addItem:view];
        [self.drag removeItem:view];
        self.drag = nil;
        [[Database sharedDatabase] save];
    }
}

-(void)addViewForCircle:(Circle*)circle {
    CircleView* imageView = [[CircleView alloc] initWithImage:[UIImage imageNamed:@"Circle"]];
    imageView.center = CGPointMake(circle.positionX, circle.positionY);
    
    imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleTap:)];
    [imageView addGestureRecognizer:tapGestureRecognizer];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(circleDrag:)];
    [imageView addGestureRecognizer:panGestureRecognizer];
    
    imageView.circle = circle;

    [self.view addSubview:imageView];
    [self.gravity addItem:imageView];
    [self.collision addItem:imageView];
}
@end
