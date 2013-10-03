//
//  DrawerViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-20.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "DrawerViewController.h"
#import "Notifications.h"
#import "Constants.h"

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

@property (nonatomic) float newPosition;

// iPad reports faulty screen size after orientation changes, so this stores the correct values.
@property (nonatomic) CGSize realScreenSize;

@property (nonatomic) float maxY;
@property (nonatomic) float restY;
@property (nonatomic) float minY;

@property (nonatomic) float topDrawerHeight;
@property (nonatomic) float bottomDrawerHeight;
@property (nonatomic) float bottomDrawerStart;

@property (nonatomic) BOOL layoutChangeRequested;
@property (nonatomic) BOOL isOriginalLayout;

@property (nonatomic) BOOL focusModeChangeRequested;
@property (nonatomic) BOOL isFocusModeDim;
@property (nonatomic) BOOL canvasesAreSlidOut;

@property (nonatomic) DragMode drawerDragMode;

@property (nonatomic) CGRect topCanvasFrameBeforeSlidingOut;

@property (strong, nonatomic) UIDynamicAnimator* animator;
@property (strong, nonatomic) UIDynamicItemBehavior* drawerBehavior;
@property (strong, nonatomic) UICollisionBehavior* collision;
@property (strong, nonatomic) UIGravityBehavior* gravity;

@property (nonatomic) BOOL hasLoaded;

@end

@implementation DrawerViewController

#pragma mark - Initial Setup

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    // Default prototype settings
    self.isOriginalLayout = YES;
    self.isFocusModeDim = YES;
    self.drawerDragMode = UIViewAnimation;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadOriginalDrawer) name:kLoadOriginalDrawerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadAlternativeDrawer) name:kLoadAlternativeDrawerNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slideOutCanvases) name:kFocusNoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slideBackCanvases) name:kFocusDismissedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFocusMode:) name:kChangeFocusModeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeDragMode:) name:kChangeDragModeNotification object:nil];

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

- (void)viewWillAppear:(BOOL)animated {
    
    // Load default settings for demo
    if (self.hasLoaded == NO) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoadAlternativeDrawerNotification object:nil];
        
        NSDictionary *dragMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:UIDynamicFreeSlidingWithGravity], @"dragMode", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kChangeDragModeNotification object:nil userInfo:dragMode];
        self.hasLoaded = YES;
    }
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
    [self drawCanvasLayout];
}

#pragma mark - Setup Top and Bottom Canvases

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

#pragma mark - UIDynamic

- (void)startPhysicsEngine {
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view.superview];
    self.animator.delegate = self;
    
    self.collision = [[UICollisionBehavior alloc] initWithItems:@[self.view]];
    self.collision.collisionDelegate = self;
    
    self.drawerBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.view]];
    self.drawerBehavior.resistance = 10;
    self.drawerBehavior.allowsRotation = NO;
    
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.drawerBehavior];
    
    if (self.drawerDragMode == UIDynamicFreeSlidingWithGravity) {
        self.drawerBehavior.density = self.view.frame.size.width * self.view.frame.size.height;
        self.drawerBehavior.elasticity = 0;
    }
}

- (void)stopPhysicsEngine {
    [self.animator removeAllBehaviors];
    self.animator = nil;
    self.collision = nil;
    self.drawerBehavior = nil;
    self.gravity = nil;
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    
    // When gravity is affecting the drawer, resistance is turned off to allow a smoother free-falling of the drawer,
    // so we'll restore resistance to our default value once the gravity is done animating
    if (self.drawerDragMode == UIDynamicFreeSlidingWithGravity) {
        self.drawerBehavior.resistance = 10;
        [self.animator removeBehavior:self.gravity];
        self.gravity = nil;
    }
}

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior
      beganContactForItem:(id<UIDynamicItem>)item
   withBoundaryIdentifier:(id<NSCopying>)identifier
                  atPoint:(CGPoint)p {
    
    // Resistance is set to 0 when gravity is taking place,
    // but we'll need to increase resistance to keep the bounce from gravity at collision under control
    if (self.drawerDragMode == UIDynamicFreeSlidingWithGravity) {
        self.drawerBehavior.resistance = 2.5;
    }
}

