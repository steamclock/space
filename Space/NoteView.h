//
//  NoteView.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//
//  This view represents the note circles in the canvases.
//

#import <UIKit/UIKit.h>
#import "Note.h"

@interface NoteView : UIImageView

// Reference to the note model that this view is representing.
@property Note* note;

// Reference to the canvas' animator, which can then be used to properly update the frame when
// setCenter:withReferenceBounds: is called.
@property (nonatomic, weak) UIDynamicAnimator* animator;

// The label above the note circle.
@property UILabel* titleLabel;

// The drawing of the note view.
@property (nonatomic) CAShapeLayer* circleShape;

// Stores the frame and position of this view before a zoom or before an orientation change, so we can come back to it,
// or redraw correctly in a new orientation.
@property (nonatomic) CGRect originalCircleFrame;
@property (nonatomic) float originalPositionX;
@property (nonatomic) float originalPositionY;

// Block for when the note drops offscreen (into the trash).
@property (nonatomic, copy) void (^onDropOffscreen)();
@property (nonatomic) int offscreenYDistance;

// Used to assist with the programmatic relocation of the note view.
-(void)setCenter:(CGPoint)center withReferenceBounds:(CGRect)bounds;

@end
