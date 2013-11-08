//
//  AboutViewController.m
//  Space
//
//  Created by Jeremy Chiang on 2013-11-01.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@property (weak, nonatomic) IBOutlet UITextView* aboutText;

@end

@implementation AboutViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // Need to enable editable first to allow data detector types, a workaround for an Apple bug.
    self.aboutText.editable = YES;
    self.aboutText.editable = NO;
    self.aboutText.dataDetectorTypes = UIDataDetectorTypeLink;
    
    UIFont* headline = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    UIFont* subHeadline = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    UIFont* body = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    NSAttributedString* header = [[NSAttributedString alloc] initWithString:@"Space\n" attributes:@{NSFontAttributeName : headline}];
    NSAttributedString* subHeader = [[NSAttributedString alloc] initWithString:@"By Steamclock Software\n\n" attributes:@{NSFontAttributeName : subHeadline}];
    NSAttributedString* content = [[NSAttributedString alloc] initWithString:@"Space is an experimental note board with the ability to jot down thoughts and plans, arrange them, and discard them once they are complete.\n\nIf you have feedback about Space, please contact us at contact@steamclock.com." attributes:@{NSFontAttributeName : body}];
    
    NSMutableAttributedString* aboutString = [[NSMutableAttributedString alloc] init];
    [aboutString appendAttributedString:header];
    [aboutString appendAttributedString:subHeader];
    [aboutString appendAttributedString:content];
    
    self.aboutText.attributedText = aboutString;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:recognizer];
    
    [self.aboutText flashScrollIndicators];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismiss:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [recognizer locationInView:nil];
        
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]) {
            [self.view.window removeGestureRecognizer:recognizer];
            [self dismissViewControllerAnimated:NO completion:nil];;
        }
    }
   
}

@end