- (void)physicsForTopHandleDraggedDownwards {
    
    // If we're adding downward velocity to the top canvas, we want to create a boundary at the bottom to
    // prevent the top canvas from sliding out of sight
    if (![[self.collision boundaryIdentifiers] containsObject:@"topCanvasBottomBoundary"]) {
        [self.collision addBoundaryWithIdentifier:@"topCanvasBottomBoundary"
                                        fromPoint:CGPointMake(0, self.view.frame.size.height)
                                          toPoint:CGPointMake(self.view.frame.size.width, self.view.frame.size.height)];
    }
    
    int gravityTriggerThreshold = (self.isOriginalLayout) ? self.restY + 100 : -100;
    BOOL pastGravityThreshold;
    if (self.isOriginalLayout) {
        pastGravityThreshold = (self.newPosition > gravityTriggerThreshold) ? YES : NO;
    } else {
        pastGravityThreshold = (self.newPosition < gravityTriggerThreshold) ? YES : NO;
    }
    
    // Let gravity pull the drawer down when the drawer is dragged past a certain point
    if (self.drawerDragMode == UIDynamicFreeSlidingWithGravity && pastGravityThreshold) {
        
        self.drawerBehavior.resistance = 0;
        
        self.gravity = [[UIGravityBehavior alloc] initWithItems:@[self.view]];
        [self.gravity setMagnitude:5.0];
        [self.animator addBehavior:self.gravity];
    }
}

- (void)physicsForTopHandleDraggedUpwards {
    
    // If we're adding upward velocity to the top canvas, we want to create a boundary at the top to
    // prevent the top canvas from sliding out of sight
    if (![[self.collision boundaryIdentifiers] containsObject:@"topCanvasTopBoundary"]) {
        [self.collision addBoundaryWithIdentifier:@"topCanvasTopBoundary"
                                        fromPoint:CGPointMake(0, self.restY)
                                          toPoint:CGPointMake(self.view.frame.size.width, self.restY)];
    }
    
    int gravityTriggerThreshold = (self.isOriginalLayout) ? self.maxY - 100 : -700;
    BOOL pastGravityThreshold;
    if (self.isOriginalLayout) {
        pastGravityThreshold = (self.newPosition < gravityTriggerThreshold) ? YES : NO;
    } else {
        pastGravityThreshold = (self.newPosition > gravityTriggerThreshold) ? YES : NO;
    }
    
    // Let gravity pull the drawer up when the drawer is dragged past a certain point
    if (self.drawerDragMode == UIDynamicFreeSlidingWithGravity && pastGravityThreshold) {
        
        self.drawerBehavior.resistance = 0;
        
        self.gravity = [[UIGravityBehavior alloc] initWithItems:@[self.view]];
        [self.gravity setMagnitude:-5.0];
        [self.animator addBehavior:self.gravity];
    }
}

- (void)physicsForBottomHandleDraggedDownwards {
    
    if (![[self.collision boundaryIdentifiers] containsObject:@"bottomCanvasBottomBoundary"]) {
        
        if (self.isOriginalLayout) {
            [self.collision addBoundaryWithIdentifier:@"bottomCanvasBottomBoundary"
                                            fromPoint:CGPointMake(0, self.view.frame.size.height + self.restY)
                                              toPoint:CGPointMake(self.view.frame.size.width, self.view.frame.size.height + self.restY)];
        } else {
            [self.collision addBoundaryWithIdentifier:@"bottomCanvasBottomBoundary"
                                            fromPoint:CGPointMake(0, self.view.frame.size.height)
                                              toPoint:CGPointMake(self.view.frame.size.width, self.view.frame.size.height)];
        }
    }
    
    int gravityTriggerThreshold = (self.isOriginalLayout) ? self.minY + 100 : -100;
    BOOL pastGravityThreshold;
    if (self.isOriginalLayout) {
        pastGravityThreshold = (self.newPosition > gravityTriggerThreshold) ? YES : NO;
    } else {
        pastGravityThreshold = (self.newPosition < gravityTriggerThreshold) ? YES : NO;
    }
    
    // Let gravity pull the drawer down when the drawer is dragged past a certain point
    if (self.drawerDragMode == UIDynamicFreeSlidingWithGravity && pastGravityThreshold) {
        
        self.drawerBehavior.resistance = 0;
        
        self.gravity = [[UIGravityBehavior alloc] initWithItems:@[self.view]];
        [self.gravity setMagnitude:5.0];
        [self.animator addBehavior:self.gravity];
    }
}

