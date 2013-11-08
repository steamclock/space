//
//  CanvasViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasViewController.h"
#import "DrawerViewController.h"
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
@property (nonatomic) UIDynamicItemBehavior* circleBehavior;

@property (nonatomic) NoteView* notePendingDelete;
@property (nonatomic) NoteView* draggedNote;

@property (nonatomic) int currentCanvas;
@property (nonatomic) BOOL isTrashMode;

@property (nonatomic) int triggerTrashY;

@property (weak, nonatomic) UIView* topLevelView;
@property (strong, nonatomic) UIButton* emptyTrashButton;

@end

static BOOL isDeleting;
static BOOL dragToTrashRequested;
static BOOL dragHandleIsPointUp;
static BOOL isRotating;

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

-(void)addBoundariesForCanvas {
    [self.collision addBoundaryWithIdentifier:@"canvasTop"
                                    fromPoint:CGPointMake(0,0)
                                      toPoint:CGPointMake(self.view.frame.size.width, 0)];
    
    [self.collision addBoundaryWithIdentifier:@"canvasLeft"
                                    fromPoint:CGPointMake(0,0)
                                      toPoint:CGPointMake(0, self.view.frame.size.height)];
    
    [self.collision addBoundaryWithIdentifier:@"canvasRight"
                                    fromPoint:CGPointMake(self.view.frame.size.width,0)
                                      toPoint:CGPointMake(self.view.frame.size.width, self.view.frame.size.height)];
    
    [self.collision addBoundaryWithIdentifier:@"canvasBottom"
                                    fromPoint:CGPointMake(0, self.view.frame.size.height)
                                      toPoint:CGPointMake(self.view.frame.size.width, self.view.frame.size.height)];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;

    self.collision = [[UICollisionBehavior alloc] init];
    self.circleBehavior = [[UIDynamicItemBehavior alloc] init];
    self.circleBehavior.allowsRotation = NO;
    self.circleBehavior.resistance = 10;

    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.circleBehavior];

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flipHandleBarUp:) name:kFlipHandleBarUpNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flipHandleBarDown:) name:kFlipHandleBarDownNotification object:nil];
        dragHandleIsPointUp = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canvasChanged:) name:kCanvasChangedNotification object:nil];
    
    self.zoomAnimationDuration = 0.18;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Load last selected canvas.
    self.currentCanvas = [[[NSUserDefaults standardUserDefaults] objectForKey:Key_CanvasNumber] intValue];
    [self loadCurrentCanvas];
    
    [self addBoundariesForCanvas];
    
    if (self.isTrashMode == NO) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:Key_AppInstalled] == nil) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:Key_AppInstalled];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self createDefaultNote];
        }
    }
    
    // Helps reposition the create note label at the center of the screen, because at the point where we want to
    // create this label, the top canvas view isn't properly initialized yet, so the bounds were a bit off at that time.
    if (self.drawer.topDrawerContents.createNoteLabel != nil) {
        self.drawer.topDrawerContents.createNoteLabel.frame = [Coordinate frameWithCenterXByFactor:0.5
                                                                                   centerYByFactor:0.5
                                                                                             width:self.drawer.topDrawerContents.createNoteLabel.frame.size.width
                                                                                            height:self.drawer.topDrawerContents.createNoteLabel.frame.size.height
                                                                               withReferenceBounds:self.drawer.topDrawerContents.view.bounds];
    }
}

-(void)setTrashThreshold:(int)trashY {
    self.triggerTrashY = trashY - self.view.frame.origin.y - 100;
}

#pragma mark - Change Canvas

