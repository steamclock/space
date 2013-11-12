//
//  Constants.h
//  Space
//
//  Created by Jeremy Chiang on 2013-09-05.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

extern int const Key_NavBarHeight;

// Keys for objects in either Core Data or NSUserDefaults.
extern NSString* const Key_AppInstalled;

extern NSString* const Key_CanvasTitles;
extern NSString* const Key_CanvasTitlesIds;

extern NSString* const Key_CanvasNumber;
extern NSString* const Key_CanvasName;

extern NSString* const Key_CurrentCanvasIndex;

extern NSString* const Key_TrashedNotes;
extern NSString* const Key_RecoveredNote;

// Boundaries for gravity.
extern NSString* const Key_TopBoundary;
extern NSString* const Key_BotBoundary;

// Controls how far up or down the y axis the focus view is in different orientations.
extern int const Key_LandscapeFocusViewAdjustment;
extern int const Key_PortraitFocusViewAdjustment;

// Border width for the note circles, both zoomed in and zoomed out.
extern int const Key_BorderWidth;
// The radius for the note circles.
extern int const Key_NoteRadius;
// The size for the focus view.
extern int const Key_FocusWidth;
extern int const Key_FocusHeight;

// The label above the note circles.
extern int const Key_NoteTitleLabelWidth;
extern int const Key_NoteTitleLabelHeight;

// The max number of characters for the note title label.
extern int const Key_NoteTitleLabelLength;

// The textview in focus view.
extern int const Key_NoteContentFieldWidth;
extern int const Key_NoteContentFieldHeight;

// Image names.
extern NSString* const Img_HandlebarDown;
extern NSString* const Img_TrashBin;
