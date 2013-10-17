//
//  CanvasViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasViewController.h"
#import "FocusViewController.h"
#import "Database.h"
#import "Note.h"
#import "QBPopupMenu.h"
#import "Notifications.h"
#import "Constants.h"
#import "Coordinate.h"
#import "HelperMethods.h"

#define SCALE_FACTOR 8.0

@interface CanvasViewController ()

@property (nonatomic) UIDynamicAnimator* animator;
@property (nonatomic) UICollisionBehavior* collision;
@property (nonatomic) UIDynamicItemBehavior* dynamicProperties;

@property (nonatomic) NoteView* notePendingDelete;

@property (nonatomic) int currentCanvas;
@property (nonatomic) BOOL isTrashMode;

@property (nonatomic) int triggerFocusY;
@property (nonatomic) int triggerTrashY;
@property (nonatomic) BOOL dragToFocusRequested;
@property (nonatomic) BOOL dragToTrashRequested;

@property (nonatomic) UIView* topLevelView;
@property (strong, nonatomic) UIButton* emptyTrashButton;

@property (nonatomic) BOOL showOriginalNoteLocation;

@end

@implementation CanvasViewController;

#pragma mark - Canvas Handling

-(id)initWithTopLevelView:(UIView*)view {
    if (self = [super init]) {
        self.topLevelView = view;
    }
    return self;
}

-(id)initAsTrashCanvasWithTopLevelView:(UIView*)view {
    if (self = [super init]) {
        self.topLevelView = view;
        self.isTrashMode = YES;
    }
    return self;
}

-(void)setYValuesWithTrashOffset:(int)trashY {
    // Trash offset is relative to superview
    self.triggerFocusY = self.view.bounds.size.height;
    self.triggerTrashY = trashY - self.view.frame.origin.y - 100;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;

    self.collision = [[UICollisionBehavior alloc] init];
    self.collision.translatesReferenceBoundsIntoBoundary = YES;
    self.dynamicProperties = [[UIDynamicItemBehavior alloc] init];
    self.dynamicProperties.allowsRotation = NO;
    self.dynamicProperties.resistance = 10;

    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.dynamicProperties];

    if (self.isTrashMode) {
        // Catch the trashed notes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteTrashedNotification:) name:kNoteTrashedNotification object:nil];
        
    } else {
        // Allow new notes
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spaceTap:)];
        [self.view addGestureRecognizer:tapGestureRecognizer];
        
        // Catch the recovered notes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteRecoveredNotification:) name:kNoteRecoveredNotification object:nil];
        
        // Help manage note circle zoom animation
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteCreated:) name:kNoteCreatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutChanged:) name:kLayoutChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissNote:) name:kDismissNoteNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleNoteCircleMode:) name:kChangeNoteCircleModeNotification object:nil];
    }
    
    self.currentCanvas = 0;
    [self loadCurrentCanvas];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canvasChanged:) name:kCanvasChangedNotification object:nil];
    
    self.zoomAnimationDuration = 0.5;
    self.showOriginalNoteLocation = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (self.isTrashMode) {
        self.emptyTrashButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.emptyTrashButton setTitle:@"Empty Trash" forState:UIControlStateNormal];
        self.emptyTrashButton.frame = [Coordinate frameWithCenterXByFactor:0.5 centerYByFactor:0.9 width:300 height:50 withReferenceBounds:self.view.bounds];
        [self.emptyTrashButton addTarget:self action:@selector(emptyTrash) forControlEvents:UIControlEventTouchUpInside];
        self.emptyTrashButton.titleLabel.font = [UIFont systemFontOfSize:20];
        
        [self.view addSubview:self.emptyTrashButton];
        // NSLog(@"Empty Trash Button Frame = %@", NSStringFromCGRect(self.emptyTrashButton.frame));
    }
    
    if (self.isTrashMode == NO) {
        // NSLog(@"Canvas view center = %@", NSStringFromCGPoint(self.view.center));
        // NSLog(@"Canvas superview center = %@", NSStringFromCGPoint(self.view.superview.superview.center));
    }
}

#pragma mark - Show / Hide Original Note Circle Location

-(void)toggleNoteCircleMode:(NSNotification*)notification {
    if ([[notification.userInfo objectForKey:Key_NoteCircleMode] isEqual:[NSNumber numberWithInt:ShowOriginalLocation]]) {
        self.showOriginalNoteLocation = YES;
    } else {
        self.showOriginalNoteLocation = NO;
    }
}

#pragma mark - Change Canvas