-(void)loadCurrentCanvas {
    [self showCreateNoteLabel];
    
    for(UIView* view in self.view.subviews) {
        if (view != self.drawer.topDrawerContents.createNoteLabel && view != self.dragHandleView) {
            [self.collision removeItem:view];
            [self.circleBehavior removeItem:view];
            [view removeFromSuperview];
        }
    }
    
    NSArray* notes;
    
    if (self.isTrashMode) {
        notes = [[Database sharedDatabase] trashedNotesInCanvas:self.currentCanvas];
        NSLog(@"Number of deleted notes = %d", [notes count]);
        
        UIImage* trashBinImage = [[UIImage imageNamed:Img_TrashBin] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.emptyTrashButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.emptyTrashButton setImage:trashBinImage forState:UIControlStateNormal];
        self.emptyTrashButton.frame = [Coordinate frameWithCenterXByFactor:0.5 centerYByFactor:0.9 width:300 height:50 withReferenceBounds:self.view.bounds];
        [self.emptyTrashButton addTarget:self action:@selector(emptyTrash) forControlEvents:UIControlEventTouchUpInside];
        [self.emptyTrashButton setTitle:@"Empty Trash" forState:UIControlStateNormal];
        
        [self.view addSubview:self.emptyTrashButton];
        
    } else {
        notes = [[Database sharedDatabase] notesInCanvas:self.currentCanvas];
        NSLog(@"Number of saved notes = %d", [notes count]);
        
        if (self.dragHandleView == nil) {
            UIImage* handlebarDownImage = [UIImage imageNamed:Img_HandlebarDown];
            self.dragHandleView = [[UIImageView alloc] initWithImage:handlebarDownImage];
            self.dragHandleView.center = CGPointMake(self.view.center.x, self.view.frame.size.height + 40);
        
            [self.view addSubview:self.dragHandleView];
        }
    }
    
    for(Note* note in notes) {
        [self addViewForNote:note];
    }
    
    self.isRunningZoomAnimation = NO;    
}

-(void)canvasChanged:(NSNotification*)notification {
    self.currentCanvas = [notification.userInfo[Key_CanvasNumber] intValue];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:self.currentCanvas] forKey:Key_CanvasNumber];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.isCurrentlyZoomedIn) {
        self.isRefocus = NO;
        self.loadCurrentCanvasAfterAnimation = YES;
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
    } else {
        [self loadCurrentCanvas];
    }
}

#pragma mark - Flip Handle Bar

-(void)flipHandleBarUp:(NSNotification*)notification {
    if (dragHandleIsPointUp == NO) {
        [UIView animateWithDuration:0.1 animations:^{
            self.dragHandleView.transform = CGAffineTransformIdentity;
        }];
        dragHandleIsPointUp = YES;
    }
}

-(void)flipHandleBarDown:(NSNotification*)notification {
    if (dragHandleIsPointUp) {
        [UIView animateWithDuration:0.1 animations:^{
            self.dragHandleView.transform = CGAffineTransformMakeScale(1, -1);
        }];
        dragHandleIsPointUp = NO;
    }
}

#pragma mark - Drag Notes

static BOOL dragStarted = NO;

