//
//  FocusViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "FocusViewController.h"
#import "Database.h"
#import "Note.h"
#import <QuartzCore/QuartzCore.h>
#import "Coordinate.h"

#define FOCUS_SIZE 400

@interface FocusViewController ()

@property (nonatomic) Note* note;
@property (nonatomic) UIView* focus;
@property (nonatomic) UITextField* titleField;
@property (nonatomic) UITextView* contentField;

@end

@implementation FocusViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = self.view.bounds;
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.3];
    
    self.focus = [[UIView alloc] initWithFrame:[Coordinate frameWithCenterXByFactor:0.5
                                                                    centerYByFactor:0.5
                                                                              width:FOCUS_SIZE
                                                                             height:FOCUS_SIZE
                                                                withReferenceBounds:self.view.bounds]];
    
    self.focus.backgroundColor = [UIColor lightGrayColor];
    self.focus.layer.cornerRadius = FOCUS_SIZE / 2;
    
    self.titleField = [[UITextField alloc] initWithFrame:[Coordinate frameWithCenterXByFactor:0.5
                                                                              centerYByFactor:0.15
                                                                                        width:250
                                                                                       height:50
                                                                          withReferenceBounds:self.focus.bounds]];
    
    self.titleField.placeholder = @"Title";
    [self.titleField setTextAlignment:NSTextAlignmentCenter];
    
    self.contentField = [[UITextView alloc] initWithFrame:[Coordinate frameWithCenterXByFactor:0.5
                                                                               centerYByFactor:0.55
                                                                                         width:280
                                                                                        height:200
                                                                           withReferenceBounds:self.focus.bounds]];
    
    self.contentField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    self.contentField.layer.cornerRadius = 15;
    
    [self.view addSubview:self.focus];
    [self.focus addSubview:self.titleField];
    [self.focus addSubview:self.contentField];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOutside:)]];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
     
        self.focus.frame = [Coordinate frameWithCenterXByFactor:0.5
                                             centerYByFactor:0.25
                                                       width:FOCUS_SIZE
                                                      height:FOCUS_SIZE
                                         withReferenceBounds:self.view.bounds];
    } else {
        [self updateFocusViewFrame];
    }
}

-(void)tapOutside:(UITapGestureRecognizer*)guesture {
    
    [self.titleField resignFirstResponder];
    [self.contentField resignFirstResponder];
    
    self.note.title = self.titleField.text;
    self.note.content = self.contentField.text;
    
    [[Database sharedDatabase] save];
    
    self.view.hidden = true;
}

-(void)focusOn:(Note *)note {
    
    [self updateFocusViewFrame];
    
    self.note = note;
    
    self.titleField.text = self.note.title;
    self.contentField.text = self.note.content;

    if ([note.title length]) {
        //title exists; edit the content
        [self.contentField becomeFirstResponder];
    } else {
        //edit the title
        [self.titleField becomeFirstResponder];
    }

    self.view.hidden = NO;
}

- (void)updateFocusViewFrame {
    
    self.focus.frame = [Coordinate frameWithCenterXByFactor:0.5
                                            centerYByFactor:0.5
                                                      width:FOCUS_SIZE
                                                     height:FOCUS_SIZE
                                        withReferenceBounds:self.view.bounds];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
