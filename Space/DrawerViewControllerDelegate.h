//
//  DrawerViewControllerDelegate.h
//  Space
//
//  Created by Jeremy Chiang on 2013-10-10.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DrawerViewControllerDelegate <NSObject>

// The drawer 
-(void)updateCurrentlyZoomedInNoteViewCenter;

@end