-(void)loadCurrentCanvas {
    
    for(UIView* view in self.view.subviews) {
        [self.collision removeItem:view];
        [self.dynamicProperties removeItem:view];
    }
    
    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSArray* notes;
    
    if (self.isTrashMode) {
        notes = [[Database sharedDatabase] trashedNotesInCanvas:self.currentCanvas];
        NSLog(@"Number of deleted notes = %d", [notes count]);
        
        self.emptyTrashButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.emptyTrashButton setTitle:@"Empty Trash" forState:UIControlStateNormal];
        self.emptyTrashButton.frame = [Coordinate frameWithCenterXByFactor:0.5 centerYByFactor:0.9 width:300 height:50 withReferenceBounds:self.view.bounds];
        [self.emptyTrashButton addTarget:self action:@selector(emptyTrash) forControlEvents:UIControlEventTouchUpInside];
        self.emptyTrashButton.titleLabel.font = [UIFont systemFontOfSize:20];
        
        [self.view addSubview:self.emptyTrashButton];
        // NSLog(@"Empty Trash Button Frame = %@", NSStringFromCGRect(self.emptyTrashButton.frame));
        
    } else {
        notes = [[Database sharedDatabase] notesInCanvas:self.currentCanvas];
        NSLog(@"Number of saved notes = %d", [notes count]);
    }
    
    for(Note* note in notes) {
        [self addViewForNote:note];
    }
}

-(void)canvasChanged:(NSNotification*)notification {

    self.currentCanvas = [notification.userInfo[Key_CanvasNumber] intValue];
    // NSLog(@"Current canvas = %d", self.currentCanvas);
    
    if (self.isCurrentlyZoomedIn) {
        
        self.shouldLoadCanvasAfterZoomOut = YES;
        
        self.zoomAnimationDuration = 0;
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
        self.zoomAnimationDuration = 0.5;
        
    } else {
        [self loadCurrentCanvas];
    }
}

#pragma mark - Add Notes

-(void)spaceTap:(UITapGestureRecognizer *)recognizer {
    
    // Don't allow space tap if the animator is still running, or if a zoom animation is still animating
    if (self.animator.running || self.isRunningZoomAnimation) {
        return;
    }
    
    // Don't create a note when an empty space is tapped while we're zoomed in, instead, zoom out.
    if (self.isCurrentlyZoomedIn) {
        self.isRefocus = NO;
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
        return;
    }
    
    Note* note = [[Database sharedDatabase] createNote];
    
    CGPoint position = [recognizer locationInView:self.view];
    // NSLog(@"Creating a note at %@", NSStringFromCGPoint(position));
    
    note.canvas = self.currentCanvas;
    note.positionX = [Coordinate normalizeXCoord:position.x withReferenceBounds:self.view.bounds]; // position.x;
    note.positionY = [Coordinate normalizeYCoord:position.y withReferenceBounds:self.view.bounds]; // position.y;
    
    // NSLog(@"Normalized X coord = %f", [Coordinate normalizeXCoord:position.x withReferenceBounds:self.view.bounds]);
    // NSLog(@"Normalized Y coord = %f", [Coordinate normalizeYCoord:position.y withReferenceBounds:self.view.bounds]);
    
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds];
    note.originalX = unnormalizedCenter.x;
    note.originalY = unnormalizedCenter.y;
    // NSLog(@"Unnormalized coord = %@", NSStringFromCGPoint([Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds]));
    
    self.noteCreated = YES;
    [self addViewForNote:note];
    
    [[Database sharedDatabase] save];
}

-(void)addViewForNote:(Note*)note {
    
    NoteView* noteView = [[NoteView alloc] init];
    noteView.animator = self.animator;
    
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds];
    [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
    
    // NSLog(@"Note position X = %f", note.positionX);
    // NSLog(@"Note position Y = %f", note.positionY);
    // NSLog(@"Adding note at %@", NSStringFromCGPoint(noteView.center));
    
    // If this is a trashed note, "flip" its y-coordinate so that for example, if it was originally 80% down the y-coordinate in the top canvas,
    // it should only be roughly 20% down in the bottom canvas.
    if ((self.isTrashMode == YES && note.trashed == YES && note.draggedToTrash != YES)) {
        
        unnormalizedCenter.y = self.view.bounds.size.height - unnormalizedCenter.y;
        [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
        
        NSLog(@"Dropped to Trash note view center = %@", NSStringFromCGPoint(noteView.center));
        
    } else if (self.isTrashMode == YES && note.trashed == YES && note.draggedToTrash == YES) {
        
        // If this note was manually dragged to trash, place it at the original position at the start of the drag
        
        float normalizedOriginalX = [Coordinate normalizeXCoord:note.originalX withReferenceBounds:self.view.bounds];
        float normalizedOriginalY = [Coordinate normalizeYCoord:note.originalY withReferenceBounds:self.view.bounds];
        
        note.positionX = normalizedOriginalX;
        note.positionY = normalizedOriginalY;
        
        unnormalizedCenter = [Coordinate unnormalizePoint:CGPointMake(normalizedOriginalX, normalizedOriginalY) withReferenceBounds:self.view.bounds];
        
        if ( self.view.bounds.size.height - unnormalizedCenter.y > 0 ) {
            unnormalizedCenter.y = self.view.bounds.size.height - unnormalizedCenter.y;
        }
        
        [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
        note.originalX = noteView.center.x;
        note.originalY = noteView.center.y;
        
        [[Database sharedDatabase] save];
        
        NSLog(@"Dragged to Trash note view center = %@", NSStringFromCGPoint(noteView.center));
    }
    
    noteView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(noteTap:)];
    [noteView addGestureRecognizer:tapGestureRecognizer];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(noteDrag:)];
    [noteView addGestureRecognizer:panGestureRecognizer];

    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(noteLongPress:)];
    [noteView addGestureRecognizer:longPress];

    [self.view addSubview:noteView];
    [self.collision addItem:noteView];
    [self.dynamicProperties addItem:noteView];

    noteView.note = note;
    
    if (self.noteCreated == YES) {
        // [self.focus focusOn:imageView withTouchPoint:unnomralizedCenter];
        self.newlyCreatedNoteView = noteView;
        self.shouldZoomInAfterCreatingNewNote = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNoteCreatedNotification object:self];
        self.noteCreated = NO;
    }
}

