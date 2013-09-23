//
//  CanvasSelectionViewController.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-26.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasSelectionViewController.h"
#import "CanvasTitleEditPopover.h"
#import "Database.h"
#import "Notifications.h"
#import "Constants.h"

@interface CanvasSelectionViewController ()

@property UIToolbar* toolbar;
@property NSArray* buttons;

@property (strong, nonatomic) NSMutableArray* canvasTitles;
@property (strong, nonatomic) NSMutableArray* canvasTitleIndices;

@property (strong, nonatomic) UIButton* currentlyEditingButton;
@property (strong, nonatomic) UILabel* currentlyEditingTitle;
@property (strong, nonatomic) UIPopoverController* popoverController;

// Cannot use a variable name that starts with "new"
@property (strong, nonatomic) NSString* brandNewCanvasTitle;

@property (strong, nonatomic) NSUserDefaults* defaults;

@end

@implementation CanvasSelectionViewController

@synthesize popoverController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        self.toolbar = [UIToolbar new];
        self.defaults = [NSUserDefaults standardUserDefaults];

        if ([self.defaults objectForKey:Key_CanvasTitles] && [self.defaults objectForKey:Key_CanvasTitleIndices]) {
            self.canvasTitles = [self.defaults objectForKey:Key_CanvasTitles];
            self.canvasTitleIndices = [self.defaults objectForKey:Key_CanvasTitleIndices];
            [self setupToolbarWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
        } else {
            [self setupToolbarWithCanvasTitles:@[@"One", @"Two"] andIndices:@[@0, @1]];
        }
        
        self.view = self.toolbar;
        
        Class popoverClass = NSClassFromString(@"UIPopoverController");
        
        if (popoverClass != nil && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            CanvasTitleEditPopover *canvasTitlePopover = [[CanvasTitleEditPopover alloc] init];
            self.popoverController = [[UIPopoverController alloc] initWithContentViewController:canvasTitlePopover];
            canvasTitlePopover.popoverController = self.popoverController;
            
            __weak CanvasSelectionViewController* weakSelf = self;
            canvasTitlePopover.newTitleEntered = ^(NSString* title) {
                weakSelf.brandNewCanvasTitle = title;
                NSLog(@"New title = %@", weakSelf.brandNewCanvasTitle);
                [self.canvasTitles addObject:weakSelf.brandNewCanvasTitle];
                
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
                
                [self setupToolbarWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
            };
        }
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.view.frame = CGRectMake(0, 0, self.view.superview.bounds.size.width, 50);
    self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupToolbarWithCanvasTitles:(NSArray*)canvasTitles andIndices:(NSArray*)canvasIndices
{
    self.toolbar.items = nil;
    
    self.canvasTitles = [canvasTitles mutableCopy];
    self.canvasTitleIndices = [canvasIndices mutableCopy];
    [self.defaults setObject:self.canvasTitles forKey:Key_CanvasTitles];
    [self.defaults setObject:self.canvasTitleIndices forKey:Key_CanvasTitleIndices];
    [self.defaults synchronize];
    
    NSMutableArray* items = [NSMutableArray new];
    NSMutableArray* buttons = [NSMutableArray new];
    
    // Used to help identify and locate the custom UIButton that's embedded in each of the BarButtonItems,
    // corresponds to actual canvas title array's index that the button represents.
    int indexTag = 0;
    
    for (NSString* name in canvasTitles) {
        [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] ];
        
        CGRect rect = CGRectMake(0, 0, 100, 44);
        
        UITextField* buttonTextField = [[UITextField alloc] initWithFrame:rect];
        [buttonTextField setTextAlignment:NSTextAlignmentCenter];
        [buttonTextField setHidden:YES];
        [buttonTextField setDelegate:self];
        
        UILabel* buttonLabel = [[UILabel alloc] initWithFrame:rect];
        [buttonLabel setText:name];
        [buttonLabel setTextAlignment:NSTextAlignmentCenter];
        
        UIButton* customBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        customBarButton.frame = rect;
        [customBarButton addSubview:buttonTextField];
        [customBarButton addSubview:buttonLabel];
        [customBarButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(titleLongPress:)];
        [customBarButton addGestureRecognizer:longPress];
        
        customBarButton.tag = indexTag;
        indexTag++;
        
        UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithCustomView:customBarButton];
        
        // UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStylePlain target:self action:@selector(buttonPress:)];
        [items addObject: button];
        [buttons addObject:button];
    }

    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] ];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showPopover:)]];
    
    self.toolbar.items = items;
    self.buttons = buttons;
}

