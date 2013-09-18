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

#define FOCUS_SIZE 400

@interface FocusViewController ()

@property (nonatomic) Note* note;
@property (nonatomic) UIView* focus;
@property (nonatomic) UITextField* titleField;
@property (nonatomic) UITextView* contentField;

@end

@implementation FocusViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, 768, 1024);
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.3];
    
    self.focus = [[UIView alloc] initWithFrame:CGRectMake(234 - FOCUS_SIZE/8, 325, FOCUS_SIZE, FOCUS_SIZE)];
    self.focus.backgroundColor = [UIColor lightGrayColor];
    self.focus.layer.cornerRadius = FOCUS_SIZE / 2;
    
    self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(20 + FOCUS_SIZE/8, 70, 260, 40)];
    self.titleField.placeholder = @"Title";
    [self.titleField setTextAlignment:NSTextAlignmentCenter];
    
    self.contentField = [[UITextView alloc] initWithFrame:CGRectMake(20 + FOCUS_SIZE/8, 130, 260, 200)];
    self.contentField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    self.contentField.layer.cornerRadius = 15;
    
    [self.view addSubview:self.focus];
    [self.focus addSubview:self.titleField];
    [self.focus addSubview:self.contentField];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOutside:)]];
}

-(void)tapOutside:(UITapGestureRecognizer*)guesture {
    [self.titleField resignFirstResponder];
    [self.contentField resignFirstResponder];
    
    self.note.title = self.titleField.text;
    self.note.content = self.contentField.text;
    
    [[Database sharedDatabase] save];
    
    self.view.hidden = true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)focusOn:(Note *)note {
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
@end
