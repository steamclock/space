//
//  CanvasViewController.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteView.h"
#import "DrawerViewControllerDelegate.h"

@class FocusViewController;

@interface CanvasViewController : UIViewController <UIDynamicAnimatorDelegate, DrawerViewControllerDelegate>

@property (nonatomic) FocusViewController* focus;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// These properties help manage zoom focus animation

@property (nonatomic) BOOL isRunningZoomAnimation;
@property (strong, nonatomic) NoteView* currentlyZoomedInNoteView;
@property (nonatomic) BOOL isCurrentlyZoomedIn;
@property (nonatomic) float zoomAnimationDuration;

@property (strong, nonatomic) NoteView* newlyCreatedNoteView;
@property (nonatomic) BOOL noteCreated;
@property (nonatomic) BOOL shouldZoomInAfterCreatingNewNote;
@property (nonatomic) BOOL shouldLoadCanvasAfterZoomOut;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(id)initWithTopLevelView:(UIView*)view;
-(id)initAsTrashCanvasWithTopLevelView:(UIView*)view;

//set up various almost-constants
-(void)setYValuesWithTrashOffset:(int)trashY;

-(void)updateNotesForBoundsChange;

@end
