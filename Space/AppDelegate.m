//
//  AppDelegate.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "AppDelegate.h"
#import "DrawerViewController.h"
#import "CanvasViewController.h"
#import "FocusViewController.h"
#import "CanvasSelectionViewController.h"
#import "Database.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.window makeKeyAndVisible];

    UIViewController* container = [[UIViewController alloc] init];
    
    CanvasViewController* noteCanvas = [[CanvasViewController alloc] initAsNoteCanvasWithTopLevelView:container.view];
    CanvasViewController* trashCanvas = [[CanvasViewController alloc] initAsTrashCanvasWithTopLevelView:container.view];
    
    DrawerViewController* drawer = [[DrawerViewController alloc] init];
    drawer.bottomDrawerContents = trashCanvas;
    drawer.topDrawerContents = noteCanvas;
    
    container.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [container addChildViewController:drawer];
    [container.view addSubview:drawer.view];
    
    FocusViewController* focus = [[FocusViewController alloc] init];
    focus.view.alpha = 0;
    noteCanvas.focus = focus;
    
    [container addChildViewController:focus];
    [container.view addSubview:focus.view];
    
    CanvasSelectionViewController* canvasSelect = [[CanvasSelectionViewController alloc] init];
    [container addChildViewController:canvasSelect];
    [container.view addSubview:canvasSelect.view];
    
    self.window.rootViewController = container;
    
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
