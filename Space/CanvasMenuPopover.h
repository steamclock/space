//
//  CanvasTitleEditPopover.h
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CanvasSelectionViewController.h"

@interface CanvasMenuPopover : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSMutableArray* canvasTitles;
@property (strong, nonatomic) NSMutableArray* canvasTitleIndices;

@property (strong, nonatomic) UITextField* titleField;
@property (weak, nonatomic) UIPopoverController* popoverController;

// @property (copy, nonatomic) void(^newTitleEntered)(NSString* title);

@end
