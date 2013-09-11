//
//  NoteView.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Note;

@interface NoteView : UIImageView

@property Note* note;

//block for when the note drops offscreen (into the trash)
@property (nonatomic, copy) void (^onDropOffscreen)();

@end