#pragma mark - Delete Notes

-(void)noteLongPress: (UITapGestureRecognizer *)recognizer {
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        NoteView* view = (NoteView*)recognizer.view;
        [self askToDeleteNote:view];
    }
}

-(void)askToDeleteNote:(NoteView*) view {
    self.notePendingDelete = view;
    
    QBPopupMenu* menu = [[QBPopupMenu alloc] init];
    NSString* title = self.isTrashMode ? @"Delete forever" : @"Send to trash";
    menu.items = @[ [[QBPopupMenuItem alloc] initWithTitle:title target:self action:@selector(deletePendingNote)] ];
    
    // We need to use the top-level view so that clicking outside the popup dismisses it.
    CGPoint showAt = [view.superview convertPoint:view.center toView:self.topLevelView];
    
    [menu showInView:self.topLevelView atPoint:showAt];
}

-(void)deletePendingNote {
    Note* note = self.notePendingDelete.note;
    
    [self.collision removeItem:self.notePendingDelete];
    [self.dynamicProperties removeItem:self.notePendingDelete];
    
    if (self.isTrashMode) {
        [self.notePendingDelete removeFromSuperview];
        self.notePendingDelete = nil;
        
        [note removeFromDatabase];
        [[Database sharedDatabase] save];
    } else {
        [note markAsTrashed];
        
        UIGravityBehavior *trashDrop = [[UIGravityBehavior alloc] initWithItems:@[self.notePendingDelete]];
        trashDrop.gravityDirection = CGVectorMake(0, 1);
        [self.animator addBehavior:trashDrop];
        
        __weak CanvasViewController* weakSelf = self;
        
        CGPoint windowBottom = CGPointMake(0, self.topLevelView.frame.size.height);
        // NSLog(@"window size %@", NSStringFromCGPoint(windowBottom));
        CGPoint windowRelativeBottom = [self.view convertPoint:windowBottom fromView:self.topLevelView];
        // NSLog(@"dist %f", windowRelativeBottom.y);
        
        self.notePendingDelete.offscreenYDistance = windowRelativeBottom.y + NOTE_RADIUS;
        
        self.notePendingDelete.onDropOffscreen = ^{
            [weakSelf.animator removeBehavior:trashDrop];
            [weakSelf.notePendingDelete removeFromSuperview];
            weakSelf.notePendingDelete = nil;
            
            NSDictionary* deletedNoteInfo = [[NSDictionary alloc] initWithObjects:@[note] forKeys:@[Key_TrashedNotes]];
            
            NSNotification* noteTrashedNotification = [[NSNotification alloc] initWithName:kNoteTrashedNotification object:weakSelf userInfo:deletedNoteInfo];
            [[NSNotificationCenter defaultCenter] postNotification:noteTrashedNotification];
        };
    }
}

-(void)deleteNoteWithoutAsking:(NoteView*) view {
    self.notePendingDelete = view;
    
    self.notePendingDelete.note.draggedToTrash = YES;
    
    [self deletePendingNote];
}

-(void)noteTrashedNotification:(NSNotification*)notification {
    if (self.isTrashMode) {
        Note* trashedNote = [notification.userInfo objectForKey:Key_TrashedNotes];
        // trashedNote.positionY = [Coordinate normalizeYCoord:NOTE_RADIUS withReferenceBounds:self.view.bounds];
        [self addViewForNote:trashedNote];
        [[Database sharedDatabase] save];
    }
}

-(void)recoverNote:(NoteView*)noteView {
    
    NSDictionary* noteToRecoverInfo =
    [[NSDictionary alloc] initWithObjects:@[noteView.note, [NSValue valueWithCGPoint:CGPointMake(noteView.note.originalX, noteView.note.originalY)]]
                                  forKeys:@[Key_RecoveredNote, @"originalPosition"]];
    
    NSNotification* noteRecoveredNotification = [[NSNotification alloc] initWithName:kNoteRecoveredNotification object:self userInfo:noteToRecoverInfo];
    [[NSNotificationCenter defaultCenter] postNotification:noteRecoveredNotification];
    
    [noteView removeFromSuperview];
    
    [self.collision removeItem:noteView];
    [self.dynamicProperties removeItem:noteView];
}

