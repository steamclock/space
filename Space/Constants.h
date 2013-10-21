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

extern NSString* const Key_TwoSectionsTopBoundary;
extern NSString* const Key_TwoSectionsBotBoundary;

extern NSString* const Key_ThreeSectionsCanvasTopBoundary;
extern NSString* const Key_ThreeSectionsCanvasBotBoundary;
extern NSString* const Key_ThreeSectionsTrashTopBoundary;
extern NSString* const Key_ThreeSectionsTrashBotBoundary;

extern int const Key_NavBarHeight;
extern int const Key_LandscapeFocusViewAdjustment;
extern int const Key_PortraitFocusViewAdjustment;

extern int const Key_NoteTitleLabelWidth;
extern int const Key_NoteTitleLabelHeight;

extern int const Key_NoteTitleFieldWidth;
extern int const Key_NoteTitleFieldHeight;

extern int const Key_NoteContentFieldWidth;
extern int const Key_NoteContentFieldHeight;

extern int const Key_NoteLargeContentFieldWidth;
extern int const Key_NoteLargeContentFieldHeight;

/* Prototyping Modes */

extern NSString* const Key_FocusMode;

typedef enum FocusModeEnum {
    Dimming,
    SlideOut,
    SlidePartially
} FocusMode;

extern NSString* const Key_DragMode;

typedef enum DragModeEnum {
    UIViewAnimation,
    UIDynamicFreeSliding,
    UIDynamicFreeSlidingWithGravity
} DragMode;

extern NSString* const Key_NoteCircleMode;

typedef enum NoteCircleModeEnum {
    ShowOriginalLocation,
    HideOriginalLocation
} NoteCircleMode;

extern NSString* const Key_EditorMode;

typedef enum EditorModeEnum {
    ShowTitle,
    NoTitle
} EditorMode;

/* Image Names */

extern NSString* const Img_HandlebarDown;
extern NSString* const Img_HandlebarUp;
