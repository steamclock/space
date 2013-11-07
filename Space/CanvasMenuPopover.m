//
//  CanvasTitleEditPopover.m
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasMenuPopover.h"
#import "CanvasMenuViewController.h"
#import "AboutViewController.h"
#import "Notifications.h"
#import "Constants.h"

@interface CanvasMenuPopover ()

// Canvas titles and indices are stored in NSUserDefaults.
@property (strong, nonatomic) NSUserDefaults* defaults;

@property (strong, nonatomic) CanvasMenuViewController* canvasMenuViewController;

@property (strong, nonatomic) UIBarButtonItem* addButton;

@property (strong, nonatomic) UIColor* defaultTintColor;

@property (strong, nonatomic) UIStoryboard* aboutPageStoryboard;
@property (strong, nonatomic) AboutViewController* aboutPageViewController;

@end

@implementation CanvasMenuPopover

@synthesize popoverController;

-(id)init {
    if (self = [super init]) {
        
        self.defaults = [NSUserDefaults standardUserDefaults];
        
        if ([self.defaults objectForKey:Key_CanvasTitles] && [self.defaults objectForKey:Key_CanvasTitleIndices]) {
            
            // Load available canvases.
            [self initializeMenuWithCanvasTitles:[self.defaults objectForKey:Key_CanvasTitles]
                                      andIndices:[self.defaults objectForKey:Key_CanvasTitleIndices]];
            
        } else {
            
            // If there are no canvases stored, initilalize two default ones.
            [self initializeMenuWithCanvasTitles:@[@"Canvas One", @"Canvas Two"]
                                      andIndices:@[@0, @1]];
            
            [self.defaults setObject:@[@"Canvas One", @"Canvas Two"] forKey:Key_CanvasTitles];
            [self.defaults setObject:@[@0, @1] forKey:Key_CanvasTitleIndices];
            [self.defaults setObject:[NSNumber numberWithInt:0] forKey:Key_CurrentCanvasIndex];
            [self.defaults synchronize];
        }
    }
    
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canvasAddedOrDeleted) name:kCanvasAddedorDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableAddButton) name:kDisableAddButtonNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableAddButton) name:kEnableAddButtonNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPopover) name:kDismissPopoverNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAboutPage) name:kShowAboutPageNotification object:nil];
    
    self.defaultTintColor = [[[[UIApplication sharedApplication] delegate] window] tintColor];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTableView)];
    
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCanvasButtonPressed)];
    
    self.addButton = self.navigationItem.rightBarButtonItem;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewDidLayoutSubviews {
    self.preferredContentSize = CGSizeMake(300.0f, 45 * [[self.defaults objectForKey:Key_CanvasTitles] count] + 125);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Initialize Canvas Menu

-(void)initializeMenuWithCanvasTitles:(NSArray *)canvasTitles andIndices:(NSArray *)canvasIndices {
    // Test tableview
    self.canvasMenuViewController = [CanvasMenuViewController canvasMenuViewController];
    self.canvasMenuViewController.view.frame = self.view.frame;
    [self.canvasMenuViewController setupMenuWithCanvasTitles:canvasTitles andIndices:canvasIndices];
    
    [self.view addSubview:self.canvasMenuViewController.view];
}

#pragma mark - Edit and Add Button Actions

-(void)editTableView {
    if (self.canvasMenuViewController.isEditingTableView == NO) {
        [self.canvasMenuViewController setEditing:YES animated:YES];
        self.canvasMenuViewController.isEditingTableView = YES;
    } else {
        [self.canvasMenuViewController setEditing:NO animated:YES];
        self.canvasMenuViewController.isEditingTableView = NO;
    }
}

-(void)addCanvasButtonPressed {
    [self.canvasMenuViewController addCanvas];
}

-(void)enableAddButton {
    self.addButton.tintColor = self.defaultTintColor;
}

-(void)disableAddButton {
    self.addButton.tintColor = [UIColor lightGrayColor];
}

#pragma mark - Update Popover Size

-(void)canvasAddedOrDeleted {
    [self.view setNeedsLayout];
}

#pragma mark - Dismiss Popover Programmatically

-(void)dismissPopover {
    if ([self.popoverController isPopoverVisible]) {
        [self.popoverController dismissPopoverAnimated:NO];
    }
}

#pragma mark - Show About Page

-(void)showAboutPage {
    if (self.aboutPageStoryboard == nil) {
        self.aboutPageStoryboard = [UIStoryboard storyboardWithName:@"AboutPage" bundle:nil];
        self.aboutPageViewController = [self.aboutPageStoryboard instantiateInitialViewController];
    }
    
    [self.navigationController pushViewController:self.aboutPageViewController animated:YES];
}

@end
