//
//  DrawerViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-20.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "DrawerViewController.h"

@interface DrawerViewController () {
    CanvasViewController* _topDrawerContents;
    CanvasViewController* _bottomDrawerContents;
}

@property (nonatomic) UIView* topDragHandle;
@property (nonatomic) UIView* bottomDragHandle;
@property (nonatomic) CGPoint dragStart;
@property (nonatomic) float initialFrameY;
@property (nonatomic) BOOL haveLayedOut;

@property (nonatomic) BOOL allowDrag;
@property (nonatomic) float allowedDragStartY;
@property (nonatomic) BOOL allowedDragStartYAssigned;

//ipad is crazy here, so I'm caching the un-crazied numbers.
@property (nonatomic) CGSize realScreenSize;

@property (nonatomic) float maxY;
@property (nonatomic) float restY;
@property (nonatomic) float minY;

@property (nonatomic) float topDrawerHeight;
@property (nonatomic) float bottomDrawerHeight;
@property (nonatomic) float bottomDrawerStart;

@end

@implementation DrawerViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.topDragHandle = [[UIView alloc] init];
    self.bottomDragHandle = [[UIView alloc] init];

    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;


    self.topDragHandle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.topDragHandle.backgroundColor = [UIColor grayColor];

    [self.view addSubview:self.topDragHandle];

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

-(void)viewWillLayoutSubviews {
    //fix all our numbers for the current orientation, if necessary.

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;

    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        //fix the orientation because ipad is crazy
        float tmp = screenSize.height;
        screenSize.height = screenSize.width;
        screenSize.width = tmp;
    }

    NSLog(@"orientation: %d screen: %@", orientation, NSStringFromCGSize(screenSize));
    if (screenSize.height != self.realScreenSize.height) {
        [self updateExtentsForScreenSize:screenSize];
        [self updateViewSizes];
        [self updateCanvasSizes];
    }
}

-(void) updateExtentsForScreenSize:(CGSize)screenSize {
    self.realScreenSize = screenSize;


    //numbers relative to the view
    self.topDrawerHeight = screenSize.height - 24;
    self.bottomDrawerHeight = screenSize.height - 224;

    //numbers relative to the superview.
    self.maxY = 0;
    self.restY = 300 - screenSize.height;
    self.minY = self.restY - self.bottomDrawerHeight;

    //and this has to start wherever the bottom of the screen is
    self.bottomDrawerStart = screenSize.height - self.restY;

    NSLog(@"restY %f miny %f topDrawerHeight %f bottomDrawerHeight %f bottomDrawerStart %f", self.restY, self.minY, self.topDrawerHeight, self.bottomDrawerHeight, self.bottomDrawerStart);
}

-(void)updateViewSizes {
    int viewHeight = self.bottomDrawerStart + self.bottomDrawerHeight;
    self.view.frame = CGRectMake(0, self.restY, self.realScreenSize.width, viewHeight);

    int dragHeight = 40;
    int dragWidth = 200;
    float dragTop = self.topDrawerHeight - dragHeight - 5;
    float dragLeft = (self.view.bounds.size.width - dragWidth) / 2;
    float dragBottom = self.bottomDrawerStart - dragHeight - 50;

    self.topDragHandle.frame = CGRectMake(dragLeft, dragTop, dragWidth, dragHeight);
    self.bottomDragHandle.frame = CGRectMake(dragLeft, dragBottom, dragWidth, dragHeight);
}

-(void)updateCanvasSizes {
    [self updateTopCanvasSize];
    [self updateBottomCanvasSize];
}
-(void)updateTopCanvasSize {
    self.topDrawerContents.view.frame = CGRectMake(0, 0, self.realScreenSize.width, self.topDrawerHeight);
    [self.topDrawerContents updateNotesForBoundsChange];
    [self.topDrawerContents setYValuesWithTrashOffset:self.bottomDrawerStart];
}
-(void)updateBottomCanvasSize {
    self.bottomDrawerContents.view.frame = CGRectMake(0, self.bottomDrawerStart, self.realScreenSize.width, self.bottomDrawerHeight);
    [self.bottomDrawerContents updateNotesForBoundsChange];
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

-(void)setTopDrawerContents:(CanvasViewController *)contents {
    [_topDrawerContents removeFromParentViewController];
    [_topDrawerContents.view removeFromSuperview];
    _topDrawerContents = contents;
    
    if(_topDrawerContents) {
        [self addChildViewController:_topDrawerContents];
        [self.view addSubview:_topDrawerContents.view];
        [self.view bringSubviewToFront:self.topDragHandle];
        [self.view bringSubviewToFront:self.bottomDragHandle];
    }
}

-(CanvasViewController*)topDrawerContents {
    return _topDrawerContents;
}

-(void)setBottomDrawerContents:(CanvasViewController *)contents {
    [_bottomDrawerContents removeFromParentViewController];
    [_bottomDrawerContents.view removeFromSuperview];
    _bottomDrawerContents = contents;
    
    if(_bottomDrawerContents) {
        [self addChildViewController:_bottomDrawerContents];
        [self.view addSubview:_bottomDrawerContents.view];
        [self.view bringSubviewToFront:self.topDragHandle];
        [self.view bringSubviewToFront:self.bottomDragHandle];
    }
}

-(CanvasViewController*)bottomDrawerContents {
    return _bottomDrawerContents;
}
@end
