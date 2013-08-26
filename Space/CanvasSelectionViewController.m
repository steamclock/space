//
//  CanvasSelectionViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-26.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasSelectionViewController.h"

@interface CanvasSelectionViewController ()

@property UIToolbar* toolbar;

@end

@implementation CanvasSelectionViewController



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.toolbar = [UIToolbar new];
        [self setupToolbarWithCanvasNames:@[@"One", @"Two"]];
        self.view = self.toolbar;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    
    self.view.frame = CGRectMake(0, 0, self.view.superview.bounds.size.width, 50);
    self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupToolbarWithCanvasNames:(NSArray*)canvasNames
{
    NSMutableArray* items = [NSMutableArray new];
    
    for (NSString* name in canvasNames) {
        [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] ];
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStylePlain target:nil action:nil] ];
    }

    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] ];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil] ];
    
    self.toolbar.items = items;
}

@end