-(void)noteRecoveredNotification:(NSNotification*)notification {
   
    Note* recoveredNote = [notification.userInfo objectForKey:Key_RecoveredNote];
    NSValue *originalPosition = [notification.userInfo objectForKey:@"originalPosition"];
    
    CGPoint originalCenter = [originalPosition CGPointValue];
    
    // NSLog(@"Recovered note position X = %f",originalCenter.x);
    // NSLog(@"Recovered note position Y = %f",originalCenter.y);
    
    recoveredNote.positionX = [Coordinate normalizeXCoord:originalCenter.x withReferenceBounds:self.view.bounds];
    recoveredNote.positionY = [Coordinate normalizeYCoord:originalCenter.y withReferenceBounds:self.view.bounds];
    
    [self addViewForNote:recoveredNote];
    
    recoveredNote.trashed = NO;
    
    [[Database sharedDatabase] save];
}

-(void)emptyTrash {
    
    // NSLog(@"Emptying trash...");
    
    NSArray* notes;
    
    if (self.isTrashMode) {
        notes = [[Database sharedDatabase] trashedNotesInCanvas:self.currentCanvas];
    }
    
    for (int i = 0; i < [notes count]; i++) {
        Note* note = [notes objectAtIndex:i];
        [note removeFromDatabase];
        [[Database sharedDatabase] save];
    }
    
    [self loadCurrentCanvas];
}

#pragma mark - Focus Notes

-(void)noteTap: (UITapGestureRecognizer *)recognizer {
    
    // Don't allow focus if the animator is still running, or if a zoom animation is still animating.
    if (self.animator.running || self.isRunningZoomAnimation) {
        return;
    }
    
    NoteView* noteView = (NoteView*)recognizer.view;
    
    // Update the original X and Y everytime a note is tapped to help with partial slide zoom animation
    noteView.note.originalX = noteView.center.x;
    noteView.note.originalY = noteView.center.y;
    
    // If we're already zoomed in and another note is tapped, dismiss the currently zoomed in note, then zoom in the newly selected note
    if (self.isCurrentlyZoomedIn == YES && self.currentlyZoomedInNoteView != noteView) {
        
        self.isRefocus = YES;
        
        self.currentlyZoomedInNoteView.layer.zPosition = 500;
        
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:^(void) {
            self.currentlyZoomedInNoteView = noteView;
            
            // Prevents double tap
            [self.currentlyZoomedInNoteView setUserInteractionEnabled:NO];
            
            if (self.isCurrentlyZoomedIn == NO) {
                self.currentlyZoomedInNoteView.originalCircleFrame = self.currentlyZoomedInNoteView.frame;
            }
            
            [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
        }];
    } else {
    
        self.currentlyZoomedInNoteView = noteView;
        
        // Prevents double tap
        [self.currentlyZoomedInNoteView setUserInteractionEnabled:NO];
        
        if (self.isCurrentlyZoomedIn == NO) {
            self.currentlyZoomedInNoteView.originalCircleFrame = self.currentlyZoomedInNoteView.frame;
        }
        
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
        
        // [self.focus focusOn:noteView withTouchPoint:[recognizer locationInView:self.topLevelView]];
        // NSLog(@"Point of touch = %@", NSStringFromCGPoint([recognizer locationInView:self.topLevelView]));
    }
}

#pragma mark - Zoom Focus Animation

