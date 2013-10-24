//
//  CanvasViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasViewController.h"
#import "FocusViewController.h"
#import "Note.h"
#import "QBPopupMenu.h"
#import "Coordinate.h"
#import "Notifications.h"
#import "Constants.h"
#import "Database.h"

#define SCALE_FACTOR 8.0 // Zoom factor.

@interface CanvasViewController ()

@property (nonatomic) UIDynamicAnimator* animator;
@property (nonatomic) UICollisionBehavior* collision;
@property (nonatomic) UIDynamicItemBehavior* dynamicProperties;

@property (nonatomic) NoteView* notePendingDelete;

@property (nonatomic) int currentCanvas;
@property (nonatomic) BOOL isTrashMode;

@property (nonatomic) int triggerTrashY;
@property (nonatomic) BOOL dragToTrashRequested;

@property (nonatomic) UIView* topLevelView;
@property (strong, nonatomic) UIButton* emptyTrashButton;

@end

@implementation CanvasViewController;

#pragma mark - Create Canvases

-(id)initAsNoteCanvasWithTopLevelView:(UIView*)view {
    if (self = [super init]) {
        self.topLevelView = view;
        self.isTrashMode = NO;
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

#pragma mark - Setup Canvases

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
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
        // Catch the trashed notes.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addTrashedNote:) name:kNoteTrashedNotification object:nil];
        
    } else {
        // Allow creating new notes.
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spaceTap:)];
        [self.view addGestureRecognizer:tapGestureRecognizer];
        
        // Catch the recovered notes.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteRecovered:) name:kNoteRecoveredNotification object:nil];
        
        // Help manage note circle zoom animation.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteCreated:) name:kNoteCreatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissNote:) name:kDismissNoteNotification object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canvasChanged:) name:kCanvasChangedNotification object:nil];
    
    self.zoomAnimationDuration = 0.5;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Load last selected canvas.
    self.currentCanvas = [[[NSUserDefaults standardUserDefaults] objectForKey:Key_CurrentCanvasIndex] intValue];
    [self loadCurrentCanvas];
}

-(void)setTrashThreshold:(int)trashY {
    self.triggerTrashY = trashY - self.view.frame.origin.y - 100;
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
        
        UIImage* trashBinImage = [[UIImage imageNamed:Img_TrashBin] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.emptyTrashButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.emptyTrashButton setImage:trashBinImage forState:UIControlStateNormal];
        self.emptyTrashButton.frame = [Coordinate frameWithCenterXByFactor:0.5 centerYByFactor:0.9 width:300 height:50 withReferenceBounds:self.view.bounds];
        [self.emptyTrashButton addTarget:self action:@selector(emptyTrash) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:self.emptyTrashButton];
        
    } else {
        notes = [[Database sharedDatabase] notesInCanvas:self.currentCanvas];
        NSLog(@"Number of saved notes = %d", [notes count]);
        
        UIImage* handlebarDownImage = [UIImage imageNamed:Img_HandlebarDown];
        self.dragHandleView = [[UIImageView alloc] initWithImage:handlebarDownImage];
        self.dragHandleView.center = CGPointMake(self.view.center.x, self.view.frame.size.height + 50);
        
        [self.view addSubview:self.dragHandleView];
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

#pragma mark - Drag Notes

static BOOL dragStarted = NO;

-(void)noteDrag:(UIPanGestureRecognizer*)recognizer {
    // Don't allow note drag if we're currently zoomed in, which can cause problematic behaviours
    if (self.isCurrentlyZoomedIn) {
        return;
    }
    
    NoteView* noteView = (NoteView*)recognizer.view;
    CGPoint drag = [recognizer locationInView:self.view];
    
    // Saves the originalX and originalY only at the beginning of a new drag.
    if(dragStarted == NO) {
        if (!CGPointEqualToPoint(CGPointMake(noteView.note.originalX, noteView.note.originalY), noteView.center) && dragStarted == NO) {
            noteView.note.originalX = noteView.center.x;
            noteView.note.originalY = noteView.center.y;
            
            [[Database sharedDatabase] save];
            
            dragStarted = YES;
        }
    }
    
    [noteView setCenter:drag withReferenceBounds:self.view.bounds];
    
    // Prevents dragging above the navigation bar
    if (self.isTrashMode == NO && noteView.center.y <= 0) {
        [noteView setCenter:CGPointMake(drag.x, 0) withReferenceBounds:self.view.bounds];
    }
    
    // Handle drag within the trash canvas.
    if (self.isTrashMode) {
        // If a trashed note in the trashed canvas is dragged above the trashY threshold, allow recovering note.
        if (noteView.center.y < self.triggerTrashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [self returnNoteToBounds:noteView];
                [self recoverNote:noteView];
            } else {
                [noteView setBackgroundColor:[UIColor greenColor]];
            }
        } else {
            // Add throw at the end of drag.
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [[Database sharedDatabase] save];
                CGPoint velocity = [recognizer velocityInView:self.view];
                [self.dynamicProperties addLinearVelocity:CGPointMake(velocity.x, velocity.y) forItem:noteView];
            } else {
                [noteView setBackgroundColor:[UIColor clearColor]];
            }
        }
    // Handle drag within the note canvas.
    } else {
        // If a note is dragged below the trashY threshold, allow trashing note.
        if (noteView.center.y > self.triggerTrashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                self.dragToTrashRequested = YES;
                [self deleteNoteWithoutAsking:noteView];
            } else {
                [noteView setBackgroundColor:[UIColor redColor]];
            }
        } else {
            // Add throw at the end of drag.
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
        
        if (self.dragToTrashRequested == NO) {
            noteView.note.originalX = noteView.center.x;
            noteView.note.originalY = noteView.center.y;
            
            [[Database sharedDatabase] save];
        }
    }
}