-(void)noteDrag:(UIPanGestureRecognizer*)recognizer {
    // Don't allow note drag if we're currently zoomed in, which can cause problematic behaviours
    if (self.isCurrentlyZoomedIn) {
        return;
    }
    
    if ([self.animator.behaviors containsObject:self.circleBehavior] == NO) {
        [self.animator addBehavior:self.circleBehavior];
    }
    
    [self.collision removeAllBoundaries];
    
    NoteView* noteView = (NoteView*)recognizer.view;
    self.draggedNote = noteView;
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
    
    // Prevents dragging across the boundaries.
    if (self.isTrashMode) {
        
        if (noteView.center.y >= self.view.frame.size.height - Key_NoteRadius && noteView.center.x >= self.view.frame.size.width - Key_NoteRadius) {
            [noteView setCenter:CGPointMake(self.view.frame.size.width - Key_NoteRadius, self.view.frame.size.height - Key_NoteRadius) withReferenceBounds:self.view.bounds];
        } else if (noteView.center.y >= self.view.frame.size.height - Key_NoteRadius && noteView.center.x <= Key_NoteRadius) {
            [noteView setCenter:CGPointMake(Key_NoteRadius, self.view.frame.size.height - Key_NoteRadius) withReferenceBounds:self.view.bounds];
        } else if (noteView.center.y >= self.view.frame.size.height - Key_NoteRadius) {
            [noteView setCenter:CGPointMake(drag.x, self.view.frame.size.height - Key_NoteRadius) withReferenceBounds:self.view.bounds];
        } else if (noteView.center.x >= self.view.frame.size.width - Key_NoteRadius) {
            [noteView setCenter:CGPointMake(self.view.frame.size.width - Key_NoteRadius, drag.y) withReferenceBounds:self.view.bounds];
        } else if (noteView.center.x <= Key_NoteRadius) {
            [noteView setCenter:CGPointMake(Key_NoteRadius, drag.y) withReferenceBounds:self.view.bounds];
        }
        
    } else {
        
        if (noteView.center.y <= Key_NoteRadius && noteView.center.x >= self.view.frame.size.width - Key_NoteRadius) {
            [noteView setCenter:CGPointMake(self.view.frame.size.width - Key_NoteRadius, Key_NoteRadius) withReferenceBounds:self.view.bounds];
        } else if (noteView.center.y <= Key_NoteRadius && noteView.center.x <= Key_NoteRadius) {
            [noteView setCenter:CGPointMake(Key_NoteRadius, Key_NoteRadius) withReferenceBounds:self.view.bounds];
        } else if (noteView.center.y <= Key_NoteRadius) {
            [noteView setCenter:CGPointMake(drag.x, Key_NoteRadius) withReferenceBounds:self.view.bounds];
        } else if (noteView.center.x >= self.view.frame.size.width - Key_NoteRadius) {
            [noteView setCenter:CGPointMake(self.view.frame.size.width - Key_NoteRadius, drag.y) withReferenceBounds:self.view.bounds];
        } else if (noteView.center.x <= Key_NoteRadius) {
            [noteView setCenter:CGPointMake(Key_NoteRadius, drag.y) withReferenceBounds:self.view.bounds];
        }
    }
    
    // Handle drag within the trash canvas.
    if (self.isTrashMode) {
        // If a trashed note in the trashed canvas is dragged above the trashY threshold, allow recovering note.
        if (noteView.center.y < self.triggerTrashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [self returnNoteToBounds:noteView];
                [self recoverNote:noteView];
            } else {
                [noteView setImage:[UIImage imageNamed:@"circle-green"]];
            }
        } else {
            // Add throw at the end of drag.
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [[Database sharedDatabase] save];
                CGPoint velocity = [recognizer velocityInView:self.view];
                [self.circleBehavior addLinearVelocity:CGPointMake(velocity.x, velocity.y) forItem:noteView];
            } else {
                [noteView setImage:[UIImage imageNamed:@"circle"]];
            }
        }
    // Handle drag within the note canvas.
    } else {
        // If a note is dragged below the trashY threshold, allow trashing note.
        if (noteView.center.y > self.triggerTrashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                dragToTrashRequested = YES;
                [self deleteNoteWithoutAsking:noteView];
            } else {
                [noteView setImage:[UIImage imageNamed:@"circle-red"]];
            }
        } else {
            // Add throw at the end of drag.
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [[Database sharedDatabase] save];
                CGPoint velocity = [recognizer velocityInView:self.view];
                [self.circleBehavior addLinearVelocity:CGPointMake(velocity.x, velocity.y) forItem:noteView];
            } else {
                [noteView setImage:[UIImage imageNamed:@"circle"]];
            }
        }
    }
    
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        dragStarted = NO;

        [self addBoundariesForCanvas];
        
        if (dragToTrashRequested == NO) {
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
    note.recovering = NO;
    
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
    
    [self showCreateNoteLabel];
    
    NoteView* noteView = [[NoteView alloc] initWithImage:[UIImage imageNamed:@"circle"]];
    noteView.animator = self.animator;
    
    // Retrieve the actual center using the stored relative position.
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds];
    [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
    
    // If this is a trashed note, "flip" its y-coordinate so that for example, if it was originally 80% down the y-coordinate in the top canvas,
    // it should only be roughly 20% down in the bottom canvas.
    if (self.isTrashMode && dragToTrashRequested == NO && isDeleting) {
        
        unnormalizedCenter.y = self.view.bounds.size.height - unnormalizedCenter.y;
        [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
        
    } else if (self.isTrashMode && dragToTrashRequested && isDeleting) {
        
        // If this note was manually dragged to trash, place it under the drag handle.
        [noteView setCenter:CGPointMake(note.originalX, Key_NoteRadius * 2) withReferenceBounds:self.view.bounds];
        note.originalX = noteView.center.x;
        note.originalY = noteView.center.y;
        
        [[Database sharedDatabase] save];
        
    } else if (note.recovering == [[NSNumber numberWithBool:YES] intValue]) {
        
        // If this note was dragged to recover, place it just above the drag handle.
        [noteView setCenter:CGPointMake(note.originalX, self.view.frame.size.height - Key_NoteRadius * 2) withReferenceBounds:self.view.bounds];
        note.originalX = noteView.center.x;
        note.originalY = noteView.center.y;
        
        [[Database sharedDatabase] save];
    }
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(noteTap:)];
    [noteView addGestureRecognizer:tapGestureRecognizer];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(noteDrag:)];
    [noteView addGestureRecognizer:panGestureRecognizer];

    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(noteLongPress:)];
    [noteView addGestureRecognizer:longPress];

    [self.view addSubview:noteView];
    [self.collision addItem:noteView];
    [self.circleBehavior addItem:noteView];

    noteView.note = note;
    
    if (self.isTrashMode == NO && self.noteCreated == YES) {
        self.newlyCreatedNoteView = noteView;
        
        // Notify to initiate auto zoom in after a note has been created.
        self.shouldZoomInAfterCreatingNewNote = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNoteCreatedNotification object:self];
        
        // Note creation complete, reset the flag.
        self.noteCreated = NO;
    }
    
    noteView.userInteractionEnabled = YES;
}

