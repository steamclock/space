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


@interface DrawerViewController () {
    UIViewController* _topDrawerContents;
    UIViewController* _bottomDrawerContents;
}

@property (nonatomic) UIView* topDragHandle;
@property (nonatomic) UIView* bottomDragHandle;
@property (nonatomic) CGPoint dragStart;
@property (nonatomic) float initialFrameY;
@property (nonatomic) BOOL haveLayedOut;

@property (nonatomic) BOOL allowDrag;
@property (nonatomic) float allowedDragStartY;
@property (nonatomic) BOOL allowedDragStartYAssigned;

@property (nonatomic) float maxY;
@property (nonatomic) float restY;
@property (nonatomic) float minY;

@property (nonatomic) float topDrawerHeight;
@property (nonatomic) float bottomDrawerHeight;
@property (nonatomic) float bottomDrawerStart;

@end

@implementation DrawerViewController

-(id)init {
    if (self = [super init]) {
        [self calculateDrawerExtents];
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];

    int viewHeight = self.bottomDrawerStart + self.bottomDrawerHeight;
    self.view.frame = CGRectMake(0, self.restY, ScreenWidth, viewHeight);
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    int dragHeight = 40;
    float dragTop = self.topDrawerHeight - dragHeight - 5;
    float dragLeft = (self.view.bounds.size.width / 2) - 100;
    float dragBottom = self.bottomDrawerStart - dragHeight - 50;

    
    self.topDragHandle = [[UIView alloc] initWithFrame:CGRectMake(dragLeft, dragTop, 200, dragHeight)];
    self.topDragHandle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.topDragHandle.backgroundColor = [UIColor grayColor];

    [self.view addSubview:self.topDragHandle];

    self.bottomDragHandle = [[UIView alloc] initWithFrame:CGRectMake(dragLeft, dragBottom, 200, dragHeight)];
    self.bottomDragHandle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.bottomDragHandle.backgroundColor = [UIColor grayColor];
    
    [self.view addSubview:self.bottomDragHandle];
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panningDrawer:)];
    [_topDrawerContents.view addGestureRecognizer:panGestureRecognizer];
    
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panningDrawer:)];
    [_bottomDrawerContents.view addGestureRecognizer:panGestureRecognizer];
    
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHandleMoved:)];
    [self.topDragHandle addGestureRecognizer:panGestureRecognizer];
    
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHandleMoved:)];
    [self.bottomDragHandle addGestureRecognizer:panGestureRecognizer];

}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self calculateDrawerExtents];
    //[self updateCanvasExtents];
}

-(void)calculateDrawerExtents {
    //numbers relative to the view
    self.topDrawerHeight = ScreenHeight - 24;
    self.bottomDrawerHeight = ScreenHeight - 224;

    //numbers relative to the superview.
    self.maxY = 0;
    self.restY = 300 - ScreenHeight;
    self.minY = self.restY - self.bottomDrawerHeight;

    //and this has to start wherever the bottom of the screen is
    self.bottomDrawerStart = ScreenHeight - self.restY;
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

-(void)panningDrawer:(UIPanGestureRecognizer*)recognizer {
    
    CGPoint touchPointRelativeToWindow = [recognizer locationInView:self.view.superview];
    CGPoint touchPointRelativeToDrawer = [recognizer locationInView:self.view];
    
    UIView* hitView = [self.view hitTest:touchPointRelativeToDrawer withEvent:nil];
    
    UIView* targetView;
    
    if ([recognizer.view isEqual:_topDrawerContents.view]) {
        targetView = self.topDragHandle;
    } else if ([recognizer.view isEqual:_bottomDrawerContents.view]) {
        targetView = self.bottomDragHandle;
    } else {
        targetView = nil;
    }
    
    if (hitView == targetView) {
        
        if (self.allowedDragStartYAssigned == NO) {
            self.allowedDragStartY = touchPointRelativeToWindow.y;
            self.allowedDragStartYAssigned = YES;
        }
        
        self.allowDrag = YES;
    }
    
    float newPosition;
    BOOL fromTopDrawer;
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        self.dragStart = touchPointRelativeToWindow;
        self.initialFrameY = self.view.frame.origin.y;
    }
    
    if (self.allowDrag) {
        newPosition = self.initialFrameY + (touchPointRelativeToWindow.y - self.allowedDragStartY);
    } else {
        newPosition = self.initialFrameY;
    }
    
    fromTopDrawer = [recognizer.view isEqual:_topDrawerContents.view];
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        self.allowDrag = NO;
        self.allowedDragStartYAssigned = NO;
        
        BOOL velocityDownwards = [recognizer velocityInView:self.view].y >= 0;
        
        if (fromTopDrawer && velocityDownwards) {
            newPosition = self.maxY;
        } else if (!fromTopDrawer && !velocityDownwards) {
            newPosition = self.minY;
        } else {
            newPosition = self.restY;
        }
        
        [self animateDrawerPosition:newPosition];
        
    } else {
        
        if ((fromTopDrawer && newPosition < self.restY) || (!fromTopDrawer && newPosition > self.restY)) {
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
        _topDrawerContents.view.frame = CGRectMake(0, 0, ScreenWidth, self.topDrawerHeight);
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
        _bottomDrawerContents.view.frame = CGRectMake(0, self.bottomDrawerStart, ScreenWidth, self.bottomDrawerHeight);
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