#pragma mark - Add Notes

-(void)spaceTap:(UITapGestureRecognizer *)recognizer {
    // Don't allow space tap if the animator is still running, or if a zoom animation is still animating.
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
    
    note.canvas = self.currentCanvas;
    
    // Store the relative location of the newly created note.
    note.positionX = [Coordinate normalizeXCoord:position.x withReferenceBounds:self.view.bounds];
    note.positionY = [Coordinate normalizeYCoord:position.y withReferenceBounds:self.view.bounds];
    
    // Store current and actual location of the newly created note.
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds];
    note.originalX = unnormalizedCenter.x;
    note.originalY = unnormalizedCenter.y;
    
    // Draw the note as a note view in the canvas.
    self.noteCreated = YES;
    [self addViewForNote:note];
    
    [[Database sharedDatabase] save];
}

-(void)addViewForNote:(Note*)note {
    NoteView* noteView = [[NoteView alloc] initWithImage:[UIImage imageNamed:@"circle"]];
    noteView.animator = self.animator;
    
    // Retrieve the actual center using the stored relative position.
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds];
    [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
    
    // If this is a trashed note, "flip" its y-coordinate so that for example, if it was originally 80% down the y-coordinate in the top canvas,
    // it should only be roughly 20% down in the bottom canvas.
    if ((self.isTrashMode == YES && note.trashed == YES && note.draggedToTrash != YES)) {
        
        unnormalizedCenter.y = self.view.bounds.size.height - unnormalizedCenter.y;
        [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
        
    } else if (self.isTrashMode == YES && note.trashed == YES && note.draggedToTrash == YES) {
        
        // If this note was manually dragged to trash, place it at the original position at the start of the drag.
        
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
    
    if (self.isTrashMode == NO && self.noteCreated == YES) {
        self.newlyCreatedNoteView = noteView;
        
        // Notify to initiate auto zoom in after a note has been created.
        self.shouldZoomInAfterCreatingNewNote = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNoteCreatedNotification object:self];
        
        // Note creation complete, reset the flag.
        self.noteCreated = NO;
    }
}

-(void)noteCreated:(NSNotification*)notification {
    if (self.newlyCreatedNoteView != nil) {
        self.currentlyZoomedInNoteView = self.newlyCreatedNoteView;
        self.currentlyZoomedInNoteView.originalCircleFrame = self.newlyCreatedNoteView.frame;
        // Slight delay is required to wait for the animator to pause.
        [self performSelector:@selector(zoomNote:) withObject:self.newlyCreatedNoteView afterDelay:1.0];
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
    
    // We need to use the top-level view so that tapping outside the popup dismisses it.
    CGPoint showAt = [view.superview convertPoint:view.center toView:self.topLevelView];
    
    [menu showInView:self.topLevelView atPoint:showAt];
}

-(void)deleteNoteWithoutAsking:(NoteView*) view {
    self.notePendingDelete = view;
    
    self.notePendingDelete.note.draggedToTrash = YES;
    
    [self deletePendingNote];
}

-(void)deletePendingNote {
    Note* note = self.notePendingDelete.note;
    
    [self.collision removeItem:self.notePendingDelete];
    [self.dynamicProperties removeItem:self.notePendingDelete];
    
    if (self.isTrashMode) { // Remove it permanentely and instantly.
        [self.notePendingDelete removeFromSuperview];
        self.notePendingDelete = nil;
        
        [note removeFromDatabase];
        [[Database sharedDatabase] save];
        
    } else {
        // Have the note fall down, and once it's fallen below a certain point, remove it, and draw the trashed note in the trash canvas.
        [note markAsTrashed];
        
        UIGravityBehavior *trashDrop = [[UIGravityBehavior alloc] initWithItems:@[self.notePendingDelete]];
        trashDrop.gravityDirection = CGVectorMake(0, 1);
        [self.animator addBehavior:trashDrop];
        
        __weak CanvasViewController* weakSelf = self;
        
        CGPoint windowBottom = CGPointMake(0, self.topLevelView.frame.size.height);
        CGPoint windowRelativeBottom = [self.view convertPoint:windowBottom fromView:self.topLevelView];
        
        self.notePendingDelete.offscreenYDistance = windowRelativeBottom.y + Key_NoteRadius;
        
        self.notePendingDelete.onDropOffscreen = ^{
            [weakSelf.animator removeBehavior:trashDrop];
            [weakSelf.notePendingDelete removeFromSuperview];
            weakSelf.notePendingDelete = nil;
            
            NSDictionary* deletedNoteInfo = [[NSDictionary alloc] initWithObjects:@[note] forKeys:@[Key_TrashedNotes]];
            
            NSNotification* noteTrashedNotification = [[NSNotification alloc] initWithName:kNoteTrashedNotification
                                                                                    object:weakSelf
                                                                                  userInfo:deletedNoteInfo];
            
            [[NSNotificationCenter defaultCenter] postNotification:noteTrashedNotification];
        };
    }
}

-(void)addTrashedNote:(NSNotification*)notification {
    if (self.isTrashMode) {
        Note* trashedNote = [notification.userInfo objectForKey:Key_TrashedNotes];
        [self addViewForNote:trashedNote];
        [[Database sharedDatabase] save];
    }
}

-(void)emptyTrash {
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

#pragma mark - Recover Note

-(void)recoverNote:(NoteView*)noteView {
    // Remove the recovering note from the trashed canvas.
    [noteView removeFromSuperview];
    [self.collision removeItem:noteView];
    [self.dynamicProperties removeItem:noteView];
    
    NSDictionary* noteToRecoverInfo =
    [[NSDictionary alloc] initWithObjects:@[noteView.note, [NSValue valueWithCGPoint:CGPointMake(noteView.note.originalX, noteView.note.originalY)]]
                                  forKeys:@[Key_RecoveredNote, @"originalPosition"]];
    
    NSNotification* noteRecoveredNotification = [[NSNotification alloc] initWithName:kNoteRecoveredNotification object:self userInfo:noteToRecoverInfo];
    [[NSNotificationCenter defaultCenter] postNotification:noteRecoveredNotification];
}

-(void)noteRecovered:(NSNotification*)notification {
    Note* recoveredNote = [notification.userInfo objectForKey:Key_RecoveredNote];
    NSValue* originalPosition = [notification.userInfo objectForKey:@"originalPosition"];
    
    CGPoint originalCenter = [originalPosition CGPointValue];
    
    recoveredNote.positionX = [Coordinate normalizeXCoord:originalCenter.x withReferenceBounds:self.view.bounds];
    recoveredNote.positionY = [Coordinate normalizeYCoord:originalCenter.y withReferenceBounds:self.view.bounds];
    
    [self addViewForNote:recoveredNote];
    
    recoveredNote.trashed = NO;
    
    [[Database sharedDatabase] save];
}

#pragma mark - Focus Notes

-(void)noteTap:(UITapGestureRecognizer *)recognizer {
    // Don't allow focus if the animator is still running, or if a zoom animation is still animating.
    if (self.animator.running || self.isRunningZoomAnimation) {
        return;
    }
    
    NoteView* noteView = (NoteView*)recognizer.view;
    
    // Don't allow focus if the note is trashed.
    if (noteView.note.trashed == YES) {
        return;
    }
    
    // Update the original X and Y everytime a note is tapped to help with partial slide zoom animation
    noteView.note.originalX = noteView.center.x;
    noteView.note.originalY = noteView.center.y;
    
    // If we're already zoomed in and another note is tapped, dismiss the currently zoomed in note, then zoom in the newly selected note
    if (self.isCurrentlyZoomedIn == YES && self.currentlyZoomedInNoteView != noteView) {
        
        self.isRefocus = YES;
        self.hasRefocused = YES;
        
        self.currentlyZoomedInNoteView.layer.zPosition = 500;
        
        // Prevents double tap
        [self.currentlyZoomedInNoteView setUserInteractionEnabled:NO];
        
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:^(void) {
            self.currentlyZoomedInNoteView = noteView;
            
            if (self.isCurrentlyZoomedIn == NO) {
                self.currentlyZoomedInNoteView.originalCircleFrame = self.currentlyZoomedInNoteView.frame;
            }
            
            [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
        }];
    } else {
        self.currentlyZoomedInNoteView = noteView;
        
        // Prevents double tap.
        [self.currentlyZoomedInNoteView setUserInteractionEnabled:NO];
        
        if (self.isCurrentlyZoomedIn == NO) {
            self.currentlyZoomedInNoteView.originalCircleFrame = self.currentlyZoomedInNoteView.frame;
        }
        
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
    }
}

#pragma mark - Zoom Focus Animation

-(void)zoomNote:(NoteView*)noteView {
    [self toggleZoomForNoteView:noteView completion:nil];
}

-(void)dismissNote:(NSNotification*)notification {
    [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
}

-(void)toggleZoomForNoteView:(NoteView*)noteView completion:(void (^)(void))zoomCompleted {
    self.isRunningZoomAnimation = YES;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (self.isCurrentlyZoomedIn) {
        noteView = self.currentlyZoomedInNoteView;
    }
    
    // Zoom in if we're not currently zoomed in, or if a new note has just been created.
    if (self.isCurrentlyZoomedIn == NO || self.shouldZoomInAfterCreatingNewNote == YES) {
        
        noteView.titleLabel.alpha = 0;
        
        noteView.originalPositionX = noteView.note.positionX;
        noteView.originalPositionY = noteView.note.positionY;
        
        // Cannot transform properly when the view is being controlled by the animator.
        [self.collision removeItem:noteView];
        [self.dynamicProperties removeItem:noteView];
        
        self.isCurrentlyZoomedIn = YES;
        self.shouldZoomInAfterCreatingNewNote = NO;
        
        noteView.layer.zPosition = 1000;
        
        // Create a temporary circle view that shows the zoomed in note's original location.
        [self createOriginalNoteCircleIndicator];
        
        // Dim all note views.
        [self dimNoteViews];
        
        // Zoom in animation blocks.
        [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
            noteView.image = [noteView.image resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30) resizingMode:UIImageResizingModeStretch];
            noteView.frame = [self.focus.view convertRect:self.focus.view.bounds toView:self.view];
            noteView.layer.cornerRadius = Key_NoteRadius;
            noteView.layer.backgroundColor = [UIColor whiteColor].CGColor;
            noteView.layer.masksToBounds = YES;
            
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
            }
            
        } completion:^(BOOL finished) {
            // Show editor.
            [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
                self.focus.view.alpha = 1;
                [self.focus focusOn:noteView];
                
                // Show original note circle location indicator.
                self.originalNoteCircleIndicator.alpha = 1;
                
            } completion:^(BOOL finished) {
                noteView.alpha = 0;
                
                noteView.autoresizingMask =
                UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kFocusNoteNotification object:self];
                self.isRunningZoomAnimation = NO;
                
                // Allows unzoom after animation is completed.
                [self.currentlyZoomedInNoteView setUserInteractionEnabled:YES];
            }];
        }];
        
    } else {
        
        self.isCurrentlyZoomedIn = NO;
        
        noteView.alpha = 1;
        
        // Ask focus view to save the note.
        [[NSNotificationCenter defaultCenter] postNotificationName:kSaveNoteNotification object:self];
        self.focus.view.alpha = 0;
        
        // Undim all note views.
        [self undimNoteViews];
    
        // Zoom out animation blocks.
        [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
            
            noteView.frame = noteView.originalCircleFrame;
            noteView.layer.backgroundColor = [UIColor clearColor].CGColor;
            noteView.layer.masksToBounds = NO;
            
        } completion:^(BOOL finished) {
            
            // Reset the zPosition back to default so it can be overlapped by other circles that are zooming in
            noteView.layer.zPosition = 0;
            noteView.layer.cornerRadius = 0;
            
            [self.collision addItem:noteView];
            [self.dynamicProperties addItem:noteView];
            
            noteView.note.positionX = [Coordinate normalizeXCoord:noteView.center.x withReferenceBounds:self.view.bounds];
            noteView.note.positionY = [Coordinate normalizeYCoord:noteView.center.y withReferenceBounds:self.view.bounds];
            [[Database sharedDatabase] save];
            
            if (self.shouldLoadCanvasAfterZoomOut) {
                [self loadCurrentCanvas];
                self.shouldLoadCanvasAfterZoomOut = NO;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNoteDismissedNotification object:self];
            
            // Remove original note circle location indicator
            if (self.originalNoteCircleIndicator) {
                [self.originalNoteCircleIndicator removeFromSuperview];
                self.originalNoteCircleIndicator = nil;
            }
            
            noteView.titleLabel.alpha = 1;
            
            self.isRunningZoomAnimation = NO;
            
            // Allows zoom after animation is completed
            [self.currentlyZoomedInNoteView setUserInteractionEnabled:YES];
            
            // Run completion block if there's one.
            if (zoomCompleted) {
                zoomCompleted();
            }
        }];
    }
}

