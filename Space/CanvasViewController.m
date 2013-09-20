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

@interface CanvasViewController ()

@property (nonatomic) UIDynamicAnimator* animator;
@property (nonatomic) UICollisionBehavior* collision;
@property (nonatomic) UIDynamicItemBehavior* dynamicProperties;
@property (nonatomic) UIDynamicItemBehavior* activeDrag;

@property (nonatomic) BOOL simulating;

@property (nonatomic) NoteView* notePendingDelete;

@property (nonatomic) int currentCanvas;
@property (nonatomic) BOOL isTrashMode;

//almost-constant values that depend on the orientation and how the drawers are designed.
@property (nonatomic) int editY;
@property (nonatomic) int trashY;

@property (nonatomic) UIView* topLevelView;

@end

@implementation CanvasViewController

-(id)initWithTopLevelView:(UIView*)view {
    if (self = [super init]) {
        self.topLevelView = view;
    }
    return self;
}

-(id)initAsTrashCanvas {

    if (self = [super init]) {
        self.isTrashMode = YES;
    }
    
    return self;
}

-(void)setYValuesWithTrashOffset:(int)trashY {
    //trash offset is relative to superview
    self.editY = self.view.bounds.size.height;
    self.trashY = trashY - self.view.frame.origin.y - 100;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    self.collision = [[UICollisionBehavior alloc] init];
    self.collision.translatesReferenceBoundsIntoBoundary = YES;
    self.dynamicProperties = [[UIDynamicItemBehavior alloc] init];
    self.dynamicProperties.allowsRotation = NO;
    self.dynamicProperties.resistance = 8;

    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.dynamicProperties];

    if (self.isTrashMode) {
        //catch the trash
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteTrashedNotification:) name:kNoteTrashedNotification object:nil];
    } else {
        //allow new notes
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spaceTap:)];
        [self.view addGestureRecognizer:tapGestureRecognizer];
    }
    
    self.currentCanvas = 0;
    [self loadCurrentCanvas];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canvasChangedNotification:) name:kCanvasChangedNotification object:nil];
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
    } else {
        notes = [[Database sharedDatabase] notesInCanvas:self.currentCanvas];
        NSLog(@"%d saved notes", [notes count]);
    }
    
    for(Note* note in notes) {
        [self addViewForNote:note];
    }
}

-(void)canvasChangedNotification:(NSNotification*)notification {
    self.currentCanvas = [notification.userInfo[@"canvas"] intValue];
    [self loadCurrentCanvas];
}

-(void)noteTrashedNotification:(NSNotification*)notification {
    if (self.isTrashMode) {
        Note* trashedNote = [notification.userInfo objectForKey:Key_TrashedNotes];
        trashedNote.positionY = 0;
        [self addViewForNote:trashedNote];
        [[Database sharedDatabase] save];
    }
}

-(void)noteTap: (UITapGestureRecognizer *)recognizer {
    NoteView* view = (NoteView*)recognizer.view;
    [self.focus focusOn:view];
}

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

    //we need to use the top-level view so that clicking outside the popup dismisses it.
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
        //NSLog(@"window size %@", NSStringFromCGPoint(windowBottom));
        CGPoint windowRelativeBottom = [self.view convertPoint:windowBottom fromView:self.topLevelView];
        //NSLog(@"dist %f", windowRelativeBottom.y);

        self.notePendingDelete.offscreenYDistance = windowRelativeBottom.y;
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
    [self deletePendingNote];
}

-(void)spaceTap:(UITapGestureRecognizer *)recognizer {
    Note* note = [[Database sharedDatabase] createNote];
    
    CGPoint position = [recognizer locationInView:self.view];
    
    note.canvas = self.currentCanvas;
    note.positionX = position.x;
    note.positionY = position.y;

    [self addViewForNote:note];
    
    [[Database sharedDatabase] save];
}


-(void)noteDrag:(UIPanGestureRecognizer*)recognizer {
    
    NoteView* view = (NoteView*)recognizer.view;
    CGPoint drag = [recognizer locationInView:self.view];

    if(recognizer.state == UIGestureRecognizerStateBegan) {
        self.activeDrag = [[UIDynamicItemBehavior alloc] init];
        self.activeDrag.density = 1000000.0f;
        [self.animator addBehavior:self.activeDrag];
        [self.activeDrag addItem:view];
    }
    
    view.center = CGPointMake(drag.x, drag.y);
    [self.animator updateItemUsingCurrentState:view];

    //clean up the drag operation (and ONLY the drag operation. do all other ending actions below the isTrashMode check)
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        [view setBackgroundColor:[UIColor clearColor]];
        [self.activeDrag removeItem:view];
        [self.animator removeBehavior:self.activeDrag];
        self.activeDrag = nil;
    }

    if (self.isTrashMode) {
        //TODO maybe an un-trash action?
        if(recognizer.state == UIGestureRecognizerStateEnded) {
            [[Database sharedDatabase] save];
            CGPoint velocity = [recognizer velocityInView:self.view];
            [self.dynamicProperties addLinearVelocity:CGPointMake(velocity.x, velocity.y) forItem:view];
        }
    } else {
        //edit/trash actions and feedback
        //TODO: make the feedback pretty.

        if (view.center.y > self.trashY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [self deleteNoteWithoutAsking:view];
            } else {
                [view setBackgroundColor:[UIColor redColor]];
            }
        } else if (view.center.y > self.editY) {
            if(recognizer.state == UIGestureRecognizerStateEnded) {
                [self returnNoteToBounds:view];
                [self.focus focusOn:view];
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

-(void)returnNoteToBounds:(NoteView*)note {
    //force it back into the canvas if necessary.

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
        note.center = center;
        [self.animator updateItemUsingCurrentState:note];
        [[Database sharedDatabase] save];
    }
}

-(void)updateNotesForBoundsChange {
    NSLog(@"bounds %@", NSStringFromCGRect(self.view.bounds));
    for (UIView* subview in self.view.subviews) {
        if ([subview isKindOfClass:[NoteView class]]) {
            [self returnNoteToBounds:(NoteView*)subview];
        }
    }
}

-(void)addViewForNote:(Note*)note {
    NoteView* imageView = [[NoteView alloc] initWithImage:[UIImage imageNamed:@"Circle"]];
    imageView.center = CGPointMake(note.positionX, note.positionY);
    //NSLog(@"adding note at %@", NSStringFromCGPoint(imageView.center));
    
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
}
@end
