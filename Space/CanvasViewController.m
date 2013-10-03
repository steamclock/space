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
#import "NoteView.h"
#import "QBPopupMenu.h"
#import "Notifications.h"
#import "Constants.h"
#import "Coordinate.h"

@interface CanvasViewController ()

@property (nonatomic) UIDynamicAnimator* animator;
@property (nonatomic) UICollisionBehavior* collision;
@property (nonatomic) UIDynamicItemBehavior* dynamicProperties;
@property (nonatomic) UIDynamicItemBehavior* activeDrag;

@property (nonatomic) CGPoint noteOriginalPosition;

@property (nonatomic) BOOL simulating;

@property (nonatomic) NoteView* notePendingDelete;

@property (nonatomic) int currentCanvas;
@property (nonatomic) BOOL isTrashMode;

//almost-constant values that depend on the orientation and how the drawers are designed.
@property (nonatomic) int editY;
@property (nonatomic) int trashY;

@property (nonatomic) UIView* topLevelView;

@property (nonatomic) BOOL newNoteCreated;

@property (strong, nonatomic) UIButton* emptyTrashButton;

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
    //trash offset is relative to superview
    self.editY = self.view.bounds.size.height;
    self.trashY = trashY - self.view.frame.origin.y - 100;
}

- (void)emptyTrash {
    
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
    self.dynamicProperties.resistance = 8;

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
    }
    
    self.currentCanvas = 0;
    [self loadCurrentCanvas];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canvasChangedNotification:) name:kCanvasChangedNotification object:nil];
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
}

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
        NSLog(@"%d saved notes", [notes count]);
    }
    
    for(Note* note in notes) {
        [self addViewForNote:note];
    }
}

-(void)canvasChangedNotification:(NSNotification*)notification {

    self.currentCanvas = [notification.userInfo[Key_CanvasNumber] intValue];
    NSLog(@"Current canvas = %d", self.currentCanvas);
    
    [self loadCurrentCanvas];
}

#pragma mark - Add Notes

-(void)spaceTap:(UITapGestureRecognizer *)recognizer {
    
    Note* note = [[Database sharedDatabase] createNote];
    
    CGPoint position = [recognizer locationInView:self.view];
    NSLog(@"Creating a note at %@", NSStringFromCGPoint(position));
    
    note.canvas = self.currentCanvas;
    note.positionX = [Coordinate normalizeXCoord:position.x withReferenceBounds:self.view.bounds]; // position.x;
    note.positionY = [Coordinate normalizeYCoord:position.y withReferenceBounds:self.view.bounds]; // position.y;
    
    NSLog(@"Normalized X coord = %f", [Coordinate normalizeXCoord:position.x withReferenceBounds:self.view.bounds]);
    NSLog(@"Normalized Y coord = %f", [Coordinate normalizeYCoord:position.y withReferenceBounds:self.view.bounds]);
    
    NSLog(@"Unnormalized coord = %@", NSStringFromCGPoint([Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds]));
    
    self.newNoteCreated = YES;
    [self addViewForNote:note];
    
    [[Database sharedDatabase] save];
}

