//
//  CanvasTitleEditPopover.m
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasMenuPopover.h"
#import "Notifications.h"
#import "Constants.h"
#import "Database.h"

@interface CanvasMenuPopover ()

// Canvas titles and indices are stored in NSUserDefaults.
@property (strong, nonatomic) NSUserDefaults* defaults;

@property (strong, nonatomic) UIScrollView* scrollView;

// These properties assist with creating, editing, and deleting canvas titles.
@property (strong, nonatomic) UIButton* currentlyEditingButton;
@property (strong, nonatomic) NSString* currentlyEditingButtonTitle;
@property (strong, nonatomic) UITextField* currentlyEditingButtonTextField;

// The app cannot allow deleting the last remaining canvas.
@property (nonatomic) BOOL deleteTitleAllowed;

// Stores a list of buttons, each representing a stored and available canvas title.
@property (strong, nonatomic) NSMutableArray* allCanvasButtons;

@end

@implementation CanvasMenuPopover

@synthesize popoverController;

-(id)init {
    if (self = [super init]) {
        
        self.defaults = [NSUserDefaults standardUserDefaults];
        
        if ([self.defaults objectForKey:Key_CanvasTitles] && [self.defaults objectForKey:Key_CanvasTitleIndices]) {
            
            // Load available canvases.
            self.canvasTitles = [self.defaults objectForKey:Key_CanvasTitles];
            self.canvasTitleIndices = [self.defaults objectForKey:Key_CanvasTitleIndices];
            [self setupMenuWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
            
        } else {
            
            // If there are no canvases stored, initilalize two default ones.
            [self setupMenuWithCanvasTitles:@[@"Canvas One", @"Canvas Two"] andIndices:@[@0, @1]];
            
            [self.defaults setObject:[NSNumber numberWithInt:0] forKey:Key_CurrentCanvasIndex];
            [self.defaults synchronize];
        }
        
        if ([self.defaults objectForKey:Key_CurrentCanvasIndex]) {
            
            // Highlight the current canvas at the start of the app.
            int currentCanvas = [[self.defaults objectForKey:Key_CurrentCanvasIndex] intValue];
            
            UIButton* buttonToHighlight = (UIButton *)[self.allCanvasButtons objectAtIndex:currentCanvas];
            buttonToHighlight.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];
        }
    }
    
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.preferredContentSize = CGSizeMake(300.0f, 325.0f);
    
    // Setup the textfield for entering new canvas titles.
    CGRect rect = CGRectMake(20.0f, 20.0f, 260.0f, 25.0f);
    self.titleField = [[UITextField alloc] initWithFrame:rect];
    self.titleField.textAlignment = NSTextAlignmentCenter;
    self.titleField.placeholder = @"Enter new canvas title";
    [self.titleField setDelegate:self];
    [self.titleField setReturnKeyType:UIReturnKeyDone];
    [self.view addSubview:self.titleField];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.titleField setText:@""];
    
    // Workaround for Apple's bug in which the scroll indicator doesn't flash on the first viewDidAppear call.
    [self.scrollView performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0];
}

-(BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Canvas Menu Buttons

-(void)clearAllButtons {
    for (UIView* view in self.view.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            [view removeFromSuperview];
        }
    }
}

