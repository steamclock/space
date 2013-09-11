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
    
    self.focus = [[UIView alloc] initWithFrame:CGRectMake(234, 362, 300, 300)];
    self.focus.backgroundColor = [UIColor grayColor];
    
    self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, 260, 40)];
    self.titleField.backgroundColor = [UIColor whiteColor];
    self.contentField = [[UITextView alloc] initWithFrame:CGRectMake(20, 80, 260, 200)];
    
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
