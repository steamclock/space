//
//  FocusViewController.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NoteView;

@interface FocusViewController : UIViewController

@property (nonatomic) CAShapeLayer* circleShape;

@property (nonatomic) UITextField* titleField;
@property (nonatomic) UITextView* contentField;

-(void)focusOn:(NoteView*)note withTouchPoint:(CGPoint)pointOfTouch;

@end