-(void)createOriginalNoteCircleIndicator {
    self.originalNoteCircleIndicator = [[UIImageView alloc] initWithFrame:self.currentlyZoomedInNoteView.originalCircleFrame];
    self.originalNoteCircleIndicator.image = [UIImage imageNamed:@"circle"];
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, Key_NoteTitleLabelWidth, Key_NoteTitleLabelHeight)];
    titleLabel.center = CGPointMake(self.originalNoteCircleIndicator.frame.size.width/2.0, -Key_NoteTitleLabelHeight);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:14];
    [self.originalNoteCircleIndicator addSubview:titleLabel];
    [titleLabel setText:self.currentlyZoomedInNoteView.titleLabel.text];
    
    [self.view addSubview:self.originalNoteCircleIndicator];
}

-(void)dimNoteViews {
    for (UIView* view in self.view.subviews) {
        if ([view isKindOfClass:[NoteView class]]) {
            NoteView* noteView = (NoteView*)view;
            if (noteView != self.currentlyZoomedInNoteView) {
                noteView.titleLabel.textColor = [UIColor lightGrayColor];
                noteView.image = [UIImage imageNamed:@"circle-grey"];
            }
        }
    }
}

-(void)undimNoteViews {
    for (UIView* view in self.view.subviews) {
        if ([view isKindOfClass:[NoteView class]]) {
            NoteView* noteView = (NoteView*)view;
            if (noteView != self.currentlyZoomedInNoteView) {
                noteView.titleLabel.textColor = [UIColor blackColor];
                noteView.image = [UIImage imageNamed:@"circle"];
            }
        }
    }
}

