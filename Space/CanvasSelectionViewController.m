//
//  CanvasSelectionViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-26.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasSelectionViewController.h"
#import "CanvasMenuPopover.h"
#import "PrototypingPopover.h"
#import "Notifications.h"
#import "Constants.h"

@interface CanvasSelectionViewController ()

@property UINavigationBar* menuBar;

@property (strong, nonatomic) UIPopoverController* canvasMenuPopoverController;
@property (strong, nonatomic) UIPopoverController* prototypingPopoverController;

@property (strong, nonatomic) NSUserDefaults* defaults;
@property (strong, nonatomic) UINavigationItem* menuItems;

@end

@implementation CanvasSelectionViewController

@synthesize canvasMenuPopoverController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        self.defaults = [NSUserDefaults standardUserDefaults];
        
        self.menuBar = [[UINavigationBar alloc] init];
        self.menuBar.translucent = NO;
        self.view = self.menuBar;
        
        Class popoverClass = NSClassFromString(@"UIPopoverController");
        
        if (popoverClass != nil && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            PrototypingPopover *prototypingPopover = [[PrototypingPopover alloc] init];
            self.prototypingPopoverController = [[UIPopoverController alloc] initWithContentViewController:prototypingPopover];
            prototypingPopover.popoverController = self.prototypingPopoverController;
            
            CanvasMenuPopover *canvasTitlePopover = [[CanvasMenuPopover alloc] init];
            self.canvasMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:canvasTitlePopover];
            canvasTitlePopover.popoverController = self.canvasMenuPopoverController;
            
            NSMutableArray* items = [[NSMutableArray alloc] init];
            
            // Allows toggling different prototyping options for easier experimentation
            [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"Prototyping" style:UIBarButtonItemStyleBordered target:self action:@selector(showPrototypingPopover:)]];
            
            [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"Canvases" style:UIBarButtonItemStyleBordered target:self action:@selector(showCanvasMenuPopover:)]];
            
            if ([self.defaults objectForKey:Key_CurrentCanvasIndex]) {
                
                NSMutableArray* canvasTitles = [self.defaults objectForKey:Key_CanvasTitles];
                NSMutableArray* canvasTitleIndices = [self.defaults objectForKey:Key_CanvasTitleIndices];
                
                int currentCanvas = [[self.defaults objectForKey:Key_CurrentCanvasIndex] intValue];
                NSString* currentTitle = [[self.defaults objectForKey:Key_CanvasTitles] objectAtIndex:currentCanvas];
                self.menuItems = [[UINavigationItem alloc] initWithTitle:currentTitle];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification
                                                                    object:self
                                                                  userInfo:@{Key_CanvasNumber:canvasTitleIndices[currentCanvas],
                                                                             Key_CanvasName:[canvasTitles objectAtIndex:currentCanvas]}];
                
            } else {
                
                self.menuItems = [[UINavigationItem alloc] initWithTitle:@"Canvas One"];
                
            }
            
            [self.menuItems setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Prototyping"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(showPrototypingPopover:)]];
            
            [self.menuItems setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Canvases"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(showCanvasMenuPopover:)]];
            
            [self.menuBar setItems:@[self.menuItems]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitle:) name:kCanvasChangedNotification object:nil];
        }
    }
    return self;
}

- (void)updateTitle:(NSNotification *)notification {
    
    self.menuItems.title = [notification.userInfo objectForKey:Key_CanvasName];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.view.frame = CGRectMake(0, 0, self.view.superview.bounds.size.width, 64);
    self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Tool Bar Button Actions

- (IBAction)showCanvasMenuPopover:(id)sender {
    
    [self.canvasMenuPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)showPrototypingPopover:(id)sender {
    
    [self.prototypingPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