-(void)toggleZoomForNoteView:(NoteView*)noteView completion:(void (^)(void))zoomCompleted {
    
    self.isRunningZoomAnimation = YES;
    
    if (self.isCurrentlyZoomedIn) {
        noteView = self.currentlyZoomedInNoteView;
    }
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (CGRectEqualToRect(noteView.frame, noteView.originalCircleFrame) || self.shouldZoomInAfterCreatingNewNote == YES || self.isCurrentlyZoomedIn == NO) {
        
        noteView.titleLabel.alpha = 0;
        
        noteView.originalPositionX = noteView.note.positionX;
        noteView.originalPositionY = noteView.note.positionY;
        
        // Cannot transform properly when the view is being controlled by the animator
        [self.collision removeItem:noteView];
        [self.dynamicProperties removeItem:noteView];
        
        self.isCurrentlyZoomedIn = YES;
        self.shouldZoomInAfterCreatingNewNote = NO;
        
        noteView.layer.zPosition = 1000;
        
        // Create a temporary circle view that shows the zoomed in note's original location
        if (self.showOriginalNoteLocation) {
            self.originalNoteCircleIndicator = [self drawCircleWithFrame:noteView.originalCircleFrame];
            
            if (self.dragToFocusRequested) {
                self.originalNoteCircleIndicator.center = CGPointMake(noteView.note.originalX, noteView.note.originalY);
            }
            
            [self.view addSubview:self.originalNoteCircleIndicator];
        }
        
        // Fade out all other note views
        for (UIView* view in self.view.subviews) {
            if ([view isKindOfClass:[NoteView class]]) {
                NoteView* notZoomedInNoteView = (NoteView*)view;
                
                if (notZoomedInNoteView != self.currentlyZoomedInNoteView) {
                    notZoomedInNoteView.circleShape.strokeColor = [UIColor lightGrayColor].CGColor;
                }
            }
         }
        
        [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
            // Zoom Circle
            [noteView setTransform:CGAffineTransformMakeScale(SCALE_FACTOR, SCALE_FACTOR)];
            CGPoint centerOfScreen = [self findCenterOfScreen];
            
            if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
                if (self.isRefocus) {
                    noteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - self.view.superview.frame.origin.y - Key_LandscapeFocusViewAdjustment - self.slideOffset);
                } else {
                    noteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - self.view.superview.frame.origin.y - Key_LandscapeFocusViewAdjustment);
                }
                self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_LandscapeFocusViewAdjustment);
            } else {
                if (self.isRefocus) {
                    noteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - self.view.superview.frame.origin.y - Key_PortraitFocusViewAdjustment - self.slideOffset);
                } else {
                    noteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - self.view.superview.frame.origin.y - Key_PortraitFocusViewAdjustment);
                }
                self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_PortraitFocusViewAdjustment);
                
                // NSLog(@"Drawer Y = %f", self.view.superview.frame.origin.y);
                // NSLog(@"Note view center = %@", NSStringFromCGPoint(noteView.center));
                // NSLog(@"Focus view center = %@", NSStringFromCGPoint(self.focus.view.center));
            }
            
            [CATransaction begin]; {
                
                [CATransaction setValue:[NSNumber numberWithFloat:self.zoomAnimationDuration] forKey:kCATransactionAnimationDuration];
                noteView.circleShape.lineWidth = 0;
                noteView.circleShape.fillColor = [HelperMethods circleFillColor];
                
            } [CATransaction commit];
            
        } completion:^(BOOL finished) {
            // Allows unzoom after animation is completed
            [self.currentlyZoomedInNoteView setUserInteractionEnabled:YES];
            
            // Show editor
            [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
                self.focus.view.alpha = 1.0;
                [self.focus focusOn:noteView withTouchPoint:CGPointZero];
                
                // Show original note circle location indicator
                self.originalNoteCircleIndicator.alpha = 1;
                
            } completion:^(BOOL finished) {
                noteView.alpha = 0;
                [[NSNotificationCenter defaultCenter] postNotificationName:kFocusNoteNotification object:self];
                self.isRunningZoomAnimation = NO;
            }];
            
            // NSLog(@"Circle frame after zoomed in = %@", NSStringFromCGRect(noteView.frame));
            // NSLog(@"Circle bounds after zoomed in = %@", NSStringFromCGRect(noteView.bounds));
            
            // NSLog(@"NoteView's Note positionX after zoomed in = %f", noteView.note.positionX);
            // NSLog(@"NoteView's Note positionY after zoomed in = %f", noteView.note.positionY);
        }];
    } else {
        
        self.isCurrentlyZoomedIn = NO;
        
        CGPoint centerOfScreen = [self findCenterOfScreen];
        
        if (self.isRefocus || self.canvasWillSlide) {
            if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
                noteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - self.view.superview.frame.origin.y - Key_LandscapeFocusViewAdjustment - self.slideOffset);
            } else {
                noteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - self.view.superview.frame.origin.y - Key_PortraitFocusViewAdjustment - self.slideOffset);
            }
        } else {
            noteView.frame = CGRectMake(noteView.frame.origin.x,
                                        noteView.frame.origin.y - self.slideOffset,
                                        noteView.frame.size.width,
                                        noteView.frame.size.height);
        }
        
        noteView.alpha = 1;
        
        // Ask focus view to save the note
        [[NSNotificationCenter defaultCenter] postNotificationName:kSaveNoteNotification object:self];
        
        // Hide editor
        self.focus.view.alpha = 0;
        
        // Fade back all note views
        for (UIView* view in self.view.subviews) {
            if ([view isKindOfClass:[NoteView class]]) {
                NoteView* notZoomedInNoteView = (NoteView*)view;
                
                if (notZoomedInNoteView != self.currentlyZoomedInNoteView) {
                    notZoomedInNoteView.circleShape.strokeColor = [UIColor blackColor].CGColor;
                }
            }
        }
        
        [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
            // Unzoom Circle
            [noteView setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
            
            if (self.dragToFocusRequested) {
                // NSLog(@"Returning to X = %f", noteView.note.originalX);
                // NSLog(@"Returning to Y = %f", noteView.note.originalY);
                noteView.center = CGPointMake(noteView.note.originalX, noteView.note.originalY);
                self.dragToFocusRequested = NO;
            } else {
                noteView.frame = noteView.originalCircleFrame;
            }
            
            [CATransaction begin]; {
                
                [CATransaction setValue:[NSNumber numberWithFloat:self.zoomAnimationDuration] forKey:kCATransactionAnimationDuration];
                noteView.circleShape.lineWidth = 2.0;
                noteView.circleShape.fillColor = [UIColor clearColor].CGColor;
                
            } [CATransaction commit];
            
        } completion:^(BOOL finished) {
            
            // Allows zoom after animation is completed
            [self.currentlyZoomedInNoteView setUserInteractionEnabled:YES];
            
            // Reset the zPosition back to default so it can be overlapped by other circles that are zooming in
            noteView.layer.zPosition = 0;
            
            // NSLog(@"Circle frame after zoomed out = %@", NSStringFromCGRect(noteView.frame));
            // NSLog(@"Circle bounds after zoomed out = %@", NSStringFromCGRect(noteView.bounds));
            
            [self.collision addItem:noteView];
            [self.dynamicProperties addItem:noteView];
            
            noteView.note.positionX = [Coordinate normalizeXCoord:noteView.center.x withReferenceBounds:self.view.bounds];
            noteView.note.positionY = [Coordinate normalizeYCoord:noteView.center.y withReferenceBounds:self.view.bounds];
            [[Database sharedDatabase] save];
            
            if (self.shouldLoadCanvasAfterZoomOut) {
                [self loadCurrentCanvas];
                self.shouldLoadCanvasAfterZoomOut = NO;
            }
            
            // NSLog(@"NoteView's Note positionX after zoomed out = %f", noteView.note.positionX);
            // NSLog(@"NoteView's Note positionY after zoomed out = %f", noteView.note.positionY);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNoteDismissedNotification object:self];
            
            // Remove original note circle location indicator
            if (self.originalNoteCircleIndicator) {
                [self.originalNoteCircleIndicator removeFromSuperview];
                self.originalNoteCircleIndicator = nil;
            }
            
            if (zoomCompleted) {
                zoomCompleted();
            }
            
            [UIView animateWithDuration:0.5 animations:^{
                noteView.titleLabel.alpha = 1;
            } completion:^(BOOL finished) {
                self.isRunningZoomAnimation = NO;
            }];
        }];
    }
}