#pragma mark - Orientation Changes Handling

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Remove behaviours to prevent the animator from setting the incorrect center positions for noteViews after we've already
    // calculated and set them. We're not sure why the animator does this, but we're doing a lot of custom view positioning,
    // and it could be a result of some custom view handling logic that don't play well with the animator.
    [self.animator removeAllBehaviors];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.isTrashMode) {
        self.emptyTrashButton.frame = [Coordinate frameWithCenterXByFactor:0.5 centerYByFactor:0.9 width:300 height:50 withReferenceBounds:self.view.bounds];
    } else {
        self.dragHandleView.center = CGPointMake(self.view.center.x, self.view.frame.size.height + 50);
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
            
            // Save new coordinates in the new device orientation.
            noteView.note.originalX = noteView.center.x;
            noteView.note.originalY = noteView.center.y;
            
            [[Database sharedDatabase] save];
        }
    }

    // Reposition the hidden zoomed in note view so that the unzoom can start from the same location as the focus view.
    if (self.isCurrentlyZoomedIn) {
        [self repositionZoomedInNoteView:self.currentlyZoomedInNoteView];
    } else {
        [self repositionFocusView];
    }
    
    // Restore the behaviours after orientation changes and calculations are completed.
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.dynamicProperties];
}

// Called when orientation changes to reposition note views.
-(void)updateNotesForBoundsChange {
    for (UIView* subview in self.view.subviews) {
        if ([subview isKindOfClass:[NoteView class]]) {
            [self returnNoteToBounds:(NoteView*)subview];
            [self updateLocationForNoteView:(NoteView*)subview];
        }
    }
}