- (void)physicsForBottomHandleDraggedUpwards {
    
    if (![[self.collision boundaryIdentifiers] containsObject:@"bottomCanvasTopBoundary"]) {
        
        if (self.isOriginalLayout) {
            [self.collision addBoundaryWithIdentifier:@"bottomCanvasTopBoundary"
                                            fromPoint:CGPointMake(0, self.minY)
                                              toPoint:CGPointMake(self.view.frame.size.width, self.minY)];
        } else {
            [self.collision addBoundaryWithIdentifier:@"bottomCanvasTopBoundary"
                                            fromPoint:CGPointMake(0, self.minY)
                                              toPoint:CGPointMake(self.view.frame.size.width, self.minY)];
        }
    }
    
    int gravityTriggerThreshold = (self.isOriginalLayout) ? self.maxY - 100 : self.minY + 100;
    BOOL pastGravityThreshold;
    if (self.isOriginalLayout) {
        pastGravityThreshold = (self.newPosition < gravityTriggerThreshold) ? YES : NO;
    } else {
        pastGravityThreshold = (self.newPosition > gravityTriggerThreshold) ? YES : NO;
    }
    
    // Let gravity pull the drawer up when the drawer is dragged past a certain point
    if (self.drawerDragMode == UIDynamicFreeSlidingWithGravity && pastGravityThreshold) {
        
        self.drawerBehavior.resistance = 0;
        
        self.gravity = [[UIGravityBehavior alloc] initWithItems:@[self.view]];
        [self.gravity setMagnitude:-5.0];
        [self.animator addBehavior:self.gravity];
    }
}

#pragma mark - Prototyping Options

- (void)changeFocusMode:(NSNotification *)notification {
    
    if ([[notification.userInfo objectForKey:@"focusMode"] isEqualToString:@"dim"]) {
        
        self.isFocusModeDim = YES;
        self.focusModeChangeRequested = YES;
        
        NSLog(@"Setting focus mode to dim.");
        
    } else {
        
        self.isFocusModeDim = NO;
        self.focusModeChangeRequested = YES;
        
        NSLog(@"Setting focus mode to slide.");
    }
}

- (void)changeDragMode:(NSNotification *)notification {
    
    self.drawerDragMode = [[notification.userInfo objectForKey:@"dragMode"] intValue];
    
    if (self.drawerDragMode == UIViewAnimation) {
        
        // Kill UIDynamics
        [self stopPhysicsEngine];
        
    } else {
        
        // Revive UIDynamics
        [self startPhysicsEngine];
    }
    
    NSLog(@"Drawer Drag Mode = %d", self.drawerDragMode);
}

- (void)loadOriginalDrawer {
    NSLog(@"Load original drawer.");
    
    if (self.drawerDragMode != UIViewAnimation) {
        [self stopPhysicsEngine];
    }
    
    self.layoutChangeRequested = YES;
    self.isOriginalLayout = YES;
    
    [self drawCanvasLayout];
    
    if (self.drawerDragMode != UIViewAnimation) {
        [self startPhysicsEngine];
    }
}

- (void)loadAlternativeDrawer {
    NSLog(@"Load alternative drawer.");
    
    if (self.drawerDragMode != UIViewAnimation) {
        [self stopPhysicsEngine];
    }
    
    self.layoutChangeRequested = YES;
    self.isOriginalLayout = NO;
    
    [self drawCanvasLayout];
    
    if (self.drawerDragMode != UIViewAnimation) {
        [self startPhysicsEngine];
    }
}

#pragma mark - Render Layout

-(void)drawCanvasLayout {
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        // Fix the iPad faulty screen size numbers due to a system bug in changing orientations
        float tmp = screenSize.height;
        screenSize.height = screenSize.width;
        screenSize.width = tmp;
    }
    
    NSLog(@"Orientation: %d Screen: %@", orientation, NSStringFromCGSize(screenSize));
    
    // Redraw the layout if orientation has changed, or if a layout change is requested by the user
    if (screenSize.height != self.realScreenSize.height || self.layoutChangeRequested) {
        [self updateExtentsForScreenSize:screenSize];
        [self updateViewSizes];
        [self updateCanvasSizes];
        
        self.layoutChangeRequested = NO;
    }
}