-(CGPoint)findCenterOfScreen {
    // Self.view.superview == DrawerView, DrawerView's superview is the Container view, which has the correct and current bounds of the screen,
    // so we can use that to find the absolute center of the screen.
    return [self.view.superview.superview convertPoint:self.view.superview.superview.center fromView:self.view.superview.superview.superview];
}

-(void)updateCurrentlyZoomedInNoteViewCenter {
    
    // When the drawer is dragged or has changed position while a note view is zoomed in, we want to update the center of the note view so that
    // when we unzoom the note circle, it will start the unzoom from the correct location
    if (self.isCurrentlyZoomedIn) {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        CGPoint centerOfScreen = [self findCenterOfScreen];
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            self.currentlyZoomedInNoteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - self.view.superview.frame.origin.y - Key_LandscapeFocusViewAdjustment);
        } else {
            self.currentlyZoomedInNoteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - self.view.superview.frame.origin.y - Key_PortraitFocusViewAdjustment);
        }
    }
}

-(UIView*)drawCircleWithFrame:(CGRect)frame {
    
    UIView* circle = [[UIView alloc] initWithFrame:frame];
    circle.backgroundColor = [UIColor clearColor];
    
    CAShapeLayer* circleShape = [CAShapeLayer layer];
    
    CGRect circleFrame = circle.bounds;
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithRoundedRect:circleFrame cornerRadius:NOTE_RADIUS];
    
    circleShape.path = circlePath.CGPath;
    
    circleShape.fillColor = [UIColor clearColor].CGColor;
    circleShape.strokeColor = [UIColor blackColor].CGColor;
    circleShape.lineWidth = 2.0f;
    
    circleShape.frame = circleFrame;
    
    [circle.layer addSublayer:circleShape];
    
    return circle;
}

-(void)fadeOutNoteView:(NoteView*)noteView {
    noteView.circleShape.strokeColor = [UIColor grayColor].CGColor;
}

-(void)noteCreated:(NSNotification*)notification {
    if (self.newlyCreatedNoteView != nil) {
        self.currentlyZoomedInNoteView = self.newlyCreatedNoteView;
        self.currentlyZoomedInNoteView.originalCircleFrame = self.newlyCreatedNoteView.frame;
        // Slight delay is required to wait for the animator to pause
        [self performSelector:@selector(zoomNote:) withObject:self.newlyCreatedNoteView afterDelay:1.0];
    }
}

-(void)zoomNote:(NoteView*)noteView {
    [self toggleZoomForNoteView:noteView completion:nil];
}

