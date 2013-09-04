//
//  CanvasTitleEditPopover.h
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CanvasSelectionViewController.h"

@interface CanvasTitleEditPopover : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) UITextField* titleField;

@property (weak, nonatomic) UIPopoverController* popoverController;

@property (copy, nonatomic) void(^newTitleEntered)(NSString* title);

@end
