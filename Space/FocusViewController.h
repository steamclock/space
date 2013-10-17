//
//  FocusViewController.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RichTextEditor.h"

@class NoteView;

@interface FocusViewController : UIViewController <RichTextEditorDataSource>

@property (nonatomic) CAShapeLayer* circleShape;

@property (nonatomic) UITextField* titleField;
@property (nonatomic) RichTextEditor* contentField;

-(void)focusOn:(NoteView*)note withTouchPoint:(CGPoint)pointOfTouch;

@end
