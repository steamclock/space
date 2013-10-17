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
@property (strong, nonatomic) UIActionSheet* noteCircleSelection;
@property (strong, nonatomic) UIActionSheet* editorModeSelection;

@property (strong, nonatomic) UIButton* layoutButton;
@property (strong, nonatomic) UIButton* focusButton;
@property (strong, nonatomic) UIButton* dragButton;
@property (strong, nonatomic) UIButton* noteCircleButton;
@property (strong, nonatomic) UIButton* editorButton;

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
    [self.focusButton setTitle:@"Focus: Slide Partially" forState:UIControlStateNormal];
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
    
    self.noteCircleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.noteCircleButton setTitle:@"Note Circle: Show Original" forState:UIControlStateNormal];
    self.noteCircleButton.titleLabel.font = [UIFont systemFontOfSize:20];
    CGRect noteCircleButtonFrame = CGRectMake(5, 220, 300, 50);
    self.noteCircleButton.frame = noteCircleButtonFrame;
    [self.noteCircleButton addTarget:self action:@selector(showNoteCircleSelection) forControlEvents:UIControlEventTouchUpInside];
    
    self.editorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.editorButton setTitle:@"Editor: No Title" forState:UIControlStateNormal];
    self.editorButton.titleLabel.font = [UIFont systemFontOfSize:20];
    CGRect editorButtonFrame = CGRectMake(5, 290, 300, 50);
    self.editorButton.frame = editorButtonFrame;
    [self.editorButton addTarget:self action:@selector(showEditorModeSelection) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.view addSubview:self.layoutButton];
    [self.view addSubview:self.focusButton];
    [self.view addSubview:self.dragButton];
    [self.view addSubview:self.noteCircleButton];
    [self.view addSubview:self.editorButton];
}

- (void)showDrawerLayoutSelection {
    
    self.drawerLayoutSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Drawer Layout"
                                                             delegate:(id<UIActionSheetDelegate>)self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"2 Sections", @"3 Sections", nil];
    [self.drawerLayoutSelection showInView:self.view];
}

- (void)showFocusModeSelection {
    
    self.focusModeSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Focus Mode"
                                                          delegate:(id<UIActionSheetDelegate>)self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Slide Partially", @"Slide Out", @"No Slide", nil];
    [self.focusModeSelection showInView:self.view];
}

- (void)showDragModeSelection {
    
    self.dragModeSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Drag Mode"
                                                          delegate:(id<UIActionSheetDelegate>)self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Gravity", @"Free Sliding", @"Basic Animation", nil];
    [self.dragModeSelection showInView:self.view];
}

- (void)showNoteCircleSelection {
    
    self.noteCircleSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Note Circle Display Mode"
                                                           delegate:(id<UIActionSheetDelegate>)self
                                                  cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Show Original Location", @"Don't Show Original Location", nil];
    [self.noteCircleSelection showInView:self.view];
}

- (void)showEditorModeSelection {
    
    self.editorModeSelection = [[UIActionSheet alloc] initWithTitle:@"Choose an Editor Mode"
                                                         delegate:(id<UIActionSheetDelegate>)self
                                                cancelButtonTitle:@"Cancel"
                                           destructiveButtonTitle:nil
                                                otherButtonTitles:@"No Title", @"Show Title", nil];
    [self.editorModeSelection showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet == self.drawerLayoutSelection) {
        
        if (buttonIndex == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoadTwoSectionsLayoutNotification object:nil];
            [self.layoutButton setTitle:@"Layout: 2 Sections" forState:UIControlStateNormal];
        } else if (buttonIndex == 1) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoadThreeSectionsLayoutNotification object:nil];
            [self.layoutButton setTitle:@"Layout: 3 Sections" forState:UIControlStateNormal];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLayoutChangedNotification object:nil];
        
    } else if (actionSheet == self.focusModeSelection) {
        
        if (buttonIndex == 0) {
            NSDictionary *focusMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:SlidePartially], Key_FocusMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeFocusModeNotification object:nil userInfo:focusMode];
            [self.focusButton setTitle:@"Focus: Slide Partially" forState:UIControlStateNormal];
        } else if (buttonIndex == 1) {
            NSDictionary *focusMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:SlideOut], Key_FocusMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeFocusModeNotification object:nil userInfo:focusMode];
            [self.focusButton setTitle:@"Focus: Slide Out" forState:UIControlStateNormal];
        } else if (buttonIndex == 2) {
            NSDictionary *focusMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:Dimming], Key_FocusMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeFocusModeNotification object:nil userInfo:focusMode];
            [self.focusButton setTitle:@"Focus: No Sliding" forState:UIControlStateNormal];
        }
        
    } else if (actionSheet == self.dragModeSelection) {
        
        if (buttonIndex == 0) {
            NSDictionary *dragMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:UIDynamicFreeSlidingWithGravity], Key_DragMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeDragModeNotification object:nil userInfo:dragMode];
            [self.dragButton setTitle:@"Drag: Gravity" forState:UIControlStateNormal];
        } else if (buttonIndex == 1) {
            NSDictionary *dragMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:UIDynamicFreeSliding], Key_DragMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeDragModeNotification object:nil userInfo:dragMode];
            [self.dragButton setTitle:@"Drag: Free Sliding" forState:UIControlStateNormal];
        } else if (buttonIndex == 2) {
            NSDictionary *dragMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:UIViewAnimation], Key_DragMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeDragModeNotification object:nil userInfo:dragMode];
            [self.dragButton setTitle:@"Drag: Basic Animation" forState:UIControlStateNormal];
        }

    } else if (actionSheet == self.noteCircleSelection) {
        
        if (buttonIndex == 0) {
            NSDictionary *noteCircleMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:ShowOriginalLocation], Key_NoteCircleMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeNoteCircleModeNotification object:nil userInfo:noteCircleMode];
            [self.noteCircleButton setTitle:@"Note Circle: Show Original" forState:UIControlStateNormal];
        } else if (buttonIndex == 1) {
            NSDictionary *noteCircleMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:HideOriginalLocation], Key_NoteCircleMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeNoteCircleModeNotification object:nil userInfo:noteCircleMode];
            [self.noteCircleButton setTitle:@"Note Circle: Hide Original" forState:UIControlStateNormal];
        }
        
    } else if (actionSheet == self.editorModeSelection) {
        
        if (buttonIndex == 0) {
            NSDictionary* editorMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:NoTitle], Key_EditorMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeEditorModeNotification object:nil userInfo:editorMode];
            [self.editorButton setTitle:@"Editor: No Title" forState:UIControlStateNormal];
        } else if (buttonIndex == 1) {
            NSDictionary* editorMode = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:ShowTitle], Key_EditorMode, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeEditorModeNotification object:nil userInfo:editorMode];
            [self.editorButton setTitle:@"Editor: Show Title" forState:UIControlStateNormal];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
