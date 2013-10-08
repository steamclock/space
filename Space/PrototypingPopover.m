//
//  PrototypingPopover.m
//  Space
//
//  Created by Jeremy Chiang on 2013-09-24.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "PrototypingPopover.h"
#import "Notifications.h"
#import "Constants.h"

@interface PrototypingPopover ()

@property (strong, nonatomic) UIActionSheet* drawerLayoutSelection;
@property (strong, nonatomic) UIActionSheet* focusModeSelection;
@property (strong, nonatomic) UIActionSheet* dragModeSelection;

@property (strong, nonatomic) UIButton* layoutButton;
@property (strong, nonatomic) UIButton* focusButton;
@property (strong, nonatomic) UIButton* dragButton;

@end

@implementation PrototypingPopover

@synthesize popoverController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.layoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.layoutButton setTitle:@"Layout: 2 Sections" forState:UIControlStateNormal];
    self.layoutButton.titleLabel.font = [UIFont systemFontOfSize:20];
    CGRect layoutButtonFrame = CGRectMake(5, 10, 300, 50);
    self.layoutButton.frame = layoutButtonFrame;
    [self.layoutButton addTarget:self action:@selector(showDrawerLayoutSelection) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.focusButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.focusButton setTitle:@"Focus: Dimming" forState:UIControlStateNormal];
    self.focusButton.titleLabel.font = [UIFont systemFontOfSize:20];
    CGRect focusButtonFrame = CGRectMake(5, 80, 300, 50);
    self.focusButton.frame = focusButtonFrame;
    [self.focusButton addTarget:self action:@selector(showFocusModeSelection) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.dragButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.dragButton setTitle:@"Drag: Gravity" forState:UIControlStateNormal];
    self.dragButton.titleLabel.font = [UIFont systemFontOfSize:20];
    CGRect dragButtonFrame = CGRectMake(5, 150, 300, 50);
    self.dragButton.frame = dragButtonFrame;
    [self.dragButton addTarget:self action:@selector(showDragModeSelection) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.view addSubview:self.layoutButton];
    [self.view addSubview:self.focusButton];
    [self.view addSubview:self.dragButton];
}

- (void)showDrawerLayoutSelection {
    
    self.drawerLayoutSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Drawer Layout"
                                                             delegate:(id<UIActionSheetDelegate>)self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"3 Sections", @"2 Sections", nil];
    [self.drawerLayoutSelection showInView:self.view];
}

- (void)showFocusModeSelection {
    
    self.focusModeSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Focus Mode"
                                                          delegate:(id<UIActionSheetDelegate>)self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Dimming", @"Slide Out", nil];
    [self.focusModeSelection showInView:self.view];
}

- (void)showDragModeSelection {
    
    self.dragModeSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Drag Mode"
                                                          delegate:(id<UIActionSheetDelegate>)self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Basic Animation", @"Free Sliding", @"Gravity", nil];
    [self.dragModeSelection showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet == self.drawerLayoutSelection) {
        
        if (buttonIndex == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoadThreeSectionsLayoutNotification object:nil];
            [self.layoutButton setTitle:@"Layout: 3 Sections" forState:UIControlStateNormal];
        } else if (buttonIndex == 1) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoadTwoSectionsLayoutNotification object:nil];
            [self.layoutButton setTitle:@"Layout: 2 Sections" forState:UIControlStateNormal];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLayoutChangedNotification object:nil];
        
    } else if (actionSheet == self.focusModeSelection) {
        
        if (buttonIndex == 0) {
            NSDictionary *focusMode = [[NSDictionary alloc] initWithObjectsAndKeys:@"dim", @"focusMode", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeFocusModeNotification object:nil userInfo:focusMode];
            [self.focusButton setTitle:@"Focus: Dimming" forState:UIControlStateNormal];
        } else if (buttonIndex == 1) {
            NSDictionary *focusMode = [[NSDictionary alloc] initWithObjectsAndKeys:@"slide", @"focusMode", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeFocusModeNotification object:nil userInfo:focusMode];
            [self.focusButton setTitle:@"Focus: Slide Out" forState:UIControlStateNormal];
        }
        
    } else if (actionSheet == self.dragModeSelection) {
        
        if (buttonIndex == 0) {
            NSDictionary *dragMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:UIViewAnimation], @"dragMode", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeDragModeNotification object:nil userInfo:dragMode];
            [self.dragButton setTitle:@"Drag: Basic Animation" forState:UIControlStateNormal];
        } else if (buttonIndex == 1) {
            NSDictionary *dragMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:UIDynamicFreeSliding], @"dragMode", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeDragModeNotification object:nil userInfo:dragMode];
            [self.dragButton setTitle:@"Drag: Free Sliding" forState:UIControlStateNormal];
        } else if (buttonIndex == 2) {
            NSDictionary *dragMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:UIDynamicFreeSlidingWithGravity], @"dragMode", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeDragModeNotification object:nil userInfo:dragMode];
            [self.dragButton setTitle:@"Drag: Gravity" forState:UIControlStateNormal];
        }

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