-(void)setupMenuWithCanvasTitles:(NSArray *)canvasTitles andIndices:(NSArray *)canvasIndices {
    
    if (self.scrollView) {
        [self.scrollView removeFromSuperview];
        self.scrollView = nil;
    }
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20.0f, 60.0f, 260.0f, 200.0f)];
    self.scrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.scrollView];
    
    self.allCanvasButtons = nil;
    self.allCanvasButtons = [[NSMutableArray alloc] init];
    
    // Allows setting up the popover menu from a fresh state everytime there's a change.
    [self clearAllButtons];
    
    // Store canvas titles and indices in NSUserDefaults.
    self.canvasTitles = [canvasTitles mutableCopy];
    self.canvasTitleIndices = [canvasIndices mutableCopy];
    [self.defaults setObject:self.canvasTitles forKey:Key_CanvasTitles];
    [self.defaults setObject:self.canvasTitleIndices forKey:Key_CanvasTitleIndices];
    [self.defaults synchronize];
    
    // Helps dynamically position canvas title buttons.
    int yCoord = 5;
    
    // Helps associate a button to its corresponding array index of the canvas titles and indices. (See .h for more info)
    int indexTag = 0;
    
    // Create a button for every canvas title.
    for (NSString* name in canvasTitles) {
        
        int buttonWidth = 250;
        int buttonHeight = 44;
        int gapBetweenButtons = 5;
        
        CGRect buttonFrame = CGRectMake(5, yCoord, buttonWidth, buttonHeight);
        
        UIButton* canvasButton = [UIButton buttonWithType:UIButtonTypeSystem];
        canvasButton.frame = buttonFrame;
        [canvasButton setTitle:name forState:UIControlStateNormal];
        canvasButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        canvasButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [canvasButton addTarget:self action:@selector(canvasSelected:) forControlEvents:UIControlEventTouchUpInside];
        
        // Add a hidden textfield to the button for editing canvas titles
        UITextField* buttonTextField = [[UITextField alloc] initWithFrame:canvasButton.bounds];
        [buttonTextField setTextAlignment:NSTextAlignmentCenter];
        [buttonTextField setHidden:YES];
        [buttonTextField setDelegate:self];
        [canvasButton addSubview:buttonTextField];
        
        // Allows editing of canvas title by holding down on the button
        UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(titleLongPress:)];
        [canvasButton addGestureRecognizer:longPress];
        
        canvasButton.tag = indexTag;
        indexTag++;
        
        [self.allCanvasButtons addObject:canvasButton];
        
        [self.scrollView addSubview:canvasButton];
        yCoord += buttonHeight + gapBetweenButtons;
    }
    
    self.scrollView.contentSize = CGSizeMake(260.0f, 50.0f * [canvasTitles count]);
}

-(void)titleLongPress:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return; // Disregard other states that are also part of a long press, so we don't enter this method multiple times.
    }
    
    // Only allows editing one canvas title at a time
    if (self.currentlyEditingButton == nil) {
        self.currentlyEditingButton = (UIButton *)recognizer.view;
        
        [self swapButtonWithTextField];
    }
}

-(void)swapButtonWithTextField {
    // Hide the button's title label so we can show the textfield on top of the button.
    self.currentlyEditingButtonTitle = self.currentlyEditingButton.titleLabel.text;
    [self.currentlyEditingButton setTitle:@"" forState:UIControlStateNormal];
    
    // Grab and show the textfield we've added as a subview in the canvas button.
    for (UIView* view in self.currentlyEditingButton.subviews) {
        
        if ([view isKindOfClass:[UITextField class]]) {
            
            self.currentlyEditingButtonTextField = (UITextField*)view;
            
            [self.currentlyEditingButtonTextField setHidden:NO];
            [self.currentlyEditingButtonTextField setText:@""];
            [self.currentlyEditingButtonTextField becomeFirstResponder];
            
            break;
        }
    }
}

#pragma mark - Select, Add, Update, Delete Canvases

-(IBAction)canvasSelected:(id)sender {
    UIButton* pressedButton = (UIButton*)sender;
    
    // NSLog(@"Button number = %@", [NSNumber numberWithInt:pressedButton.tag]);
    // NSLog(@"Canvas number = %@", self.canvasTitleIndices[pressedButton.tag]);
    int pressedButtonIndex = [self.allCanvasButtons indexOfObject:pressedButton];
    NSLog(@"Pressed button index = %d", pressedButtonIndex);
    
    [self.defaults setObject:[NSNumber numberWithInt:pressedButtonIndex] forKey:Key_CurrentCanvasIndex];
    [self.defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification
                                                        object:self
                                                      userInfo:@{Key_CanvasNumber:self.canvasTitleIndices[pressedButtonIndex],
                                                                 Key_CanvasName:[self.canvasTitles objectAtIndex:pressedButtonIndex]}];
    
    for (UIButton* button in self.allCanvasButtons) {
        button.backgroundColor = [UIColor clearColor];
    }
    
    pressedButton.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];
}

-(void)addNewCanvasTitle:(NSString *)newCanvasTitle {
    [self.canvasTitles addObject:newCanvasTitle];
    
    BOOL isIndexUpdated = NO;
    
    // Loop through canvas title indices and assign a unique number that has not been taken yet.
    for (int i = 0; i < [self.canvasTitleIndices count]; i++) {
        if ([self.canvasTitleIndices containsObject:[NSNumber numberWithInt:i]]) {
            continue;
        } else {
            [self.canvasTitleIndices addObject:[NSNumber numberWithInt:i]];
            isIndexUpdated = YES;
            break;
        }
    }
    
    if (isIndexUpdated == NO) {
        [self.canvasTitleIndices addObject:[NSNumber numberWithInt:self.canvasTitleIndices.count]];
    }
}

