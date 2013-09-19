//
//  DrawerViewController.h
//  Space
//
//  Created by Nigel Brooke on 2013-08-20.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CanvasViewController.h"

@interface DrawerViewController : UIViewController

@property (nonatomic) CanvasViewController* topDrawerContents;
@property (nonatomic) CanvasViewController* bottomDrawerContents;

@end
