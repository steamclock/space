//
//  DrawerViewController.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-20.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//
//  This is the big view that stretches beyond the top and bottom of the device's screen, and contains the note and
//  trash canvases. When "dragging the canvases", we are actually dragging and moving the entire drawer up or down
//  the screen.
//

#import <UIKit/UIKit.h>
#import "CanvasViewController.h"

@interface DrawerViewController : UIViewController <UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate>

@property (nonatomic) CanvasViewController* topDrawerContents;
@property (nonatomic) CanvasViewController* bottomDrawerContents;

@end