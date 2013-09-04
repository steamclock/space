//
//  CanvasTitleEditPopover.m
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasTitleEditPopover.h"

@interface CanvasTitleEditPopover ()

@end

@implementation CanvasTitleEditPopover

@synthesize popoverController;

- (BOOL)isInPopover {
    
    Class popoverClass = NSClassFromString(@"UIPopoverController");
    
    if (popoverClass != nil && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && self.popoverController != nil) {
        return YES;
    } else {
        return NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.preferredContentSize = CGSizeMake(300.0f, 65.0f);
    
    CGRect rect = CGRectMake(20.0f, 20.0f, 160.0f, 25.0f);
    self.titleField = [[UITextField alloc] initWithFrame:rect];
    self.titleField.placeholder = @"Enter new title";
    [self.titleField setDelegate:self];
    [self.titleField setReturnKeyType:UIReturnKeyDone];
    [self.view addSubview:self.titleField];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.titleField setText:@""];
    [self.titleField becomeFirstResponder];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (self.newTitleEntered) {
        self.newTitleEntered(textField.text);
    }
    
    [textField resignFirstResponder];
    [self.popoverController dismissPopoverAnimated:YES];
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
