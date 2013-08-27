//
//  CanvasSelectionViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-26.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasSelectionViewController.h"
#import "Notifications.h"

@interface CanvasSelectionViewController ()

@property UIToolbar* toolbar;
@property NSArray* buttons;

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
    NSMutableArray* buttons = [NSMutableArray new];
    
    for (NSString* name in canvasNames) {
        [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] ];
        
        UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStylePlain target:self action:@selector(buttonPress:)];
        [items addObject: button];
        [buttons addObject:button];
    }

    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] ];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil] ];
    
    self.toolbar.items = items;
    self.buttons = buttons;
}

-(IBAction)buttonPress:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification object:self userInfo:@{@"canvas":[NSNumber numberWithInt:[self.buttons indexOfObject:sender]]}];
}

@end
