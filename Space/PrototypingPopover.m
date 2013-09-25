//
//  PrototypingPopover.m
//  Space
//
//  Created by Jeremy Chiang on 2013-09-24.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "PrototypingPopover.h"
#import "Notifications.h"

@interface PrototypingPopover ()

@property (strong, nonatomic) UIActionSheet* drawerLayoutSelection;
@property (strong, nonatomic) UIActionSheet* focusModeSelection;

@property (strong, nonatomic) UILabel* layoutLabel;
@property (strong, nonatomic) UILabel* focusLabel;

@end

@implementation PrototypingPopover

@synthesize popoverController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    UIButton* layoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [layoutButton setTitle:@"Layout" forState:UIControlStateNormal];
    layoutButton.titleLabel.font = [UIFont systemFontOfSize:20];
    CGRect layoutButtonFrame = CGRectMake(5, 10, 100, 50);
    layoutButton.frame = layoutButtonFrame;
    [layoutButton addTarget:self action:@selector(showDrawerLayoutSelection) forControlEvents:UIControlEventTouchUpInside];
    
    self.layoutLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 10, 100, 50)];
    [self.layoutLabel setText:@"Original"];
    
    UIButton* focusButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [focusButton setTitle:@"Focus" forState:UIControlStateNormal];
    focusButton.titleLabel.font = [UIFont systemFontOfSize:20];
    CGRect focusButtonFrame = CGRectMake(5, 80, 100, 50);
    focusButton.frame = focusButtonFrame;
    [focusButton addTarget:self action:@selector(showFocusModeSelection) forControlEvents:UIControlEventTouchUpInside];
    
    self.focusLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 80, 100, 50)];
    [self.focusLabel setText:@"Dimming"];
    
    [self.view addSubview:layoutButton];
    [self.view addSubview:self.layoutLabel];
    [self.view addSubview:focusButton];
    [self.view addSubview:self.focusLabel];
}

- (void)showDrawerLayoutSelection {
    
    self.drawerLayoutSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Drawer Layout"
                                                             delegate:(id<UIActionSheetDelegate>)self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Original", @"Alternative", nil];
    [self.drawerLayoutSelection showInView:self.view];
}

- (void)showFocusModeSelection {
    
    self.focusModeSelection = [[UIActionSheet alloc] initWithTitle:@"Choose a Focus Mode"
                                                          delegate:(id<UIActionSheetDelegate>)self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Dimming", @"Slide Out", nil];
    [self.focusModeSelection showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet == self.drawerLayoutSelection) {
        
        if (buttonIndex == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoadOriginalDrawerNotification object:nil];
            [self.layoutLabel setText:@"Original"];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoadAlternativeDrawerNotification object:nil];
            [self.layoutLabel setText:@"Alternative"];
        }
        
    } else {
        
        if (buttonIndex == 0) {
            NSDictionary *focusMode = [[NSDictionary alloc] initWithObjectsAndKeys:@"dim", @"focusMode", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeFocusModeNotification object:nil userInfo:focusMode];
            [self.focusLabel setText:@"Dimming"];
        } else {
            NSDictionary *focusMode = [[NSDictionary alloc] initWithObjectsAndKeys:@"slide", @"focusMode", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeFocusModeNotification object:nil userInfo:focusMode];
            [self.focusLabel setText:@"Sliding"];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
