//
//  NoteView.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-21.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "NoteView.h"
#import "Note.h"

@interface NoteView () {
    Note* _note;
}

@property UILabel* titleLabel;

@end

@implementation NoteView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) {
        [self commonSetup];
    }
    return self;
}

-(void)dealloc {
    [_note removeObserver:self forKeyPath:@"title"];
}

-(void)commonSetup {
    self.contentMode = UIViewContentModeScaleToFill;
    self.frame = CGRectMake(0, 0, 24, 24);

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.center.x - 32, self.frame.size.height, 64, 20)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    
    [self addSubview:self.titleLabel];
    self.clipsToBounds = NO;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"title"]) {
        self.titleLabel.text = self.note.title;
    }
}

-(void)setNote:(Note *)note {
    [_note removeObserver:self forKeyPath:@"title"];
    _note = note;
    self.titleLabel.text = note.title;
    [_note addObserver:self forKeyPath:@"title" options:0 context:NULL];
}

-(Note*)note {
    return _note;
}

-(void)setCenter:(CGPoint)center {
    [super setCenter:center];
    
    self.note.positionX = center.x;
    self.note.positionY = center.y;
}


@end
