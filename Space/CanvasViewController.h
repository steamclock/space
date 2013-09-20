//
//  CanvasViewController.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FocusViewController;

@interface CanvasViewController : UIViewController

@property (nonatomic) FocusViewController* focus;

-(id)initWithTopLevelView:(UIView*)view;
-(id)initAsTrashCanvas;

//set up various almost-constants
-(void)setYValuesWithTrashOffset:(int)trashY;

-(void)updateNotesForBoundsChange;

@end