-(IBAction)buttonPress:(id)sender {
    UIButton* pressedButton = (UIButton*)sender;
    
    // NSLog(@"Button number = %@", [NSNumber numberWithInt:pressedButton.tag]);
    // NSLog(@"Canvas number = %@", self.canvasTitleIndices[pressedButton.tag]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification object:self userInfo:@{@"canvas":self.canvasTitleIndices[pressedButton.tag]}];
}

-(IBAction)titleLongPress:(UITapGestureRecognizer *)recognizer {
    
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return; // Disregard other states that are also part of a long press, so we don't enter this method multiple times
    }
    
    self.currentlyEditingButton = (UIButton*)recognizer.view;
    
    [self swapTextFieldWithTitleLabel];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self.currentlyEditingTitle setText:textField.text];
    
    int canvasToDelete = 0;
    int canvasToSwitchTo = 0;
    
    // Assumes delete when an empty string is provided, for now.
    if([textField.text isEqualToString:@""]) {
        
        canvasToDelete = [self.canvasTitleIndices[self.currentlyEditingButton.tag] intValue];
        [[Database sharedDatabase] deleteAllNotesInCanvas:canvasToDelete];
        [self.canvasTitles removeObjectAtIndex:self.currentlyEditingButton.tag];
        [self.canvasTitleIndices removeObjectAtIndex:self.currentlyEditingButton.tag];
        
        int indexOfCanvasToSwitchTo = self.currentlyEditingButton.tag - 1;
        if (indexOfCanvasToSwitchTo < 0) {
            indexOfCanvasToSwitchTo = 0;
        }
        canvasToSwitchTo = [[self.canvasTitleIndices objectAtIndex:indexOfCanvasToSwitchTo] intValue];
        if (canvasToSwitchTo < 0) {
            canvasToSwitchTo = 0;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification object:self userInfo:@{@"canvas":[NSNumber numberWithInt:canvasToSwitchTo]}];
        
    } else {
        [self.canvasTitles replaceObjectAtIndex:self.currentlyEditingButton.tag withObject:textField.text];
        [self.canvasTitleIndices replaceObjectAtIndex:self.currentlyEditingButton.tag withObject:textField.text];
    }
    
    [self swapTextFieldWithTitleLabel];
    
    [textField resignFirstResponder];
    
    [self setupToolbarWithCanvasTitles:self.canvasTitles andIndices:self.canvasTitleIndices];
    
    return YES;
}

-(void)swapTextFieldWithTitleLabel {
    
    for (UIView* view in self.currentlyEditingButton.subviews) {
        
        if ([view isKindOfClass:[UILabel class]]) {
            
            self.currentlyEditingTitle = (UILabel*)view;
            
            if (self.currentlyEditingTitle.hidden) {
                [self.currentlyEditingTitle setHidden:NO];
            } else {
                [self.currentlyEditingTitle setHidden:YES];
            }
            
            continue;
            
        } else if ([view isKindOfClass:[UITextField class]]) {
            
            UITextField* textField = (UITextField*)view;
            [textField setText:@""];
            
            if (textField.hidden) {
                [textField setHidden:NO];
            } else {
                [textField setHidden:YES];
            }
            
            [textField becomeFirstResponder];
            
            continue;
        }
    }
}

-(IBAction)showPopover:(id)sender {
    [self.popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
