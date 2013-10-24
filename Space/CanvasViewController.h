//
//  CanvasViewController.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//
//  Zoom Animation Explained:
//
//  Zooming In:
//
//  1. When a note circle is tapped, the canvas immediately draws a duplicate note circle.
//  2. After the duplicate note circle is drawn, the original note circle will zoom in to the center of the screen.
//  3. As soon as the zoom is completed, the focus view, which looks exactly the same as the zoomed in note circle, will appear,
//     and the zoomed in note circle will disappear.
//  4. Finally, a notification is sent, and the canvas will slide up partially.
//
//  Note: After the canvas has slid up, so does the original zoomed-in and now hidden note circle, since it's a subview
//        of the canvas. Therefore, we must reposition the original zoomed-in note circle before zooming out, so it can
//        reappear in the middle of the screen, rather than up top at where the canvas has slid up to.
//
//  Zooming Out:
//
//  1. The focus view will disappear, and the zoomed in note circle with a recalculated offset position will appear.
//  2. The note circle will zoom out to its original position in the canvas.
//  3. After it has zoomed out, the duplicate note circle is removed.
//  4. Finally, a notification is sent here as well, and the canvas will slide back down to its fully revealed position.
//

#import <UIKit/UIKit.h>
#import "NoteView.h"

@class FocusViewController;

@interface CanvasViewController : UIViewController <UIDynamicAnimatorDelegate>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@property (strong, nonatomic) NoteView* currentlyZoomedInNoteView;
@property (nonatomic) CGRect originalZoomedInNoteViewFrame;

// A temporary duplicate note circle at the exact same location of the tapped note circle.
@property (strong, nonatomic) UIImageView* originalNoteCircleIndicator;

// Used to help disabling user interactions during an animation, which could cause glitches.
@property (nonatomic) BOOL isRunningZoomAnimation;

@property (nonatomic) BOOL isCurrentlyZoomedIn;

// Refocus is the case for an attempt to zoom in another note while one is already zoomed in.
@property (nonatomic) BOOL isRefocus;
@property (nonatomic) BOOL hasRefocused;

// How far away the note/top canvas is from its resting/original position after sliding up; This is used to determine
// where to redraw the actual zoomed in note view when unzoom occurs.
@property (nonatomic) float slideOffset;
@property (nonatomic) float previousOffset;

@property (nonatomic) float zoomAnimationDuration;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@property (strong, nonatomic) NoteView* newlyCreatedNoteView;
@property (nonatomic) BOOL noteCreated;

// Assist with automatic zoom in at note creation.
@property (nonatomic) BOOL shouldZoomInAfterCreatingNewNote;
@property (nonatomic) BOOL shouldLoadCanvasAfterZoomOut;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@property (nonatomic) FocusViewController* focus;

// Displays the artwork for the drag handle.
@property (strong, nonatomic) UIImageView* dragHandleView;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Initialize either a note or a trash canvas.
-(id)initAsNoteCanvasWithTopLevelView:(UIView*)view;
-(id)initAsTrashCanvasWithTopLevelView:(UIView*)view;

// Sets the threshold for drag-to-trash, and once a note view is dragged past this threshold, it can be trashed when touch is released.
-(void)setTrashThreshold:(int)trashY;

// Update note view locations when orientation changes.
-(void)updateNotesForBoundsChange;

// Triggers a zoom on a selected note view. The method itself will determine whether to zoom or to unzoom.
-(void)toggleZoomForNoteView:(NoteView*)noteView completion:(void (^)(void))zoomCompleted;

@end
