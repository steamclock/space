//
//  NoteView.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "NoteView.h"
#import "Coordinate.h"
#import "Constants.h"
#import "Database.h"

@interface NoteView () {
    Note* _note;
}

@end

@implementation NoteView

-(id)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) {
        [self commonSetup];
    }
    return self;
}

-(void)dealloc {
    [_note removeObserver:self forKeyPath:@"content"];
}

-(void)commonSetup {
    int diameter = Key_NoteRadius * 2;
    
    self.contentMode = UIViewContentModeScaleToFill;
    self.frame = CGRectMake(0, 0, diameter, diameter);

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, Key_NoteTitleLabelWidth, Key_NoteTitleLabelHeight)];
    // self.titleLabel.backgroundColor = [UIColor yellowColor];
    // Force the title label to float above the note circle.
    self.titleLabel.center = CGPointMake(self.center.x, -Key_NoteTitleLabelHeight);
    self.clipsToBounds = NO;
    
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    
    [self addSubview:self.titleLabel];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if ([keyPath isEqualToString:@"content"]) {
       
       // Don't allow more than a certain number of characters when storing and displaying the note title.
       NSUInteger charCount = [self.note.content length];
       if (charCount > Key_NoteTitleLabelLength) {
           charCount = Key_NoteTitleLabelLength;
       }
       
       // Use the first few characters of the content as the title.
       self.note.title = [self.note.content substringToIndex:charCount];
              
       if ([self.note.content length] > Key_NoteTitleLabelLength) {
           self.titleLabel.text = [NSString stringWithFormat:@"%@...", [self.note.title substringToIndex:Key_NoteTitleLabelLength]];
       } else {
           self.titleLabel.text = self.note.title;
       }
    }
}

-(void)setNote:(Note *)note {
    [_note removeObserver:self forKeyPath:@"content"];
    
    _note = note;
    self.titleLabel.text = note.content;
    
    if ([note.content length] > Key_NoteTitleLabelLength) {
        self.titleLabel.text = [NSString stringWithFormat:@"%@...", [note.content substringToIndex:Key_NoteTitleLabelLength]];
    }
    
    [_note addObserver:self forKeyPath:@"content" options:0 context:NULL];
}

-(Note*)note {
    return _note;
}

// We're overriding the default setCenter method, which is constantly being called by the animator when it is animating,
// in order to add some additional functionality, such as performing an action when the animator has dropped a
// recently sent-to-trash note view below the bottom of the screen.
-(void)setCenter:(CGPoint)center {
    [super setCenter:center];
    
    if (self.onDropOffscreen && center.y > self.offscreenYDistance) {
        NSLog(@"Trashed note has dropped offscreen");
        self.onDropOffscreen();
    }
}

// This is called when dragging a note view, or when orientation changes. In both cases, we need to programmatically
// set new positions, and then update the animator with the new changes. We are not using the default setCenter here
// because occasionally we need to call setCenter and manually reposition views while the animator is still active.
// However, if we do that our setCenter calls can conflict with the animator as it could also be attempting to
// reposition the same view. Therefore, we leave the default setCenter method alone, and do our custom moving here.
// When we're done, we give the animator the results of our changes.
-(void)setCenter:(CGPoint)center withReferenceBounds:(CGRect)bounds {
    [super setCenter:center];
    
    self.note.positionX = [Coordinate normalizeXCoord:center.x withReferenceBounds:bounds];
    self.note.positionY = [Coordinate normalizeYCoord:center.y withReferenceBounds:bounds];
    
    [self.animator updateItemUsingCurrentState:self];
    [[Database sharedDatabase] save];
}

@end
