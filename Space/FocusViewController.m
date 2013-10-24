//
//  FocusViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "FocusViewController.h"
#import "FocusView.h"
#import <QuartzCore/QuartzCore.h>
#import "Coordinate.h"
#import "Notifications.h"
#import "Constants.h"
#import "Database.h"

@interface FocusViewController ()

@property (nonatomic) UITextView* contentField;

@property (nonatomic) Note* note;
@property (nonatomic) NoteView* noteView;

// The subview that will only detect touches within the zoomed in note view. This allows different behaviours for
// tapping inside or outside the zoomed in note view.
@property (nonatomic) UIView* focus;

@end

@implementation FocusViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveNote) name:kSaveNoteNotification object:nil];
    
    self.view.frame = [Coordinate frameWithCenterXByFactor:0.5
                                           centerYByFactor:0.5
                                                     width:Key_FocusWidth
                                                    height:Key_FocusHeight
                                       withReferenceBounds:self.view.bounds];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.focus = [[FocusView alloc] initWithFrame:[Coordinate frameWithCenterXByFactor:0.5
                                                                    centerYByFactor:0.5
                                                                              width:Key_FocusWidth
                                                                             height:Key_FocusHeight
                                                                withReferenceBounds:self.view.bounds]];
    
    self.focus.backgroundColor = [UIColor whiteColor];
    self.focus.layer.borderWidth = Key_BorderWidth;
    self.focus.layer.cornerRadius = Key_NoteRadius;
    
    self.contentField = [[UITextView alloc] initWithFrame:[Coordinate frameWithCenterXByFactor:0.5
                                                                               centerYByFactor:0.5
                                                                                         width:Key_NoteContentFieldWidth
                                                                                        height:Key_NoteContentFieldHeight
                                                                           withReferenceBounds:self.focus.bounds]];
    
    self.contentField.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.focus];
    [self.focus addSubview:self.contentField];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOutside:)]];
    [self.focus addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapInside:)]];
    
    self.view.autoresizingMask =
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Readjust focus view location based on current device orientation.
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGPoint centerOfScreen = self.view.superview.center;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        self.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_LandscapeFocusViewAdjustment);
    } else {
        self.view.center = CGPointMake(centerOfScreen.x, centerOfScreen.y - Key_PortraitFocusViewAdjustment);
    }
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Save, hide keyboard, and unzoom if the tap is outside the circle.
-(void)tapOutside:(UITapGestureRecognizer*)gesture {
    [self saveNote];
    [[NSNotificationCenter defaultCenter] postNotificationName:kDismissNoteNotification object:self];
}

// Just save and hide keyboard if the tap is inside the circle.
-(void)tapInside:(UITapGestureRecognizer*)gesture {
    [self saveNote];
}

-(void)saveNote {
    [self.contentField resignFirstResponder];
    
    self.note.content = self.contentField.text;
    
    [[Database sharedDatabase] save];
    
    [self.noteView setUserInteractionEnabled:YES];
}

-(void)focusOn:(NoteView *)noteView {
    self.noteView = noteView;
    self.note = noteView.note;
    
    self.contentField.text = self.note.content;
    [self.contentField becomeFirstResponder];
}

@end
