//
//  DrawerViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-20.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "DrawerViewController.h"

//a bunch of constants to centralize and simplify the drawer geometry
//FIXME plenty of these should stop being consts soon.
static const int ScreenHeight = 1024;
static const int ScreenWidth = 768;

//numbers relative to the view
static const int TopDrawerHeight = 1000;
static const int BottomDrawerHeight = 800;
static const int SpaceBetweenDrawers = 748;

//numbers relative to the superview.
static const int restY = -724;
static const int minY = -1524;
static const int maxY = 0;

//generated numbers
static const int BottomDrawerStart = TopDrawerHeight + SpaceBetweenDrawers;


@interface DrawerViewController () {
    UIViewController* _topDrawerContents;
    UIViewController* _bottomDrawerContents;
}

@property (nonatomic) UIView* topDragHandle;
@property (nonatomic) UIView* bottomDragHandle;
@property (nonatomic) CGPoint dragStart;
@property (nonatomic) float initialFrameY;
@property (nonatomic) float minY;
@property (nonatomic) float restY;
@property (nonatomic) float maxY;
@property (nonatomic) BOOL haveLayedOut;

@end

@implementation DrawerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    int viewHeight = TopDrawerHeight + SpaceBetweenDrawers + BottomDrawerHeight;
    self.view.frame = CGRectMake(0, restY, ScreenWidth, viewHeight);
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    int dragHeight = 20;
    float dragTop = TopDrawerHeight - dragHeight - 5;
    float dragLeft = (self.view.bounds.size.width / 2) - 50;
    float dragBottom = BottomDrawerStart - dragHeight - 50;
    
    self.topDragHandle = [[UIView alloc] initWithFrame:CGRectMake(dragLeft, dragTop, 100, dragHeight)];
    self.topDragHandle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.topDragHandle.backgroundColor = [UIColor grayColor];

    [self.view addSubview:self.topDragHandle];

    self.bottomDragHandle = [[UIView alloc] initWithFrame:CGRectMake(dragLeft, dragBottom, 100, dragHeight)];
    self.bottomDragHandle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.bottomDragHandle.backgroundColor = [UIColor grayColor];
    
    [self.view addSubview:self.bottomDragHandle];

    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHandleMoved:)];
    [self.topDragHandle addGestureRecognizer:panGestureRecognizer];

    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHandleMoved:)];
    [self.bottomDragHandle addGestureRecognizer:panGestureRecognizer];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self calculateDrawerExtents];
    [self setDrawerPosition:self.view.frame.origin.y];
}

-(void)calculateDrawerExtents {
    //CGRect bounds = self.view.superview.bounds;

    self.restY = restY;
    self.maxY = maxY;
    self.minY = minY;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if(!self.haveLayedOut) {
        self.haveLayedOut = YES;
        // [self calculateDrawerExtents];
        // [self setDrawerPosition:self.maxY];
    }
}

-(void)setDrawerPosition:(float)positionY {
    
    CGRect frame = self.view.frame;
    frame.origin.y = positionY;
    
    if(frame.origin.y > self.maxY) {
        frame.origin.y = self.maxY;
    }
    else if(frame.origin.y < self.minY) {
        frame.origin.y = self.minY;
    }
    
    self.view.frame = frame;
}


-(void)animateDrawerPosition:(float)positionY {
    CGRect frame = self.view.frame;
    frame.origin.y = positionY;

    [UIView animateWithDuration:0.5 animations:^{
        self.view.frame = frame;
    }];
}

-(void)dragHandleMoved:(UIPanGestureRecognizer*)recognizer {
    
    CGPoint drag = [recognizer locationInView:self.view.superview];
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        self.dragStart = drag;
        self.initialFrameY = self.view.frame.origin.y;
        [self calculateDrawerExtents];
    }
    
    float newPosition = self.initialFrameY + (drag.y - self.dragStart.y);

    BOOL fromTopHandle = [recognizer.view isEqual:self.topDragHandle];

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        //animate to the appropriate end position

        BOOL velocityDownwards = [recognizer velocityInView:self.view].y >= 0;

        if (fromTopHandle && velocityDownwards) {
            newPosition = self.maxY;
        } else if (!fromTopHandle && !velocityDownwards) {
            newPosition = self.minY;
        } else {
            newPosition = self.restY;
        }

        [self animateDrawerPosition:newPosition];
    } else {
        //bound the drag based on the handle in use (it's not allowed to close past its rest position)

        if ((fromTopHandle && newPosition < self.restY) || (!fromTopHandle && newPosition > self.restY)) {
            newPosition = self.restY;
        }

        [self setDrawerPosition:newPosition];
    }

}

-(void)setTopDrawerContents:(UIViewController *)contents {
    [_topDrawerContents removeFromParentViewController];
    [_topDrawerContents.view removeFromSuperview];
    _topDrawerContents = contents;
    
    if(_topDrawerContents) {
        _topDrawerContents.view.frame = CGRectMake(0, 0, ScreenWidth, TopDrawerHeight);
        [self addChildViewController:_topDrawerContents];
        [self.view addSubview:_topDrawerContents.view];
        [self.view bringSubviewToFront:self.topDragHandle];
        [self.view bringSubviewToFront:self.bottomDragHandle];
    }
}

-(UIViewController*)topDrawerContents {
    return _topDrawerContents;
}

-(void)setBottomDrawerContents:(UIViewController *)contents {
    [_bottomDrawerContents removeFromParentViewController];
    [_bottomDrawerContents.view removeFromSuperview];
    _bottomDrawerContents = contents;
    
    if(_bottomDrawerContents) {
        _bottomDrawerContents.view.frame = CGRectMake(0, BottomDrawerStart, ScreenWidth, BottomDrawerHeight);
        [self addChildViewController:_bottomDrawerContents];
        [self.view addSubview:_bottomDrawerContents.view];
        [self.view bringSubviewToFront:self.topDragHandle];
        [self.view bringSubviewToFront:self.bottomDragHandle];
    }
}

-(UIViewController*)bottomDrawerContents {
    return _bottomDrawerContents;
}
@end