-(void)updateExtentsForScreenSize:(CGSize)screenSize {
    
    // Store the actual screen size so we can reference it later to fix an iPad system bug where it'll report the wrong
    // size after changes in orientation
    self.realScreenSize = screenSize;

    // Size of top and bottom canvas
    self.topDrawerHeight = screenSize.height - 24;
    self.bottomDrawerHeight = screenSize.height - 224;

    // When the drawer is pulled down all the way with the top canvas fully revealed, it will be resting at (0, 0)
    self.maxY = 0;
    
    // Resting position or initial position is when the top left corner of the drawer is up and outside the screen,
    // so that's why it's a negative value
    self.restY = 324 - screenSize.height;
    
    // When the drawer reveals the trash canvas, it is pulled up and outside the screen even more, and this represents
    // how far the drawer can be pulled up
    self.minY = self.restY - self.bottomDrawerHeight;
    
    // Bottom canvas starts at where the bottom of the screen is, so it's not visible initially
    self.bottomDrawerStart = screenSize.height - self.restY;
    
    // Update values for alternative layout
    if (self.isOriginalLayout == NO) {
        
        // The empty space between the top canvas and the bottom of the screen at resting position
        int bottomSpace = 100;
        
        // Alternative layout requires a different height for the top canvas, or else notes can get fly out of sight
        self.topDrawerHeight = screenSize.height - bottomSpace;
        
        // Resting position is with the canvas pulled all the way down
        self.restY = self.maxY;
        
        // Reupdate minY using new restY value so we can pull up the trash canvas to the proper height
        self.minY = self.restY - self.bottomDrawerHeight;
        
        // Bottom drawer starts right at the bottom of the screen in alternative layout
        self.bottomDrawerStart = screenSize.height;
    }
    
    NSLog(@"restY = %f minY = %f topDrawerHeight = %f bottomDrawerHeight = %f bottomDrawerStart = %f",
          self.restY, self.minY, self.topDrawerHeight, self.bottomDrawerHeight, self.bottomDrawerStart);
}

-(void)updateViewSizes {
    
    // Frames for original layout
    int viewHeight = self.bottomDrawerStart + self.bottomDrawerHeight;
    self.view.frame = CGRectMake(0, self.restY, self.realScreenSize.width, viewHeight);
    
    int dragHeight = 40;
    int dragWidth = 200;
    float dragTop = self.topDrawerHeight - dragHeight - 5;
    float dragLeft = (self.view.bounds.size.width - dragWidth) / 2;
    float dragBottom = self.bottomDrawerStart - dragHeight - 50;

    self.topDragHandle.frame = CGRectMake(dragLeft, dragTop, dragWidth, dragHeight);
    self.bottomDragHandle.frame = CGRectMake(dragLeft, dragBottom, dragWidth, dragHeight);
    
    // Update some frames for alternative layout
    if (self.isOriginalLayout == NO) {
        
        // Remove the top drag handle as it is not needed in the alternative layout
        self.topDragHandle.frame = CGRectZero;
    }
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

#pragma mark - Drag Animations

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
    
    NSLog(@"Drawer current Y = %f", self.view.frame.origin.y);
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
        
        [self.animator removeBehavior:self.gravity];
        self.gravity = nil;
        
        self.dragStart = drag;
        self.initialFrameY = self.view.frame.origin.y;
        
        // It is important to remove boundaries at the start of gesture or it'll be too late and the boundaries may
        // persist and cause weird glitches.
        if (self.drawerDragMode != UIViewAnimation) {
            if ([self.collision.boundaryIdentifiers count] > 0) {
                [self.collision removeAllBoundaries];
            }
        }
    }
    
    self.newPosition = self.initialFrameY + (drag.y - self.dragStart.y);
    // NSLog(@"newPosition = %f", self.newPosition);
    BOOL fromTopHandle = [recognizer.view isEqual:self.topDragHandle];
    
    // If dragged past a certain point, extend or hide the the canvas
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        BOOL velocityDownwards = [recognizer velocityInView:self.view].y >= 0;
        
        if (fromTopHandle && velocityDownwards) {
            
            if (self.drawerDragMode == UIViewAnimation) {
                self.newPosition = self.maxY;
            } else {
                [self physicsForTopHandleDraggedDownwards];
            }
            
        } else if (fromTopHandle && !velocityDownwards) {
            
            if (self.drawerDragMode == UIViewAnimation) {
                self.newPosition = self.restY;
            } else {
                [self physicsForTopHandleDraggedUpwards];
            }
        
        } else if (!fromTopHandle && velocityDownwards) { // Case for dragging the bottom canvas downward
            
            if (self.drawerDragMode == UIViewAnimation) {
                self.newPosition = self.restY;
            } else {
                [self physicsForBottomHandleDraggedDownwards];
            }
            
        } else if (!fromTopHandle && !velocityDownwards) { // Case for dragging the bottom canvas upward
            
            if (self.drawerDragMode == UIViewAnimation) {
                self.newPosition = self.minY;
            } else {
                [self physicsForBottomHandleDraggedUpwards];
            }
        
        }
        
        if (self.drawerDragMode == UIViewAnimation) {
            [self animateDrawerPosition:self.newPosition];
        }
        
        // Add throwable feel to the drawer
        if (self.drawerDragMode == UIDynamicFreeSliding || self.drawerDragMode == UIDynamicFreeSlidingWithGravity) {
            CGPoint verticalVelocity = [recognizer velocityInView:self.view.superview];
            verticalVelocity = CGPointMake(0, verticalVelocity.y);
        
            [self.drawerBehavior addLinearVelocity:verticalVelocity forItem:self.view];
        }
        
    } else { // If we did not drag past a certain point, continue updating canvas' new position based on current drag
    
        if ((fromTopHandle && self.newPosition < self.restY) || (!fromTopHandle && self.newPosition > self.restY)) {
            self.newPosition = self.restY;
        }
        
        [self setDrawerPosition:self.newPosition];
        
        if (self.drawerDragMode != UIViewAnimation) {
            [self.animator updateItemUsingCurrentState:self.view];
        }
    }
}