-(void)dismissNote:(NSNotification*)notification {
    [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
}

-(void)layoutChanged:(NSNotification*)notification {
    if (self.isCurrentlyZoomedIn) {
        self.zoomAnimationDuration = 0;
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
        self.zoomAnimationDuration = 0.5;
    }
}

#pragma mark - Drag Notes

static BOOL dragStarted = NO;

-(void)noteDrag:(UIPanGestureRecognizer*)recognizer {
    
    // Don't allow note drag if we're currently zoomed in, which can cause problematic behaviours
    if (self.isCurrentlyZoomedIn) {
        return;
    }
    
    NoteView* noteView = (NoteView*)recognizer.view;
    CGPoint drag = [recognizer locationInView:self.view];
    
    if(dragStarted == NO) {
        
        if (!CGPointEqualToPoint(CGPointMake(noteView.note.originalX, noteView.note.originalY), noteView.center) && dragStarted == NO) {
            noteView.note.originalX = noteView.center.x;
            noteView.note.originalY = noteView.center.y;
            
            [[Database sharedDatabase] save];
            
            // NSLog(@"Original X = %f", noteView.note.originalX);
            // NSLog(@"Original Y = %f", noteView.note.originalY);
            
            dragStarted = YES;
        }
    }
    
    [noteView setCenter:drag withReferenceBounds:self.view.bounds];
    
    // Prevents dragging above the navigation bar
    if (self.isTrashMode == NO && noteView.center.y <= 0) {
        [noteView setCenter:CGPointMake(drag.x, 0) withReferenceBounds:self.view.bounds];
    }
    
    if (self.isTrashMode) {
        
        if (noteView.center.y < self.triggerTrashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [self returnNoteToBounds:noteView];
                [self recoverNote:noteView];
            } else {
                [noteView setBackgroundColor:[UIColor greenColor]];
            }
        } else if(recognizer.state == UIGestureRecognizerStateEnded) {
            [[Database sharedDatabase] save];
            CGPoint velocity = [recognizer velocityInView:self.view];
            [self.dynamicProperties addLinearVelocity:CGPointMake(velocity.x, velocity.y) forItem:noteView];
        } else {
            [noteView setBackgroundColor:[UIColor clearColor]];
        }
        
    } else {
        
        if (noteView.center.y > self.triggerTrashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                self.dragToTrashRequested = YES;
                [self deleteNoteWithoutAsking:noteView];
            } else {
                [noteView setBackgroundColor:[UIColor redColor]];
            }
        } else if (noteView.center.y > self.triggerFocusY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                self.dragToFocusRequested = YES;
                [self.focus focusOn:noteView withTouchPoint:CGPointZero];
                [self toggleZoomForNoteView:noteView completion:nil];
            } else {
                [noteView setBackgroundColor:[UIColor greenColor]];
            }
        } else {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [[Database sharedDatabase] save];
                CGPoint velocity = [recognizer velocityInView:self.view];
                [self.dynamicProperties addLinearVelocity:CGPointMake(velocity.x, velocity.y) forItem:noteView];
            } else {
                [noteView setBackgroundColor:[UIColor clearColor]];
            }
        }
    }
    
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        [noteView setBackgroundColor:[UIColor clearColor]];
        dragStarted = NO;
        
        if (self.dragToFocusRequested == NO && self.dragToTrashRequested == NO) {
            noteView.note.originalX = noteView.center.x;
            noteView.note.originalY = noteView.center.y;
            
            [[Database sharedDatabase] save];
        }
    }
}

#pragma mark - Orientation Changes Handling

-(void)updateNotesForBoundsChange {
    
    // NSLog(@"New bounds = %@", NSStringFromCGRect(self.view.bounds));
    
    for (UIView* subview in self.view.subviews) {
        
        if ([subview isKindOfClass:[NoteView class]]) {
            [self returnNoteToBounds:(NoteView*)subview];
            [self updateLocationForNoteView:(NoteView*)subview];
            
            /*
            if (subview == self.currentlyZoomedInNoteView) {
                NSLog(@"Circle frame in updateNotesForBoundsChange = %@", NSStringFromCGRect(subview.frame));
                NSLog(@"Circle bounds in updateNotesForBoundsChange = %@", NSStringFromCGRect(subview.bounds));
            }
            */
        }
    }
}

// Used to force notes back into the canvas
-(void)returnNoteToBounds:(NoteView*)note {
  
    if (! CGRectContainsRect(self.view.bounds, note.frame)) {
        CGPoint center = note.center;
        
        if (note.frame.origin.y < 0) {
            center.y = NOTE_RADIUS;
        } else if (CGRectGetMaxY(note.frame) > self.view.bounds.size.height) {
            center.y = self.view.bounds.size.height - NOTE_RADIUS;
        }
        
        if (note.frame.origin.x < 0) {
            center.x = NOTE_RADIUS;
        } else if (CGRectGetMaxX(note.frame) > self.view.bounds.size.width) {
            center.x = self.view.bounds.size.width - NOTE_RADIUS;
        }
        
        // NSLog(@"Move from %@ to %@", NSStringFromCGPoint(note.center), NSStringFromCGPoint(center));
        // note.center = center;
        
        note.center = CGPointMake(note.originalPositionX, note.originalPositionY);
        
        [self.animator updateItemUsingCurrentState:note];
        [[Database sharedDatabase] save];
    }
}

