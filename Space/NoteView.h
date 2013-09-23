//
//  NoteView.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const int NOTE_RADIUS;

@class Note;

@interface NoteView : UIImageView

@property Note* note;

// Block for when the note drops offscreen (into the trash)
@property (nonatomic, copy) void (^onDropOffscreen)();
@property (nonatomic) int offscreenYDistance;

// Used to help update item coordinates in setCenter:withReferenceBounds:
@property (nonatomic, weak) UIDynamicAnimator* animator;

-(void)setCenter:(CGPoint)center withReferenceBounds:(CGRect)bounds;
-(void)setHighlighted:(BOOL)highlighted;

@end
