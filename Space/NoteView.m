//
//  NoteView.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "NoteView.h"
#import "Note.h"
#import "Coordinate.h"
#import "Database.h"
#import "Constants.h"

const int NOTE_RADIUS = 30;

@interface NoteView () {
    Note* _note;
}

@end

@implementation NoteView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonSetup];
    }
    return self;
}

/*
-(id)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) {
        [self commonSetup];
    }
    return self;
}
*/

-(void)dealloc {
    [_note removeObserver:self forKeyPath:@"title"];
    [_note removeObserver:self forKeyPath:@"content"];
}

-(void)commonSetup {
    int diameter = NOTE_RADIUS * 2;
    
    self.contentMode = UIViewContentModeScaleToFill;
    self.frame = CGRectMake(0, 0, diameter, diameter);

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, Key_NoteTitleLabelWidth, Key_NoteTitleLabelHeight)];
    self.titleLabel.center = CGPointMake(self.center.x, -Key_NoteTitleLabelHeight);
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    
    [self addSubview:self.titleLabel];
    self.clipsToBounds = NO;
    
    [self drawCircle];
}

-(void)drawCircle {
    UIView* circle = [[UIView alloc] initWithFrame:self.frame];
    circle.backgroundColor = [UIColor clearColor];
    [self addSubview:circle];
    
    self.circleShape = [CAShapeLayer layer];
    
    CGRect circleFrame = self.bounds;
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithRoundedRect:circleFrame cornerRadius:NOTE_RADIUS];
    
    self.circleShape.path = circlePath.CGPath;
    
    self.circleShape.fillColor = [UIColor clearColor].CGColor;
    self.circleShape.strokeColor = [UIColor blackColor].CGColor;
    self.circleShape.lineWidth = 2.0f;
    
    self.circleShape.frame = self.bounds;
    
    [self.layer addSublayer:self.circleShape];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"title"]) {
        self.titleLabel.text = self.note.title;
    } else if ([keyPath isEqualToString:@"content"]) {
        if ([self.titleLabel.text isEqualToString:@""]) {
            // NSLog(@"Title is empty");
            self.titleLabel.text = self.note.content;
        }
    }
}

-(void)setNote:(Note *)note {
    [_note removeObserver:self forKeyPath:@"title"];
    [_note removeObserver:self forKeyPath:@"content"];
    
    _note = note;
    
    self.titleLabel.text = note.title;
    if ([self.titleLabel.text isEqualToString:@""]) {
        // NSLog(@"Title is empty");
        self.titleLabel.text = note.content;
    }
    
    [_note addObserver:self forKeyPath:@"title" options:0 context:NULL];
    [_note addObserver:self forKeyPath:@"content" options:0 context:NULL];
}

-(Note*)note {
    return _note;
}

-(void)setCenter:(CGPoint)center {
    [super setCenter:center];
    
    if (self.onDropOffscreen && center.y > self.offscreenYDistance) {
        NSLog(@"Trashed note has dropped offscreen");
        self.onDropOffscreen();
    }
}

-(void)setCenter:(CGPoint)center withReferenceBounds:(CGRect)bounds {
    [super setCenter:center];
    
    self.note.positionX = [Coordinate normalizeXCoord:center.x withReferenceBounds:bounds];
    self.note.positionY = [Coordinate normalizeYCoord:center.y withReferenceBounds:bounds];
    
    [self.animator updateItemUsingCurrentState:self];
    [[Database sharedDatabase] save];
}

-(void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        // [self setBackgroundColor:[UIColor blueColor]];
    } else {
        // [self setBackgroundColor:[UIColor clearColor]];
    }
}

@end