-(void)addViewForNote:(Note*)note {
    
    NoteView* imageView = [[NoteView alloc] initWithImage:[UIImage imageNamed:@"Circle"]];
    imageView.animator = self.animator;
    CGPoint unnomralizedCenter = [Coordinate unnormalizePoint:CGPointMake(note.positionX, note.positionY) withReferenceBounds:self.view.bounds];
    [imageView setCenter:unnomralizedCenter withReferenceBounds:self.view.bounds];
    
    NSLog(@"Note position X = %f", note.positionX);
    NSLog(@"Note position Y = %f", note.positionY);
    NSLog(@"Adding note at %@", NSStringFromCGPoint(imageView.center));
    
    // If this is a trashed note, "flip" its y-coordinate so that for example, if it was originally 80% down the y-coordinate in the top canvas,
    // it should only be roughly 20% down in the bottom canvas.
    if (note.trashed == YES && note.draggedToTrash != YES) {
        unnomralizedCenter.y = self.view.bounds.size.height - unnomralizedCenter.y;
        [imageView setCenter:unnomralizedCenter withReferenceBounds:self.view.bounds];
    } else if (note.draggedToTrash == YES) {
        // If this note was manually dragged to trash, place it near the top
        unnomralizedCenter.y = NOTE_RADIUS;
        [imageView setCenter:unnomralizedCenter withReferenceBounds:self.view.bounds];
    }
    
    imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(noteTap:)];
    [imageView addGestureRecognizer:tapGestureRecognizer];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(noteDrag:)];
    [imageView addGestureRecognizer:panGestureRecognizer];

    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(noteLongPress:)];
    [imageView addGestureRecognizer:longPress];

    [self.view addSubview:imageView];
    [self.collision addItem:imageView];
    [self.dynamicProperties addItem:imageView];

    imageView.note = note;
    
    if (self.newNoteCreated == YES) {
        [self.focus focusOn:imageView withTouchPoint:unnomralizedCenter];
        [[NSNotificationCenter defaultCenter] postNotificationName:kFocusNoteNotification object:self];
        self.newNoteCreated = NO;
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

- (void)recoverNote:(NoteView*)noteView {
    
    NSDictionary* noteToRecoverInfo = [[NSDictionary alloc] initWithObjects:@[noteView.note, [NSValue valueWithCGPoint:self.noteOriginalPosition]] forKeys:@[Key_RecoveredNote, @"originalPosition"]];
    
    NSNotification* noteRecoveredNotification = [[NSNotification alloc] initWithName:kNoteRecoveredNotification object:self userInfo:noteToRecoverInfo];
    [[NSNotificationCenter defaultCenter] postNotification:noteRecoveredNotification];
    
    [noteView removeFromSuperview];
    
    [self.collision removeItem:noteView];
    [self.dynamicProperties removeItem:noteView];
}

- (void)noteRecoveredNotification:(NSNotification*)notification {
   
    Note* recoveredNote = [notification.userInfo objectForKey:Key_RecoveredNote];
    NSValue *originalPosition = [notification.userInfo objectForKey:@"originalPosition"];
    
    CGPoint originalCenter = [originalPosition CGPointValue];
    
    NSLog(@"Recovered note position X = %f",originalCenter.x);
    NSLog(@"Recovered note position Y = %f",originalCenter.y);
    
    recoveredNote.positionX = [Coordinate normalizeXCoord:originalCenter.x withReferenceBounds:self.view.bounds];
    recoveredNote.positionY = [Coordinate normalizeYCoord:originalCenter.y withReferenceBounds:self.view.bounds];
    
    [self addViewForNote:recoveredNote];
    
    recoveredNote.trashed = NO;
    
    [[Database sharedDatabase] save];
}

#pragma mark - Focus Notes

-(void)noteTap: (UITapGestureRecognizer *)recognizer {
    
    NoteView* view = (NoteView*)recognizer.view;
    
    // Prevents double tap
    [view setUserInteractionEnabled:NO];
    
    [self.focus focusOn:view withTouchPoint:[recognizer locationInView:self.topLevelView]];
    NSLog(@"Point of touch = %@", NSStringFromCGPoint([recognizer locationInView:self.topLevelView]));
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kFocusNoteNotification object:self];
}

#pragma mark - Drag Notes

