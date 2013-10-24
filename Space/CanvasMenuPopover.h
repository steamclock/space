//
//  CanvasTitleEditPopover.h
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//
//  Allows switching, creating, and deleting canvases. Tap and hold on the canvas title to edit. Enter an empty string
//  to delete.
//

#import <UIKit/UIKit.h>
#import "CanvasSelectionViewController.h"

@interface CanvasMenuPopover : UIViewController <UITextFieldDelegate>

// Stores a list of canvas titles in which each title corresponds to an index number in the title indices.
// A potential mapping after some editing could look like this:

/*
      Array Index | Canvas Title Index | Canvas Title
 
      0             1                    Computer Science
      1             3                    Biology
      2             5                    Accounting
*/

// This way, a canvas title can always be represented by a 'primary-key' canvas index that is unique, while the
// array index which the canvas title corresponds to can change. This allows the reordering of the canvas titles
// inside the popover menu.
@property (strong, nonatomic) NSMutableArray* canvasTitles;
@property (strong, nonatomic) NSMutableArray* canvasTitleIndices;

@property (strong, nonatomic) UITextField* titleField;
@property (weak, nonatomic) UIPopoverController* popoverController;

@end