-(void)updateLocationForNoteView:(NoteView*)noteView {

    CGPoint relativePosition = CGPointMake(noteView.note.positionX, noteView.note.positionY);
    // NSLog(@"Relative position = %@", NSStringFromCGPoint(relativePosition));
    
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:relativePosition withReferenceBounds:self.view.bounds];
    
    if (noteView.note.trashed == YES) {
        unnormalizedCenter = CGPointMake(noteView.note.originalX, noteView.note.originalY);
    }
    
    [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
    // NSLog(@"New actual center = %@", NSStringFromCGPoint(noteView.center));
    
    // NSLog(@"Circle frame in updateLocationForNoteView = %@", NSStringFromCGRect(noteView.frame));
    // NSLog(@"Circle bounds in updateLocationForNoteView = %@", NSStringFromCGRect(noteView.bounds));
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Remove behaviours to prevent the animator from setting the incorrect center positions for noteViews after we've already
    // calculated and set them. We're not sure why the animator does this, but we're doing a lot of custom view positioning,
    // and it could be a result of some custom view handling logic that don't play well with the animator.
    [self.animator removeAllBehaviors];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.isTrashMode) {
        self.emptyTrashButton.frame = [Coordinate frameWithCenterXByFactor:0.5 centerYByFactor:0.9 width:300 height:50 withReferenceBounds:self.view.bounds];
    }
    
    if (self.isCurrentlyZoomedIn) {
        self.currentlyZoomedInNoteView.originalCircleFrame = [Coordinate frameWithCenterXByFactor:self.currentlyZoomedInNoteView.originalPositionX
                                                                                  centerYByFactor:self.currentlyZoomedInNoteView.originalPositionY
                                                                                            width:self.currentlyZoomedInNoteView.originalCircleFrame.size.width
                                                                                           height:self.currentlyZoomedInNoteView.originalCircleFrame.size.height
                                                                              withReferenceBounds:self.view.bounds];
        
        self.originalNoteCircleIndicator.frame = self.currentlyZoomedInNoteView.originalCircleFrame;
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    for (UIView* subview in self.view.subviews) {
        if ([subview isKindOfClass:[NoteView class]]) {
            NoteView* noteView = (NoteView*)subview;
            noteView.note.originalX = noteView.center.x;
            noteView.note.originalY = noteView.center.y;
            
            [[Database sharedDatabase] save];
        }
    }
    
    if (self.isCurrentlyZoomedIn) {
        [self repositionZoomedInNoteView:self.currentlyZoomedInNoteView];
    } else {
        [self repositionFocusView];
    }
    
    // Restore the behaviours after orientation changes and calculations are completed.
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.dynamicProperties];
}

-(void)repositionZoomedInNoteView:(NoteView*)noteView {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGPoint centerOfScreen = [self findCenterOfScreen];
    
    // Handle cases where the drawer is not completely drawn out.
    int drawerOffset = self.view.superview.frame.origin.y;
    if (drawerOffset < Key_NavBarHeight) {
        drawerOffset = Key_NavBarHeight - self.view.superview.frame.origin.y;
    } else {
        drawerOffset = 0;
    }
    
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        [UIView animateWithDuration:0.5 animations:^{
            noteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_NavBarHeight - Key_LandscapeFocusViewAdjustment + drawerOffset);
            self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_LandscapeFocusViewAdjustment);
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            noteView.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_NavBarHeight - Key_PortraitFocusViewAdjustment + drawerOffset);
            self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_PortraitFocusViewAdjustment);
        }];
    }
}

-(void)repositionFocusView {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGPoint centerOfScreen = [self findCenterOfScreen];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_LandscapeFocusViewAdjustment);
    } else {
        self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_PortraitFocusViewAdjustment);
    }
}

#pragma mark - Animator Delegate Methods

// Saves the new x, y coordinates after a throw
- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    
    for (UIView* subview in self.view.subviews) {
        
        if ([subview isKindOfClass:[NoteView class]]) {
            
            NoteView* noteView = (NoteView*)subview;
            noteView.note.positionX = [Coordinate normalizeXCoord:noteView.center.x withReferenceBounds:self.view.bounds];
            noteView.note.positionY = [Coordinate normalizeYCoord:noteView.center.y withReferenceBounds:self.view.bounds];
            
            if (self.isTrashMode) {
                noteView.note.originalX = noteView.center.x;
                noteView.note.originalY = noteView.center.y;
            }
            
            [[Database sharedDatabase] save];
        }
    }
}

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    
}

@end