-(void)noteCreated:(NSNotification*)notification {
    if (self.newlyCreatedNoteView != nil) {
        self.currentlyZoomedInNoteView = self.newlyCreatedNoteView;
        self.currentlyZoomedInNoteView.originalCircleFrame = self.newlyCreatedNoteView.frame;
        [self zoomNote:self.newlyCreatedNoteView];
    }
}

-(void)createDefaultNote {
    Note* note = [[Database sharedDatabase] createNote];
    
    note.recovering = NO;
    note.canvas = self.currentCanvas;
    
    note.title = @"About Space";
    note.content = @"About Space\n\nSpace is an experimental note board with the ability to jot down thoughts and plans, arrange them, and discard them once they are complete.";
    
    note.positionX = 0.5;
    note.positionY = 0.25;
    
    // Store current and actual location of the newly created note.
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds];
    note.originalX = unnormalizedCenter.x;
    note.originalY = unnormalizedCenter.y;
    
    // Draw the note as a note view in the canvas.
    [self addViewForNote:note];
    
    [[Database sharedDatabase] save];
}

-(void)showCreateNoteLabel {
    NSArray* notes = [[Database sharedDatabase] notesInCanvas:self.currentCanvas];
    
    if ([notes count] <= 3) {
        if (self.drawer.topDrawerContents.createNoteLabel == nil) {
            self.drawer.topDrawerContents.createNoteLabel = [[UILabel alloc] init];
            
            [self.drawer.topDrawerContents.createNoteLabel setText:@"Tap anywhere to create a note"];
            [self.drawer.topDrawerContents.createNoteLabel setTextColor:[UIColor lightGrayColor]];
            [self.drawer.topDrawerContents.createNoteLabel sizeToFit];
            
            self.drawer.topDrawerContents.createNoteLabel.frame = [Coordinate frameWithCenterXByFactor:0.5
                                                                                       centerYByFactor:0.5
                                                                                                 width:self.drawer.topDrawerContents.createNoteLabel.frame.size.width
                                                                                                height:self.drawer.topDrawerContents.createNoteLabel.frame.size.height
                                                                                   withReferenceBounds:self.drawer.topDrawerContents.view.bounds];
            
            [self.drawer.topDrawerContents.view addSubview:self.drawer.topDrawerContents.createNoteLabel];
        }
    } else {
        [self.drawer.topDrawerContents.createNoteLabel removeFromSuperview];
        self.drawer.topDrawerContents.createNoteLabel = nil;
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
    isDeleting = YES;
    
    Note* note = self.notePendingDelete.note;
    [note markAsTrashed];
    
    [self.collision removeItem:self.notePendingDelete];
    [self.circleBehavior removeItem:self.notePendingDelete];
    
    if (self.isTrashMode) { // Remove it permanentely and instantly.
        [self.notePendingDelete removeFromSuperview];
        self.notePendingDelete = nil;
        
        [note removeFromDatabase];
        [[Database sharedDatabase] save];
        
    } else if (dragToTrashRequested == NO) {
        [self dropNoteToTrash:note];
    } else {
        [self dropNoteToTrash:note];
        /* // Alternative drag to trash behaviour in which we just remove the note view.
        [self.notePendingDelete removeFromSuperview];
        self.notePendingDelete = nil;
        
        NSDictionary* deletedNoteInfo = [[NSDictionary alloc] initWithObjects:@[note] forKeys:@[Key_TrashedNotes]];
        
        NSNotification* noteTrashedNotification = [[NSNotification alloc] initWithName:kNoteTrashedNotification
                                                                                object:self
                                                                              userInfo:deletedNoteInfo];
        
        [[NSNotificationCenter defaultCenter] postNotification:noteTrashedNotification];
        */
    }
}

-(void)dropNoteToTrash:(Note*)note {
    self.isDroppingNoteForDeletion = YES;
    
    // Have the note fall down, and once it's fallen below a certain point, remove it, and draw the trashed note in the trash canvas.
    UIGravityBehavior *trashDrop = [[UIGravityBehavior alloc] initWithItems:@[self.notePendingDelete]];
    trashDrop.gravityDirection = CGVectorMake(0, 10);
    [self.animator addBehavior:trashDrop];
    
    __weak CanvasViewController* weakSelf = self;
    
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds];
    unnormalizedCenter.y = self.view.bounds.size.height - unnormalizedCenter.y;
    
    self.notePendingDelete.offscreenYDistance = self.view.bounds.size.height + unnormalizedCenter.y + 100;
    
    self.notePendingDelete.onDropOffscreen = ^{
        [weakSelf.animator removeBehavior:trashDrop];
        [weakSelf.notePendingDelete removeFromSuperview];
        weakSelf.notePendingDelete = nil;
        
        NSDictionary* deletedNoteInfo = [[NSDictionary alloc] initWithObjects:@[note] forKeys:@[Key_TrashedNotes]];
        
        NSNotification* noteTrashedNotification = [[NSNotification alloc] initWithName:kNoteTrashedNotification
                                                                                object:weakSelf
                                                                              userInfo:deletedNoteInfo];
        
        [[NSNotificationCenter defaultCenter] postNotification:noteTrashedNotification];
        
        weakSelf.isDroppingNoteForDeletion = NO;
    };
}

