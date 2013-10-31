//
//  CanvasTitleEditPopover.m
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasMenuPopover.h"
#import "CanvasMenuViewController.h"
#import "Notifications.h"
#import "Constants.h"

@interface CanvasMenuPopover ()

// Canvas titles and indices are stored in NSUserDefaults.
@property (strong, nonatomic) NSUserDefaults* defaults;

@property (strong, nonatomic) CanvasMenuViewController* canvasMenuViewController;
@property (nonatomic) BOOL hasEditedTableView;

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
}

-(void)viewDidLayoutSubviews {
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.preferredContentSize = CGSizeMake(300.0f, 45 * [[self.defaults objectForKey:Key_CanvasTitles] count] + 120);
    NSLog(@"Popover size at viewDidLoad = %@", NSStringFromCGSize(self.preferredContentSize));
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
    [self.canvasMenuViewController setupMenuWithCanvasTitles:canvasTitles andIndices:canvasIndices];
    self.canvasMenuViewController.tableView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
    [self.view addSubview:self.canvasMenuViewController.view];
    
    UIView* staticHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 35)];
    staticHeaderView.backgroundColor = [UIColor whiteColor];
    
    UIButton* editButton = [UIButton buttonWithType:UIButtonTypeSystem];
    editButton.frame = CGRectMake(5, 5, 50, 25);
    [editButton setTitle:@"Edit" forState:UIControlStateNormal];
    [editButton addTarget:self action:@selector(editTableView) forControlEvents:UIControlEventTouchUpInside];
    [staticHeaderView addSubview:editButton];
    
    UIButton* addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    addButton.frame = CGRectMake(250, 5, 50, 25);
    addButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [addButton setTitle:@"+" forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(addCanvasButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [staticHeaderView addSubview:addButton];
    
    [self.view addSubview:staticHeaderView];
}

#pragma mark - Edit and Add Button Actions

-(void)editTableView {
    if (self.hasEditedTableView == NO) {
        [self.canvasMenuViewController setEditing:YES animated:YES];
        self.hasEditedTableView = YES;
    } else {
        [self.canvasMenuViewController setEditing:NO animated:YES];
        self.hasEditedTableView = NO;
    }
}

-(void)addCanvasButtonPressed {
    [self.canvasMenuViewController addCanvas];
}

#pragma mark - Update Popover Size

-(void)canvasAddedOrDeleted {
    self.preferredContentSize = CGSizeMake(300.0f, 60.0f * [[self.defaults objectForKey:Key_CanvasTitles] count] + 100);
}

@end
