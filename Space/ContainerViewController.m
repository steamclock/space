//
//  ContainerViewController.m
//  Space
//
//  Created by Jeremy Chiang on 2013-10-24.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "ContainerViewController.h"

@interface ContainerViewController ()

@end

@implementation ContainerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldAutorotate {
    if (self.drawer.topDrawerContents.isRunningZoomAnimation) {
        return NO;
    } else {
        return YES;
    }
}

@end