// Allows "catching" of the handle if a pan gesture started outside the handle
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

#pragma mark - Alternate Layout Sliding Logic

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if (self.drawerDragMode != UIViewAnimation) {
        // Prevents animator from overriding our custom updates to views that are needed for orientation changes
        [self stopPhysicsEngine];
    }
    
    // Hide the ugly and unnecessary animations when the slid-out canvas is updating its frames to fit the new orientations
    if (self.isFocusModeDim == NO && self.canvasesAreSlidOut == YES) {
        
        self.topDrawerContents.view.alpha = 0;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    // Update the frames of the slid-out canvas after a change in orientation to allow us to slide it back properly
    if (self.isFocusModeDim == NO && self.canvasesAreSlidOut == YES) {
        
        self.topCanvasFrameBeforeSlidingOut = self.topDrawerContents.view.frame;
        
        self.topDrawerContents.view.alpha = 1;
        
        CGRect destination = self.topDrawerContents.view.frame;
        
        if (self.view.frame.origin.y == 0) {
            destination.origin.y = -(self.realScreenSize.height);
        } else {
            destination.origin.y = -(self.restY + self.realScreenSize.height);
        }
        
        self.topDrawerContents.view.frame = destination;
    }
    
    if (self.drawerDragMode != UIViewAnimation) {
        // Restore animator with the updated views
        [self startPhysicsEngine];
    }
}

- (void)slideOutCanvases {
    
    // NSLog(@"Checking focus mode to see if drawer should slide out.");
    
    if (self.drawerDragMode != UIViewAnimation && self.isFocusModeDim == NO) {
        [self stopPhysicsEngine];
    }
    
    if (self.isFocusModeDim == NO && self.focusModeChangeRequested == YES) {
        
        NSLog(@"Focus mode is set to slide, slide out canvases now.");
        
        self.topCanvasFrameBeforeSlidingOut = self.topDrawerContents.view.frame;
        
        CGRect destination = self.topDrawerContents.view.frame;
        
        if (self.view.frame.origin.y == 0) {
            destination.origin.y = -(self.realScreenSize.height);
        } else {
            
            if (self.drawerDragMode == UIViewAnimation) {
                destination.origin.y = -(self.restY + self.realScreenSize.height);
            } else {
                 destination.origin.y = -(self.view.frame.origin.y + self.realScreenSize.height);
            }
        }
        
        [UIView animateWithDuration:1 animations:^{
            self.topDrawerContents.view.frame = destination;
            self.topDragHandle.alpha = 0;
        }];
        
        self.canvasesAreSlidOut = YES;
        
    } else {
        
        NSLog(@"Focus mode is set to dim, don't slide out canvases.");
        
    }
}

- (void)slideBackCanvases {
    
    if (self.isFocusModeDim == NO && !CGRectEqualToRect(self.topDrawerContents.view.frame, self.topCanvasFrameBeforeSlidingOut)) {
        
        [UIView animateWithDuration:1 animations:^{
            self.topDrawerContents.view.frame = self.topCanvasFrameBeforeSlidingOut;
            self.topDragHandle.alpha = 1;
        } completion:^(BOOL finished) {
            
            if (finished) {
                if (self.drawerDragMode != UIViewAnimation) {
                    [self startPhysicsEngine];
                }
            }
        }];
        
        self.canvasesAreSlidOut = NO;
    }
}

@end