-(void)addTrashedNote:(NSNotification*)notification {
    if (self.isTrashMode) {
        Note* trashedNote = [notification.userInfo objectForKey:Key_TrashedNotes];
        [self addViewForNote:trashedNote];
        [[Database sharedDatabase] save];
        
        isDeleting = NO;
        dragToTrashRequested = NO;
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
    noteView.note.recovering = YES;
    [[Database sharedDatabase] save];
    
    // Remove the recovering note from the trashed canvas.
    [noteView removeFromSuperview];
    [self.collision removeItem:noteView];
    [self.circleBehavior removeItem:noteView];
    
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
    
    recoveredNote.trashed = NO;
    
    [self addViewForNote:recoveredNote];
    
    recoveredNote.recovering = NO;
    [[Database sharedDatabase] save];
}

#pragma mark - Focus Notes

-(void)noteTap:(UITapGestureRecognizer *)recognizer {
    
    NoteView* noteView = (NoteView*)recognizer.view;
    
    if (noteView == self.currentlyZoomedInNoteView && self.isRunningZoomAnimation == NO) {
        self.isRefocus = NO;
        self.hasRefocused = NO;
    } else if (self.animator.isRunning && self.isRunningZoomAnimation == NO) {
        // Stop the animator if a note is tapped when it's still got some velocity and is still sliding.
        [self.animator removeBehavior:self.circleBehavior];
    } else if (self.animator.running || self.isRunningZoomAnimation) {
        // Don't allow focus if the animator is still running, or if a zoom animation is still animating.
        return;
    }
    
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
        
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:^(void) {
            self.currentlyZoomedInNoteView = noteView;
            
            if (self.isCurrentlyZoomedIn == NO) {
                self.currentlyZoomedInNoteView.originalCircleFrame = self.currentlyZoomedInNoteView.frame;
            }
            
            [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
        }];
    } else {
        self.currentlyZoomedInNoteView = noteView;
        
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
    if ([self.animator isRunning] || self.isRunningZoomAnimation) {
        return;
    } else {
        [self toggleZoomForNoteView:self.currentlyZoomedInNoteView completion:nil];
    }
}

-(void)toggleZoomForNoteView:(NoteView*)noteView completion:(void (^)(void))zoomCompleted {
    self.isRunningZoomAnimation = YES;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (self.isCurrentlyZoomedIn) {
        noteView = self.currentlyZoomedInNoteView;
    }
    
    // Zoom in if we're not currently zoomed in, or if a new note has just been created.
    if (self.isCurrentlyZoomedIn == NO || self.shouldZoomInAfterCreatingNewNote == YES) {
        noteView.originalPositionX = noteView.note.positionX;
        noteView.originalPositionY = noteView.note.positionY;
        
        // Cannot transform properly when the view is being controlled by the animator.
        [self.collision removeItem:noteView];
        [self.circleBehavior removeItem:noteView];
        
        self.isCurrentlyZoomedIn = YES;
        self.shouldZoomInAfterCreatingNewNote = NO;
        
        // Create a temporary circle view that will be used for the zoom animation.
        [self createNoteCircleForZoom];
        
        // Dim all note views.
        [self dimNoteViews];
        
        // Zoom in animation blocks.
        [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
            self.noteCircleForZoom.image = [self.noteCircleForZoom.image resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30) resizingMode:UIImageResizingModeStretch];
            self.noteCircleForZoom.frame = [self.focus.view convertRect:self.focus.view.bounds toView:self.view];
            self.noteCircleForZoom.layer.cornerRadius = Key_NoteRadius;
            self.noteCircleForZoom.layer.backgroundColor = [UIColor whiteColor].CGColor;
            self.noteCircleForZoom.layer.masksToBounds = YES;
            
            CGPoint centerOfScreen = [self findCenterOfScreen];
            
            if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
                self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_LandscapeFocusViewAdjustment);
            } else {
                self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_PortraitFocusViewAdjustment);
            }
            
        } completion:^(BOOL finished) {
            // Show editor.
            [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
                self.focus.view.alpha = 1;
                [self.focus focusOn:noteView];
            } completion:^(BOOL finished) {
                self.noteCircleForZoom.alpha = 0;
                
                self.noteCircleForZoom.autoresizingMask =
                UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kFocusNoteNotification object:self];
            }];
        }];
        
    } else {
        
        self.isCurrentlyZoomedIn = NO;
        
        self.noteCircleForZoom.alpha = 1;
        
        // Ask focus view to save the note.
        [[NSNotificationCenter defaultCenter] postNotificationName:kSaveNoteNotification object:self];
        self.focus.view.alpha = 0;
        
        // Undim all note views.
        [self undimNoteViews];
    
        // Zoom out animation blocks.
        [UIView animateWithDuration:self.zoomAnimationDuration animations:^{
        
            self.noteCircleForZoom.frame = noteView.originalCircleFrame;
            self.noteCircleForZoom.layer.backgroundColor = [UIColor clearColor].CGColor;
            self.noteCircleForZoom.layer.masksToBounds = NO;
            
        } completion:^(BOOL finished) {
            
            self.isRunningZoomAnimation = NO;
            
            // If canvas has been switched, can't add to animator because noteview isn't in the canvas view any more
            if([noteView superview]) {
                [self.collision addItem:noteView];
                [self.circleBehavior addItem:noteView];
            }
            
            noteView.note.positionX = [Coordinate normalizeXCoord:noteView.center.x withReferenceBounds:self.view.bounds];
            noteView.note.positionY = [Coordinate normalizeYCoord:noteView.center.y withReferenceBounds:self.view.bounds];
            [[Database sharedDatabase] save];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNoteDismissedNotification object:self];
            
            // Remove duplicate note circle that was used for the zoom animation.
            if (self.noteCircleForZoom) {
                [self.noteCircleForZoom removeFromSuperview];
                self.noteCircleForZoom = nil;
            }
            
            // Run completion block if there's one.
            if (zoomCompleted) {
                zoomCompleted();
            }
        }];
    }
}

