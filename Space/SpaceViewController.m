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
#import "QBPopupMenu.h"

@interface SpaceViewController ()

@property (nonatomic) UIDynamicAnimator* animator;
@property (nonatomic) UIGravityBehavior* gravity;
@property (nonatomic) UICollisionBehavior* collision;
@property (nonatomic) UIDynamicItemBehavior* dynamicProperties;

@property (nonatomic) UIDynamicItemBehavior* activeDrag;

@property (nonatomic) BOOL simulating;

@property (nonatomic) CircleView* viewForMenu;

@end

@implementation SpaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    self.gravity = [[UIGravityBehavior alloc] init];
    self.gravity.gravityDirection = CGVectorMake(0, 0);
    self.collision = [[UICollisionBehavior alloc] init];
    self.collision.translatesReferenceBoundsIntoBoundary = YES;
    self.dynamicProperties = [[UIDynamicItemBehavior alloc] init];
    self.dynamicProperties.allowsRotation = NO;
    
    [self.animator addBehavior:self.gravity];
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.activeDrag];
    [self.animator addBehavior:self.dynamicProperties];

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
}

-(void)circleLongPress: (UITapGestureRecognizer *)recognizer {
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        CircleView* view = (CircleView*)recognizer.view;
        self.viewForMenu = view;
        
        QBPopupMenu* menu = [[QBPopupMenu alloc] init];
        menu.items = @[ [[QBPopupMenuItem alloc] initWithTitle:@"Delete" target:self action:@selector(circleMenuDelete:)] ];
        
        // Bleech. Gnarly dependancy on view hierarchy above this view to present the menu in the top level view, need to clean this up
        [menu showInView:self.view.superview.superview atPoint:CGPointMake(view.center.x, view.center.y + self.view.superview.frame.origin.y)];
    }
}

-(void)circleMenuDelete:(id)sender {
    Circle* circle = self.viewForMenu.circle;
    
    [circle removeFromDatabase];
    [[Database sharedDatabase] save];
    
    [self.gravity removeItem:self.viewForMenu];
    [self.collision removeItem:self.viewForMenu];
    [self.dynamicProperties removeItem:self.viewForMenu];
    
    [self.viewForMenu removeFromSuperview];
    self.viewForMenu = nil;
    
//    [sender dismiss];
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
        self.activeDrag = [[UIDynamicItemBehavior alloc] init];
        self.activeDrag.density = 1000000.0f;
        [self.activeDrag addItem:view];
        [self.gravity removeItem:view];
    }
    
    view.center = CGPointMake(drag.x, drag.y);
    
    [self.animator updateItemUsingCurrentState:view];
    
    Circle* circle = view.circle;
    circle.positionX = drag.x;
    circle.positionY = drag.y;

    if(recognizer.state == UIGestureRecognizerStateEnded) {
        [self.gravity addItem:view];
        [self.activeDrag removeItem:view];
        self.activeDrag = nil;
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
    
    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(circleLongPress:)];
    [imageView addGestureRecognizer:longPress];

    imageView.circle = circle;

    [self.view addSubview:imageView];
    [self.gravity addItem:imageView];
    [self.collision addItem:imageView];
    [self.dynamicProperties addItem:imageView];
}
@end