-(void)noteDrag:(UIPanGestureRecognizer*)recognizer {
    
    NoteView* view = (NoteView*)recognizer.view;
    CGPoint drag = [recognizer locationInView:self.view];
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        self.activeDrag = [[UIDynamicItemBehavior alloc] init];
        self.activeDrag.density = 1000000.0f;
        [self.animator addBehavior:self.activeDrag];
        [self.activeDrag addItem:view];
        
        if (!CGPointEqualToPoint(self.noteOriginalPosition, view.center)) {
            self.noteOriginalPosition = view.center;
        }
    }
    
    [view setCenter:drag withReferenceBounds:self.view.bounds];
    
    //clean up the drag operation (and ONLY the drag operation. do all other ending actions below the isTrashMode check)
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        [view setBackgroundColor:[UIColor clearColor]];
        [self.activeDrag removeItem:view];
        [self.animator removeBehavior:self.activeDrag];
        self.activeDrag = nil;
    }
    
    if (self.isTrashMode) {
        
        if (view.center.y < self.trashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [self returnNoteToBounds:view];
                [self recoverNote:view];
            } else {
                [view setBackgroundColor:[UIColor greenColor]];
            }
        } else if(recognizer.state == UIGestureRecognizerStateEnded) {
            [[Database sharedDatabase] save];
            CGPoint velocity = [recognizer velocityInView:self.view];
            [self.dynamicProperties addLinearVelocity:CGPointMake(velocity.x, velocity.y) forItem:view];
        } else {
            [view setBackgroundColor:[UIColor clearColor]];
        }
        
    } else {
        
        if (view.center.y > self.trashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [self deleteNoteWithoutAsking:view];
            } else {
                [view setBackgroundColor:[UIColor greenColor]];
            }
        } else if (view.center.y > self.editY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [self returnNoteToBounds:view];
                [self.focus focusOn:view withTouchPoint:CGPointZero];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kFocusNoteNotification object:self];
            } else {
                [view setBackgroundColor:[UIColor greenColor]];
            }
        } else {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [[Database sharedDatabase] save];
                CGPoint velocity = [recognizer velocityInView:self.view];
                [self.dynamicProperties addLinearVelocity:CGPointMake(velocity.x, velocity.y) forItem:view];
            } else {
                [view setBackgroundColor:[UIColor clearColor]];
            }
        }
    }
}

#pragma mark - Orientation Changes Handling

-(void)updateNotesForBoundsChange {
    
    NSLog(@"New bounds = %@", NSStringFromCGRect(self.view.bounds));
    
    for (UIView* subview in self.view.subviews) {
        
        if ([subview isKindOfClass:[NoteView class]]) {
            [self returnNoteToBounds:(NoteView*)subview];
            [self updateLocationForNoteView:(NoteView*)subview];
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
        
        NSLog(@"move from %@ to %@", NSStringFromCGPoint(note.center), NSStringFromCGPoint(center));
        // note.center = center;
        
        note.center = self.noteOriginalPosition;
        
        [self.animator updateItemUsingCurrentState:note];
        [[Database sharedDatabase] save];
    }
}

-(void)updateLocationForNoteView:(NoteView*)noteView {
    
    CGPoint relativePosition = CGPointMake(noteView.note.positionX, noteView.note.positionY);
    NSLog(@"Relative position = %@", NSStringFromCGPoint(relativePosition));
    
    CGPoint unnormalizedCenter = [Coordinate unnormalizePoint:relativePosition withReferenceBounds:self.view.bounds];
    [noteView setCenter:unnormalizedCenter withReferenceBounds:self.view.bounds];
    NSLog(@"New actual center = %@", NSStringFromCGPoint(noteView.center));    
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    // Remove behaviours to prevent the animator from setting the incorrect center positions for noteViews after we've already
    // calculated and set them. We're not sure why the animator does this, but we're doing a lot of custom view positioning,
    // and it could be a result of some custom view handling logic that don't play well with the animator.
    [self.animator removeAllBehaviors];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    // Restore the behaviours after orientation changes and calculations are completed.
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.dynamicProperties];
    
    if (self.isTrashMode) {
        self.emptyTrashButton.frame = [Coordinate frameWithCenterXByFactor:0.5 centerYByFactor:0.9 width:300 height:50 withReferenceBounds:self.view.bounds];
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
        }
    }
}

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    
}

@end