-(void)createNoteCircleForZoom {
    self.noteCircleForZoom = [[UIImageView alloc] initWithFrame:self.currentlyZoomedInNoteView.originalCircleFrame];
    self.noteCircleForZoom.image = [UIImage imageNamed:@"circle"];
    
    [self.view addSubview:self.noteCircleForZoom];
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
    isRotating = YES;
    
    // Remove behaviours to prevent the animator from setting the incorrect center positions for noteViews after we've already
    // calculated and set them. We're not sure why the animator does this, but we're doing a lot of custom view positioning,
    // and it could be a result of some custom view handling logic that don't play well with the animator.
    if (self.animator) {
        [self.collision removeAllBoundaries];
        [self.animator removeAllBehaviors];
    }
    self.animator = nil;
    self.collision = nil;
    self.circleBehavior = nil;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.isTrashMode) {
        self.emptyTrashButton.frame = [Coordinate frameWithCenterXByFactor:0.5 centerYByFactor:0.9 width:300 height:50 withReferenceBounds:self.view.bounds];
    } else {
        self.dragHandleView.center = CGPointMake(self.view.center.x, self.view.frame.size.height + 40);
    }
    
    if (self.isCurrentlyZoomedIn) {
        self.currentlyZoomedInNoteView.originalCircleFrame = [Coordinate frameWithCenterXByFactor:self.currentlyZoomedInNoteView.originalPositionX
                                                                                  centerYByFactor:self.currentlyZoomedInNoteView.originalPositionY
                                                                                            width:self.currentlyZoomedInNoteView.originalCircleFrame.size.width
                                                                                           height:self.currentlyZoomedInNoteView.originalCircleFrame.size.height
                                                                              withReferenceBounds:self.view.bounds];
        
        self.noteCircleForZoom.frame = self.currentlyZoomedInNoteView.originalCircleFrame;
    }
    
    self.drawer.topDrawerContents.createNoteLabel.frame = [Coordinate frameWithCenterXByFactor:0.5
                                                                               centerYByFactor:0.5
                                                                                         width:self.drawer.topDrawerContents.createNoteLabel.frame.size.width
                                                                                        height:self.drawer.topDrawerContents.createNoteLabel.frame.size.height
                                                                           withReferenceBounds:self.drawer.topDrawerContents.view.bounds];
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
    
    // Restore the physics after orientation changes and calculations are completed.
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;
    
    self.collision = [[UICollisionBehavior alloc] init];
    self.circleBehavior = [[UIDynamicItemBehavior alloc] init];
    self.circleBehavior.allowsRotation = NO;
    self.circleBehavior.resistance = 10;
    
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.circleBehavior];
    
    for (UIView* subview in self.view.subviews) {
        if ([subview isKindOfClass:[NoteView class]]) {
            NoteView* noteView = (NoteView*)subview;
            noteView.animator = self.animator;
            
            [self.collision addItem:noteView];
            [self.circleBehavior addItem:noteView];
        }
    }
    
    isRotating = NO;
    
    [self addBoundariesForCanvas];
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
    
    if (note == self.draggedNote || isRotating) {
        return;
    }
    
    if (! CGRectContainsRect(self.view.bounds, note.frame)) {
        CGPoint center = note.center;
        
        if (note.frame.origin.y < 0) {
            center.y = Key_NoteRadius * 2;
        } else if (CGRectGetMaxY(note.frame) > self.view.bounds.size.height) {
            center.y = self.view.bounds.size.height - Key_NoteRadius * 2;
        }
        
        if (note.frame.origin.x < 0) {
            center.x = Key_NoteRadius * 2;
        } else if (CGRectGetMaxX(note.frame) > self.view.bounds.size.width) {
            center.x = self.view.bounds.size.width - Key_NoteRadius * 2;
        }
        
        note.center = center;
        
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
            self.noteCircleForZoom.frame = [self.focus.view convertRect:self.focus.view.bounds toView:self.view];
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.focus.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_PortraitFocusViewAdjustment);
        } completion:^(BOOL finished) {
            self.noteCircleForZoom.frame = [self.focus.view convertRect:self.focus.view.bounds toView:self.view];
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
            
            [self returnNoteToBounds:noteView];
            
            [[Database sharedDatabase] save];
        }
    }
}

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
}

@end
