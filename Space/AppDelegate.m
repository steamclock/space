//
//  AppDelegate.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "AppDelegate.h"
#import "ContainerViewController.h"
#import "CanvasViewController.h"
#import "FocusViewController.h"
#import "CanvasNavBarController.h"
#import "Database.h"
#import "UIResponder+KeyboardCache.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.window.tintColor = [UIColor colorWithHue:(127.0/360.0) saturation:1.0 brightness:0.8 alpha:1.0];
    
    [self.window makeKeyAndVisible];
    
    //self.window.tintColor = [UIColor orangeColor];

    ContainerViewController* container = [[ContainerViewController alloc] init];
    
    CanvasViewController* noteCanvas = [[CanvasViewController alloc] initAsNoteCanvasWithTopLevelView:container.view];
    CanvasViewController* trashCanvas = [[CanvasViewController alloc] initAsTrashCanvasWithTopLevelView:container.view];
    
    self.drawer = [[DrawerViewController alloc] init];
    self.drawer.bottomDrawerContents = trashCanvas;
    self.drawer.topDrawerContents = noteCanvas;
    
    container.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [container addChildViewController:self.drawer];
    [container.view addSubview:self.drawer.view];
    
    noteCanvas.drawer = self.drawer;
    trashCanvas.drawer = self.drawer;
    container.drawer = self.drawer;
    
    FocusViewController* focus = [[FocusViewController alloc] init];
    focus.view.alpha = 0;
    noteCanvas.focus = focus;
    
    __weak CanvasViewController* weakNoteCanvas = noteCanvas;
    noteCanvas.focus.titleEntered = ^void(NSString* newTitle) {
        weakNoteCanvas.currentlyZoomedInNoteView.titleLabel.text = newTitle;
        if ([weakNoteCanvas.currentlyZoomedInNoteView.titleLabel.text length] > 15) {
            weakNoteCanvas.currentlyZoomedInNoteView.titleLabel.text = [NSString stringWithFormat:@"%@...", [newTitle substringToIndex:15]];
        }
    };
    
    [container addChildViewController:focus];
    [container.view addSubview:focus.view];
    
    CanvasNavBarController* canvasSelect = [[CanvasNavBarController alloc] init];
    [container addChildViewController:canvasSelect];
    [container.view addSubview:canvasSelect.view];
    
    self.window.rootViewController = container;
    
    [UIResponder cacheKeyboard];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [[Database sharedDatabase] save];
}

@end