// Used to force notes back into the canvas if they're getting outside.
-(void)returnNoteToBounds:(NoteView*)note {
    
    if (! CGRectContainsRect(self.view.bounds, note.frame)) {
        CGPoint center = note.center;
        
        if (note.frame.origin.y < 0) {
            center.y = Key_NoteRadius;
        } else if (CGRectGetMaxY(note.frame) > self.view.bounds.size.height) {
            center.y = self.view.bounds.size.height - Key_NoteRadius;
        }
        
        if (note.frame.origin.x < 0) {
            center.x = Key_NoteRadius;
        } else if (CGRectGetMaxX(note.frame) > self.view.bounds.size.width) {
            center.x = self.view.bounds.size.width - Key_NoteRadius;
        }
        
        note.center = CGPointMake(note.originalPositionX, note.originalPositionY);
        
        [self.animator updateItemUsingCurrentState:note];
        [[Database sharedDatabase] save];
    }
}

// Reposition note views when orientation changes.
-(void)updateLocationForNoteView:(NoteView*)noteView {
    CGPoint relativePosition = CGPointMake(noteView.note.positionX, noteView.note.positionY);
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:relativePosition withReferenceBounds:self.view.bounds];
    
    if (noteView.note.trashed == YES) {
        unnormalizedCenter = CGPointMake(noteView.note.originalX, noteView.note.originalY);
    }
    
    [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
}

-(CGPoint)findCenterOfScreen {
    // Self.view.superview == DrawerView, DrawerView's superview is the Container view, which has the correct and current bounds of the screen,
    // so we can use that to find the absolute center of the screen.
    return [self.view.superview.superview convertPoint:self.view.superview.superview.center fromView:self.view.superview.superview.superview];
}

// Called when orientation changes and we're zoomed in, therefore, update frames for both the focus view and the zoomed in note view.
-(void)repositionZoomedInNoteView:(NoteView*)noteView {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGPoint centerOfScreen = [self findCenterOfScreen];
    
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        [UIView animateWithDuration:0.5 animations:^{
            self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_LandscapeFocusViewAdjustment);
        } completion:^(BOOL finished) {
            noteView.frame = [self.focus.view convertRect:self.focus.view.bounds toView:self.view];
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_PortraitFocusViewAdjustment);
        } completion:^(BOOL finished) {
            noteView.frame = [self.focus.view convertRect:self.focus.view.bounds toView:self.view];
        }];
    }
}

// Called when orientation changes and we're not zoomed in, therefore, only update frame for the hidden focus view.
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

// Saves the new coordinates for the note views after a throw or after they're bumped.
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