-(void)updateSelectedCanvas {
    [self.canvasTitles replaceObjectAtIndex:self.currentlyEditingButton.tag withObject:self.currentlyEditingButtonTextField.text];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification
                                                        object:self
                                                      userInfo:@{Key_CanvasNumber:[NSNumber numberWithInt:self.currentlyEditingButton.tag],
                                                                 Key_CanvasName:[self.canvasTitles objectAtIndex:self.currentlyEditingButton.tag]}];
}

-(void)deleteSelectedCanvas {
    // Reject delete if there's only one remaining canvas.
    if ([self.canvasTitles count] == 1) {
        NSLog(@"Tried to delete last canvas");
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Delete" message:@"This is the last canvas." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        
        // Delete operation completed, so reset the deleteTitleAllowed check.
        self.deleteTitleAllowed = NO;
        return;
    }
    
    // It's not the last canvas, so we can proceed with delete.
    
    int canvasToDelete;
    int indexOfCanvasToDelete;
    int canvasToSwitchTo;
    int indexOfCanvasToSwitchTo;
    
    indexOfCanvasToDelete = [self.allCanvasButtons indexOfObject:self.currentlyEditingButton];
    canvasToDelete = [self.canvasTitleIndices[indexOfCanvasToDelete] intValue];
    [[Database sharedDatabase] deleteAllNotesInCanvas:canvasToDelete];
    
    [self.canvasTitles removeObjectAtIndex:indexOfCanvasToDelete];
    [self.canvasTitleIndices removeObjectAtIndex:indexOfCanvasToDelete];
    
    // Switches canvas view to the previous one by default
    indexOfCanvasToSwitchTo = indexOfCanvasToDelete - 1;
    
    // Switches canvas view to the last available one (second object will move from index 1 to 0)
    // if the first of the two canvases is the one to be deleted.
    if (indexOfCanvasToDelete == 0) {
        indexOfCanvasToSwitchTo = 0;
    }
    
    canvasToSwitchTo = [[self.canvasTitleIndices objectAtIndex:indexOfCanvasToSwitchTo] intValue];
    NSLog(@"Canvas to switch to = %d", canvasToSwitchTo);
    
    [self.defaults setObject:[NSNumber numberWithInt:indexOfCanvasToSwitchTo] forKey:Key_CurrentCanvasIndex];
    [self.defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification
                                                        object:self
                                                      userInfo:@{Key_CanvasNumber:[NSNumber numberWithInt:canvasToSwitchTo],
                                                                 Key_CanvasName:[self.canvasTitles objectAtIndex:indexOfCanvasToSwitchTo]}];
    
    // Delete operation completed, so reset the deleteTitleAllowed check.
    self.deleteTitleAllowed = NO;
}

#pragma mark - TextField Delegate Methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.currentlyEditingButtonTextField) {
        
        [self.currentlyEditingButtonTextField setHidden:YES];
        [self.currentlyEditingButton setTitle:self.currentlyEditingButtonTitle forState:UIControlStateNormal];
        
        // Assumes delete when an empty string is provided, for now.
        if ([self.currentlyEditingButtonTextField.text isEqualToString:@""]) {
            
            self.deleteTitleAllowed = YES;
            
            [self deleteSelectedCanvas];
            
        } else { // Otherwise, update canvas with the newly provided name.
            
            [self updateSelectedCanvas];
        }
        
        [self setupMenuWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
        
    } else {
    
        [self addNewCanvasTitle:textField.text];
        
        [self setupMenuWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
        
        textField.text = @"";
        
        [textField resignFirstResponder];
    }
    
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField setReturnKeyType:UIReturnKeyDone];
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    // Only allow delete if Done is pressed on the keyboard. Don't delete if the popover is dismissed
    // by tapping somewhere else while the textfield is active.
    if (textField == self.currentlyEditingButtonTextField) {
        
        if (self.deleteTitleAllowed == NO) {
            // Restore canvas title.
            [self.currentlyEditingButton setTitle:self.currentlyEditingButtonTitle forState:UIControlStateNormal];
        }
        
        [self.currentlyEditingButtonTextField setHidden:YES];
        
        // Clear cache.
        self.currentlyEditingButton = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
