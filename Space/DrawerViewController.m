//
//  DrawerViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-20.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "DrawerViewController.h"

@interface DrawerViewController () {
    UIViewController* _contents;
}

@property (nonatomic) UIView* dragHandle;
@property (nonatomic) CGPoint dragStart;
@property (nonatomic) float initialFrameY;
@property (nonatomic) float minY;
@property (nonatomic) float maxY;
@property (nonatomic) BOOL haveLayedOut;

@end

@implementation DrawerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blueColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    float dragTop = self.view.bounds.size.height - 25;
    float dragLeft = (self.view.bounds.size.width / 2) - 50;
    
    self.dragHandle = [[UIView alloc] initWithFrame:CGRectMake(dragLeft, dragTop, 100, 20)];
    self.dragHandle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.dragHandle.backgroundColor = [UIColor redColor];

    [self.view addSubview:self.dragHandle];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHandleMoved:)];

    [self.dragHandle addGestureRecognizer:panGestureRecognizer];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self calculateDrawerExtents];
    [self setDrawerPosition:self.view.frame.origin.y];
}

-(void)calculateDrawerExtents {
    CGRect bounds = self.view.superview.bounds;
    
    self.maxY = -100;
    self.minY = -(bounds.size.height - 200);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if(!self.haveLayedOut) {
        self.haveLayedOut = YES;
        [self calculateDrawerExtents];
        [self setDrawerPosition:self.minY];
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

-(void)dragHandleMoved:(UIPanGestureRecognizer*)recognizer {
    CGPoint drag = [recognizer locationInView:self.view.superview];
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        self.dragStart = drag;
        self.initialFrameY = self.view.frame.origin.y;
        [self calculateDrawerExtents];
    }

    [self setDrawerPosition:self.initialFrameY + (drag.y - self.dragStart.y)];
}

-(void)setContents:(UIViewController *)contents {
    [_contents removeFromParentViewController];
    [contents.view removeFromSuperview];
    _contents = contents;
    if(contents) {
        [self addChildViewController:contents];
        [self.view addSubview:contents.view];
        [self.view bringSubviewToFront:self.dragHandle];
    }
}

-(UIViewController*)contents {
    return _contents;
}

@end