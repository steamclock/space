//
//  FocusViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "FocusViewController.h"
#import "Database.h"
#import "NoteView.h"
#import <QuartzCore/QuartzCore.h>
#import "Coordinate.h"
#import "Notifications.h"
#import "Constants.h"
#import "HelperMethods.h"

#define FOCUS_SIZE 480

@interface FocusViewController ()

@property (nonatomic) Note* note;
@property (nonatomic) NoteView* noteView;
@property (nonatomic) UIView* focus;
@property (nonatomic) CGPoint touchPoint;

@property (nonatomic) BOOL isShowingTitleField;

@end

@implementation FocusViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveNote) name:kSaveNoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleTitle:) name:kChangeEditorModeNotification object:nil];
    self.isShowingTitleField = YES;
    
    // self.view.frame = self.view.bounds;
    self.view.frame = [Coordinate frameWithCenterXByFactor:0.5
                                           centerYByFactor:0.5
                                                     width:FOCUS_SIZE
                                                    height:FOCUS_SIZE
                                       withReferenceBounds:self.view.bounds];
    
    // self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.3];
    self.view.backgroundColor = [UIColor clearColor];
    
    [self drawCircle];
    
    self.focus = [[UIView alloc] initWithFrame:[Coordinate frameWithCenterXByFactor:0.5
                                                                    centerYByFactor:0.5
                                                                              width:FOCUS_SIZE
                                                                             height:FOCUS_SIZE
                                                                withReferenceBounds:self.view.bounds]];
    
    // self.focus.backgroundColor = [UIColor lightGrayColor];
    self.focus.backgroundColor = [UIColor clearColor];
    self.focus.layer.cornerRadius = FOCUS_SIZE / 2;
    
    self.titleField = [[UITextField alloc] initWithFrame:[Coordinate frameWithCenterXByFactor:0.5
                                                                              centerYByFactor:0.15
                                                                                        width:Key_NoteTitleFieldWidth
                                                                                       height:Key_NoteTitleFieldHeight
                                                                          withReferenceBounds:self.focus.bounds]];
    
    self.titleField.placeholder = @"Title";
    [self.titleField setTextAlignment:NSTextAlignmentCenter];
    
    self.contentField = [[UITextView alloc] initWithFrame:[Coordinate frameWithCenterXByFactor:0.5
                                                                               centerYByFactor:0.55
                                                                                         width:Key_NoteContentFieldWidth
                                                                                        height:Key_NoteContentFieldHeight
                                                                           withReferenceBounds:self.focus.bounds]];
    
    self.contentField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    self.contentField.layer.cornerRadius = 15;
    
    [self.view addSubview:self.focus];
    [self.focus addSubview:self.titleField];
    [self.focus addSubview:self.contentField];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOutside:)]];
    
    self.view.autoresizingMask =
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGPoint centerOfScreen = self.view.superview.center;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        self.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_LandscapeFocusViewAdjustment);
    } else {
        self.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_PortraitFocusViewAdjustment);
    }
}

-(void)toggleTitle:(NSNotification*)notification {
    if ([[notification.userInfo objectForKey:Key_EditorMode] isEqual:[NSNumber numberWithInt:ShowTitle]]) {
        self.isShowingTitleField = YES;
        
        [self.titleField setHidden:NO];
        
        self.contentField.frame = [Coordinate frameWithCenterXByFactor:0.5
                                                       centerYByFactor:0.55
                                                                 width:Key_NoteContentFieldWidth
                                                                height:Key_NoteContentFieldHeight
                                                   withReferenceBounds:self.focus.bounds];
        
        if (self.view.alpha == 1) {
            [self.titleField becomeFirstResponder];
        }
        
    } else {
        self.isShowingTitleField = NO;
        
        [self.titleField setHidden:YES];
        
        self.contentField.frame = [Coordinate frameWithCenterXByFactor:0.5
                                                       centerYByFactor:0.5
                                                                 width:Key_NoteLargeContentFieldWidth
                                                                height:Key_NoteLargeContentFieldHeight
                                                   withReferenceBounds:self.focus.bounds];
        
        if (self.view.alpha == 1) {
            [self.contentField becomeFirstResponder];
        }
    }
}

-(void)drawCircle {
    UIView* circle = [[UIView alloc] initWithFrame:self.view.frame];
    circle.backgroundColor = [UIColor clearColor];
    [self.view addSubview:circle];
    
    self.circleShape = [CAShapeLayer layer];
    
    CGRect circleFrame = self.view.bounds;
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithRoundedRect:circleFrame cornerRadius:FOCUS_SIZE];
    
    self.circleShape.path = circlePath.CGPath;
    
    self.circleShape.fillColor = [HelperMethods circleFillColor];
    self.circleShape.strokeColor = [UIColor blackColor].CGColor;
    self.circleShape.lineWidth = 0.0f;
    
    self.circleShape.frame = self.view.bounds;
    
    [self.view.layer addSublayer:self.circleShape];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    NSLog(@"Focus view center = %@", NSStringFromCGPoint(self.view.center));
    NSLog(@"Focus view superview center = %@", NSStringFromCGPoint(self.view.superview.center));
}

-(void)saveNote {
    [self.titleField resignFirstResponder];
    [self.contentField resignFirstResponder];
    
    self.note.title = self.titleField.text;
    self.note.content = self.contentField.text;
    
    [[Database sharedDatabase] save];
    
    [self.noteView setHighlighted:NO];
    [self.noteView setUserInteractionEnabled:YES];
}

-(void)tapOutside:(UITapGestureRecognizer*)guesture {
    
    [self saveNote];
    
    // NSLog(@"Self noteView frame = %@", NSStringFromCGRect(self.noteView.frame));
    // self.view.hidden = YES;
}

-(void)focusOn:(NoteView *)view withTouchPoint:(CGPoint)pointOfTouch {
    self.noteView = view;
    // [self.noteView setHighlighted:YES];
    // NSLog(@"Note view frame = %@", NSStringFromCGRect(view.frame));
    
    self.note = view.note;
    
    self.titleField.text = self.note.title;
    self.contentField.text = self.note.content;

    if ([view.note.title length] || self.isShowingTitleField == NO) {
        //title exists; edit the content
        [self.contentField becomeFirstResponder];
    } else {
        //edit the title
        [self.titleField becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
