//
//  Constants.h
//  Space
//
//  Created by Jeremy Chiang on 2013-09-05.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const Key_CanvasTitles;
extern NSString* const Key_CanvasTitleIndices;

extern NSString* const Key_CanvasNumber;
extern NSString* const Key_CanvasName;

extern NSString* const Key_CurrentCanvasIndex;

extern NSString* const Key_TrashedNotes;
extern NSString* const Key_RecoveredNote;

typedef enum DragModeEnum {
    UIViewAnimation,
    UIDynamicFreeSliding,
    UIDynamicFreeSlidingWithGravity
} DragMode;
