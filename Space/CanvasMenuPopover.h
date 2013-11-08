//
//  CanvasTitleEditPopover.h
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//
//  Contains a TableViewController which allows switching, creating, and deleting canvases.
//  - Tap and hold on the canvas title cell to edit.
//  - Press edit or swipe left to delete.
//  - Press "+" to add a new canvas.
//

#import <UIKit/UIKit.h>
#import "CanvasNavBarController.h"

@interface CanvasMenuPopover : UIViewController

@property (weak, nonatomic) UIPopoverController* popoverController;

@end
