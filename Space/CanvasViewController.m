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
//this gravity is disabled because the drop-to-trash gravity was conflicting with it.
//never put more than one UIGravityBehavior on the same animator. it gets confused.
//@property (nonatomic) UIGravityBehavior* gravity;
@property (nonatomic) UICollisionBehavior* collision;
@property (nonatomic) UIDynamicItemBehavior* dynamicProperties;

@property (nonatomic) UIDynamicItemBehavior* activeDrag;

@property (nonatomic) BOOL simulating;

@property (nonatomic) NoteView* viewForMenu;

@property (nonatomic) int currentCanvas;
@property (nonatomic) BOOL isTrashMode;

@end

@implementation CanvasViewController

-(id)initAsTrashCanvas {

    if (self = [super init]) {
        self.isTrashMode = YES;
    }
    
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    /*self.gravity = [[UIGravityBehavior alloc] init];
    self.gravity.gravityDirection = CGVectorMake(0, 0);*/
    self.collision = [[UICollisionBehavior alloc] init];
    self.collision.translatesReferenceBoundsIntoBoundary = YES;
    self.dynamicProperties = [[UIDynamicItemBehavior alloc] init];
    self.dynamicProperties.allowsRotation = NO;
    
    //[self.animator addBehavior:self.gravity];
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.dynamicProperties];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spaceTap:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spaceDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGestureRecognizer];
    
    self.currentCanvas = 0;
    [self loadCurrentCanvas];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canvasChangedNotification:) name:kCanvasChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteTrashedNotification:) name:kNoteTrashedNotification object:nil];
}

-(void)loadCurrentCanvas {
    
    for(UIView* view in self.view.subviews) {
        //[self.gravity removeItem:view];
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
    }
}

-(void)noteTap: (UITapGestureRecognizer *)recognizer {
    NoteView* view = (NoteView*)recognizer.view;
    [self.focus focusOn:view.note];
}

-(void)noteLongPress: (UITapGestureRecognizer *)recognizer {
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        NoteView* view = (NoteView*)recognizer.view;
        self.viewForMenu = view;
        
        QBPopupMenu* menu = [[QBPopupMenu alloc] init];
        menu.items = @[ [[QBPopupMenuItem alloc] initWithTitle:@"Delete" target:self action:@selector(noteMenuDelete:)] ];

        //we need to use the top-level view so that clicking outside the popup dismisses it.
        //FIXME referring to the super-super-view is fragile and bad. maybe we could have the top level view passed in instead?
        UIView* topView = self.view.superview.superview;

        CGPoint showAt = [view.superview convertPoint:view.center toView:topView];
        [menu showInView:topView atPoint:showAt];
    }
}

-(void)noteMenuDelete:(id)sender {
    Note* note = self.viewForMenu.note;
    
    // [note removeFromDatabase];
    [note markAsTrashed];
    [[Database sharedDatabase] save];
    
    //[self.gravity removeItem:self.viewForMenu];
    [self.collision removeItem:self.viewForMenu];
    [self.dynamicProperties removeItem:self.viewForMenu];

    UIGravityBehavior *trashDrop = [[UIGravityBehavior alloc] initWithItems:@[self.viewForMenu]];
    trashDrop.gravityDirection = CGVectorMake(0, 1);
    [self.animator addBehavior:trashDrop];

    __weak CanvasViewController* weakSelf = self;

    self.viewForMenu.onDropOffscreen = ^{
        [weakSelf.animator removeBehavior:trashDrop];
        [weakSelf.viewForMenu removeFromSuperview];
        weakSelf.viewForMenu = nil;

        NSDictionary* deletedNoteInfo = [[NSDictionary alloc] initWithObjects:@[note] forKeys:@[Key_TrashedNotes]];

        NSNotification* noteTrashedNotification = [[NSNotification alloc] initWithName:kNoteTrashedNotification object:weakSelf userInfo:deletedNoteInfo];
        [[NSNotificationCenter defaultCenter] postNotification:noteTrashedNotification];
    };
}

-(void)spaceDoubleTap:(UITapGestureRecognizer *)recognizer {
    //self.gravity.gravityDirection = CGVectorMake(0, 1);
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
        //[self.gravity removeItem:view];
    }
    
    view.center = CGPointMake(drag.x, drag.y);
    
    [self.animator updateItemUsingCurrentState:view];
    
    Note* note = view.note;
    note.positionX = drag.x;
    note.positionY = drag.y;

    if(recognizer.state == UIGestureRecognizerStateEnded) {
        //[self.gravity addItem:view];
        [self.activeDrag removeItem:view];
        self.activeDrag = nil;
        [[Database sharedDatabase] save];
    }
}

-(void)addViewForNote:(Note*)note {
    NoteView* imageView = [[NoteView alloc] initWithImage:[UIImage imageNamed:@"Circle"]];
    imageView.center = CGPointMake(note.positionX, note.positionY);
    
    imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(noteTap:)];
    [imageView addGestureRecognizer:tapGestureRecognizer];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(noteDrag:)];
    [imageView addGestureRecognizer:panGestureRecognizer];
    
    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(noteLongPress:)];
    [imageView addGestureRecognizer:longPress];

    [self.view addSubview:imageView];
    //[self.gravity addItem:imageView];
    [self.collision addItem:imageView];
    [self.dynamicProperties addItem:imageView];

    imageView.note = note;
}
@end
