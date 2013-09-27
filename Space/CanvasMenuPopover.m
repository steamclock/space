//
//  CanvasTitleEditPopover.m
//  Space
//
//  Created by Jeremy Chiang on 2013-09-04.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasMenuPopover.h"
#import "Constants.h"
#import "Database.h"
#import "Notifications.h"

@interface CanvasMenuPopover ()

@property (strong, nonatomic) NSUserDefaults* defaults;
@property (strong, nonatomic) UIButton* currentlyEditingButton;
@property (strong, nonatomic) NSString* currentlyEditingButtonTitle;
@property (strong, nonatomic) UITextField* currentlyEditingButtonTextField;

@property (nonatomic) BOOL deleteTitleAllowed;

@end

@implementation CanvasMenuPopover

@synthesize popoverController;

- (id)init {
    
    if (self = [super init]) {
        
        self.defaults = [NSUserDefaults standardUserDefaults];
        
        if ([self.defaults objectForKey:Key_CanvasTitles] && [self.defaults objectForKey:Key_CanvasTitleIndices]) {
            
            self.canvasTitles = [self.defaults objectForKey:Key_CanvasTitles];
            self.canvasTitleIndices = [self.defaults objectForKey:Key_CanvasTitleIndices];
            
            [self setupMenuWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
            
        } else {
            
            // If there are no canvases stored, initilalize two default ones
            [self setupMenuWithCanvasTitles:@[@"Canvas One", @"Canvas Two"] andIndices:@[@0, @1]];
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.preferredContentSize = CGSizeMake(300.0f, 600.0f);
    
    // Setup the textfield for entering new canvas titles
    CGRect rect = CGRectMake(20.0f, 20.0f, 260.0f, 25.0f);
    self.titleField = [[UITextField alloc] initWithFrame:rect];
    self.titleField.textAlignment = NSTextAlignmentCenter;
    self.titleField.placeholder = @"Enter new canvas title";
    [self.titleField setDelegate:self];
    [self.titleField setReturnKeyType:UIReturnKeyDone];
    [self.view addSubview:self.titleField];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.titleField setText:@""];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Canvas Button

- (void)clearAllButtons {
    
    for (UIView* view in self.view.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            [view removeFromSuperview];
        }
    }
}

- (void)setupMenuWithCanvasTitles:(NSArray *)canvasTitles andIndices:(NSArray *)canvasIndices {
    
    [self clearAllButtons];
    
    // Store canvas titles and indices to NSUserDefaults
    self.canvasTitles = [canvasTitles mutableCopy];
    self.canvasTitleIndices = [canvasIndices mutableCopy];
    [self.defaults setObject:self.canvasTitles forKey:Key_CanvasTitles];
    [self.defaults setObject:self.canvasTitleIndices forKey:Key_CanvasTitleIndices];
    [self.defaults synchronize];
    
    // Helps dynamically position canvas title buttons
    int yCoord = 60;
    
    // Helps associate a button to its corresponding canvas index
    int indexTag = 0;
    
    // Create a button for every canvas title
    for (NSString* name in canvasTitles) {
        
        int buttonWidth = 250;
        int buttonHeight = 44;
        int gapBetweenButtons = 5;
        
        CGRect buttonFrame = CGRectMake(20, yCoord, buttonWidth, buttonHeight);
        
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
        
        [self.view addSubview:canvasButton];
        yCoord += buttonHeight + gapBetweenButtons;
    }
}

- (void)titleLongPress:(UITapGestureRecognizer *)recognizer {
    
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return; // Disregard other states that are also part of a long press, so we don't enter this method multiple times
    }
    
    // Only allows editing one canvas title at a time
    if (self.currentlyEditingButton == nil) {
        self.currentlyEditingButton = (UIButton *)recognizer.view;
        
        [self swapButtonWithTextField];
    }
}

- (void)swapButtonWithTextField {
    
    // Hide the button's title label so we can show the textfield on top of the button
    self.currentlyEditingButtonTitle = self.currentlyEditingButton.titleLabel.text;
    [self.currentlyEditingButton setTitle:@"" forState:UIControlStateNormal];
    
    // Grab and show the textfield we've added as a subview in the canvas button
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification object:self userInfo:@{@"canvas":self.canvasTitleIndices[pressedButton.tag], @"canvasName":[self.canvasTitles objectAtIndex:pressedButton.tag]}];
}

- (void)addNewCanvasTitle:(NSString *)newCanvasTitle {
    
    [self.canvasTitles addObject:newCanvasTitle];
    
    BOOL isIndexUpdated = NO;
    
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

- (void)updateSelectedCanvas {
    
    [self.canvasTitles replaceObjectAtIndex:self.currentlyEditingButton.tag withObject:self.currentlyEditingButtonTextField.text];
    [self.canvasTitleIndices replaceObjectAtIndex:self.currentlyEditingButton.tag withObject:self.currentlyEditingButtonTextField.text];
}

- (void)deleteSelectedCanvas {
    
    int canvasToDelete;
    int canvasToSwitchTo;
    
    canvasToDelete = [self.canvasTitleIndices[self.currentlyEditingButton.tag] intValue];
    [[Database sharedDatabase] deleteAllNotesInCanvas:canvasToDelete];
    [self.canvasTitles removeObjectAtIndex:self.currentlyEditingButton.tag];
    [self.canvasTitleIndices removeObjectAtIndex:self.currentlyEditingButton.tag];
    
    // Switches canvas view to the previous one or to the first one if it's the last canvas
    int indexOfCanvasToSwitchTo = self.currentlyEditingButton.tag - 1;
    if (indexOfCanvasToSwitchTo < 0) {
        indexOfCanvasToSwitchTo = 0;
    }
    canvasToSwitchTo = [[self.canvasTitleIndices objectAtIndex:indexOfCanvasToSwitchTo] intValue];
    if (canvasToSwitchTo < 0) {
        canvasToSwitchTo = 0;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification object:self userInfo:@{@"canvas":[NSNumber numberWithInt:canvasToSwitchTo], @"canvasName":[self.canvasTitles objectAtIndex:canvasToSwitchTo]}];
    
    self.deleteTitleAllowed = NO;
}

#pragma mark - TextField Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.currentlyEditingButtonTextField) {
        
        [self.currentlyEditingButtonTextField setHidden:YES];
        [self.currentlyEditingButton setTitle:self.currentlyEditingButtonTitle forState:UIControlStateNormal];
        
        // Assumes delete when an empty string is provided, for now.
        if ([self.currentlyEditingButtonTextField.text isEqualToString:@""]) {
            
            self.deleteTitleAllowed = YES;
            
            // Check whether delete is allowed, and delete if nothing was entered
            [self deleteSelectedCanvas];
            
        } else { // Otherwise, update canvas with newly provided name
            
            [self updateSelectedCanvas];
        }
        
        [self setupMenuWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
        
    } else {
    
        [self addNewCanvasTitle:textField.text];
        
        [self setupMenuWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
        
        textField.text = @"";
        
        [textField resignFirstResponder];
        // [self.popoverController dismissPopoverAnimated:YES];
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    // Only allow delete if Done is pressed on the keyboard. Don't delete if the popover is dismissed
    // by tapping somewhere else while the textfield is active.
    if (textField == self.currentlyEditingButtonTextField) {
        
        if (self.deleteTitleAllowed == NO) {
            // Restore canvas title
            [self.currentlyEditingButton setTitle:self.currentlyEditingButtonTitle forState:UIControlStateNormal];
        }
        
        [self.currentlyEditingButtonTextField setHidden:YES];
        
        // Clear cache
        self.currentlyEditingButton = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
