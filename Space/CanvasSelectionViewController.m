//
//  CanvasSelectionViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-26.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasSelectionViewController.h"
#import "CanvasMenuPopover.h"
#import "Notifications.h"
#import "Constants.h"

@interface CanvasSelectionViewController ()

@property UINavigationBar* menuBar;

@property (strong, nonatomic) UIPopoverController* canvasMenuPopoverController;

@property (strong, nonatomic) NSUserDefaults* defaults;
@property (strong, nonatomic) UINavigationItem* menuItems;

@end

@implementation CanvasSelectionViewController

@synthesize canvasMenuPopoverController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        // Helps retrieving canvas titles and indices later.
        self.defaults = [NSUserDefaults standardUserDefaults];
        
        self.menuBar = [[UINavigationBar alloc] init];
        self.menuBar.translucent = NO;
        self.view = self.menuBar;
        
        Class popoverClass = NSClassFromString(@"UIPopoverController");
        
        if (popoverClass != nil && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            CanvasMenuPopover *canvasMenuPopover = [[CanvasMenuPopover alloc] init];
            UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:canvasMenuPopover];
            self.canvasMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
            canvasMenuPopover.popoverController = self.canvasMenuPopoverController;
            
            if ([self.defaults objectForKey:Key_CurrentCanvasIndex]) {
                                
                // Grab current canvas title.
                int currentCanvas = [[self.defaults objectForKey:Key_CurrentCanvasIndex] intValue];
                NSString* currentTitle = [[self.defaults objectForKey:Key_CanvasTitles] objectAtIndex:currentCanvas];
                self.menuItems = [[UINavigationItem alloc] initWithTitle:currentTitle];
                
            }
                        
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

// Update the navigation bar title to show the name of the currently selected canvas
-(void)updateTitle:(NSNotification *)notification {
    self.menuItems.title = [notification.userInfo objectForKey:Key_CanvasName];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.frame = CGRectMake(0, 0, self.view.superview.bounds.size.width, Key_NavBarHeight);
    self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Show NavBar Popover

-(IBAction)showCanvasMenuPopover:(id)sender {
    [self.canvasMenuPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
