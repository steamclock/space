//
//  CanvasMenuViewController.m
//  Space
//
//  Created by Jeremy Chiang on 2013-10-30.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "CanvasMenuViewController.h"
#import "AppDelegate.h"
#import "DrawerViewController.h"
#import "Notifications.h"
#import "Constants.h"
#import "Database.h"

@interface CanvasMenuViewController ()

// Canvas titles and indices are stored in NSUserDefaults.
@property (strong, nonatomic) NSUserDefaults* defaults;

// The app cannot allow deleting the last remaining canvas.
@property (nonatomic) BOOL deleteCanvasAllowed;

// The cell that received a long press.
@property (strong, nonatomic) UITableViewCell* cellToEdit;
@property (strong, nonatomic) NSIndexPath* pathOfCellToEdit;
@property (strong, nonatomic) UITextField* currentTextField;
@property (nonatomic) BOOL isEditingCanvasTitle;

@end

static CanvasMenuViewController* _mainInstance;

@implementation CanvasMenuViewController

+(CanvasMenuViewController*)canvasMenuViewController {
    static dispatch_once_t once;
    if (_mainInstance == nil) {
        dispatch_once(&once, ^ { _mainInstance = [[CanvasMenuViewController alloc] initWithStyle:UITableViewStyleGrouped]; });
    }
    return _mainInstance;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.defaults = [NSUserDefaults standardUserDefaults];
    
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.tableView.contentInset = UIEdgeInsetsMake(-35, 0, 0, 0);
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    int currentCanvasIndex = [[self.defaults objectForKey:Key_CurrentCanvasIndex] intValue];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentCanvasIndex inSection:0]
                                animated:YES
                          scrollPosition:UITableViewScrollPositionBottom];
    
    // NSLog(@"Canvas titles count at viewDidAppear = %d", [self.canvasTitles count]);
    // NSLog(@"Canvas indices count at viewDidAppear = %d", [self.canvasTitleIndices count]);
}

-(void)viewDidLayoutSubviews {
    [self checkCanvasLimit];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.tableView setEditing:NO animated:YES];
    self.isEditingTableView = NO;
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupMenuWithCanvasTitles:(NSArray *)canvasTitles andIds:(NSArray *)canvasIds {
    // Store canvas titles and indices in NSUserDefaults.
    self.canvasTitles = [canvasTitles mutableCopy];
    self.canvasTitlesIds = [canvasIds mutableCopy];
    [self.defaults setObject:self.canvasTitles forKey:Key_CanvasTitles];
    [self.defaults setObject:self.canvasTitlesIds forKey:Key_CanvasTitlesIds];
    [self.defaults synchronize];
}

#pragma mark - Table View Data

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return [self.canvasTitles count];
    }
    
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"CellIdentifier";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    if (indexPath.section == 0) {
        cell.textLabel.text = [self.canvasTitles objectAtIndex:indexPath.row];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        // Allows editing of canvas title by holding down on the button.
        UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(titleLongPress:)];
        [cell addGestureRecognizer:longPress];
        
        // Add an initially hidden textfield to allow editing of the canvas title.
        UITextField* titleField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, 260, 25)];
        titleField.placeholder = @"Enter new canvas title";
        titleField.delegate = self;
        titleField.returnKeyType = UIReturnKeyDone;
        titleField.tag = 1;
        titleField.alpha = 0;
        
        [cell addSubview:titleField];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"About Space";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Tap and hold to change canvas title.";
    }
    
    return nil;
}

#pragma mark - Table View Edit Mode

-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (self.isEditingCanvasTitle) {
        [self saveCurrentlyEditingCanvas];
    }
     
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

// Override to support conditional editing of the table view.
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section == 0) {
        return YES;
    }
    
    return NO;
}

// Override to support editing the table view.
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.section == 0) {
            // Reject delete if there's only one remaining canvas.
            if ([self.canvasTitles count] == 1) {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Delete"
                                                                    message:@"This is the last canvas."
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles: nil];
                [alertView show];
                
                // Delete operation completed, so reset the check.
                self.deleteCanvasAllowed = NO;
                return;
            }
            
            AppDelegate* delegate = [UIApplication sharedApplication].delegate;
            DrawerViewController* drawerVC = delegate.drawer;
            
            if (drawerVC.topDrawerContents.isCurrentlyZoomedIn) {
                [drawerVC.topDrawerContents toggleZoomForNoteView:drawerVC.topDrawerContents.currentlyZoomedInNoteView completion:^{
                    [self deleteCanvas:indexPath.row];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasAddedorDeletedNotification object:self];
                }];
            } else {
                [self deleteCanvas:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasAddedorDeletedNotification object:self];
            }
        }
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - Delete Canvas

-(void)deleteCanvas:(int)canvasIndex {
    int canvasIdToDelete;
    int indexOfCanvasToDelete;
    int canvasIdToSwitchTo;
    int indexOfCanvasToSwitchTo;
    
    indexOfCanvasToDelete = canvasIndex;
    canvasIdToDelete = [self.canvasTitlesIds[indexOfCanvasToDelete] intValue];
    
    [[Database sharedDatabase] deleteAllNotesInCanvas:canvasIdToDelete];
    
    [self.canvasTitles removeObjectAtIndex:indexOfCanvasToDelete];
    [self.canvasTitlesIds removeObjectAtIndex:indexOfCanvasToDelete];
    [self.defaults setObject:self.canvasTitles forKey:Key_CanvasTitles];
    [self.defaults setObject:self.canvasTitlesIds forKey:Key_CanvasTitlesIds];
    [self.defaults synchronize];
    
    // Switches canvas view to the previous one by default
    indexOfCanvasToSwitchTo = indexOfCanvasToDelete - 1;
    
    // Switches canvas view to the last available one (second object will move from index 1 to 0)
    // if the first of the two canvases is the one to be deleted.
    if (indexOfCanvasToDelete == 0) {
        indexOfCanvasToSwitchTo = 0;
    }
    
    canvasIdToSwitchTo = [[self.canvasTitlesIds objectAtIndex:indexOfCanvasToSwitchTo] intValue];
    NSLog(@"Canvas to switch to after delete = %d", canvasIdToSwitchTo);
    
    [self.defaults setObject:[NSNumber numberWithInt:indexOfCanvasToSwitchTo] forKey:Key_CurrentCanvasIndex];
    [self.defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification
                                                        object:self
                                                      userInfo:@{Key_CanvasNumber:[NSNumber numberWithInt:canvasIdToSwitchTo],
                                                                 Key_CanvasName:[self.canvasTitles objectAtIndex:indexOfCanvasToSwitchTo]}];
    
    // Delete operation completed, so reset the check.
    self.deleteCanvasAllowed = NO;
    
    [self checkCanvasLimit];
}

#pragma mark - Edit Canvas

-(void)titleLongPress:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan || self.isEditingTableView) {
        return; // Disregard other states that are also part of a long press, so we don't enter this method multiple times.
    }
    
    if (self.cellToEdit == nil) {
        self.cellToEdit = (UITableViewCell*)recognizer.view;
        self.pathOfCellToEdit = [self.tableView indexPathForCell:self.cellToEdit];
        self.currentTextField = (UITextField*)[self.cellToEdit viewWithTag:1];
        
        if ([self.cellToEdit.textLabel.text isEqualToString:@""] || [self.cellToEdit.textLabel.text isEqualToString:@"No Title"]) {
            self.currentTextField.placeholder = @"Enter canvas name";
        } else {
            self.currentTextField.text = self.cellToEdit.textLabel.text;
        }
        
        [self swapTextLabelWithTextField];
    }
}

-(void)swapTextLabelWithTextField {
    if (self.isEditingCanvasTitle == NO) {
        
        self.cellToEdit.textLabel.alpha = 0;
        self.currentTextField.alpha = 1;
        
        [self.currentTextField becomeFirstResponder];
        
        self.isEditingCanvasTitle = YES;
        
    } else {
        
        [self updateCanvas];
    }
}

-(void)updateCanvas {
    if ([self.currentTextField.text isEqualToString:@""]) {
        [self.canvasTitles replaceObjectAtIndex:self.pathOfCellToEdit.row withObject:@"No Title"];
    } else {
        [self.canvasTitles replaceObjectAtIndex:self.pathOfCellToEdit.row withObject:self.currentTextField.text];
    }
    
    int canvasIdToUpdate = [[self.canvasTitlesIds objectAtIndex:self.pathOfCellToEdit.row] intValue];
    
    [self.defaults setObject:[NSNumber numberWithInt:self.pathOfCellToEdit.row] forKey:Key_CurrentCanvasIndex];
    [self.defaults setObject:self.canvasTitles forKey:Key_CanvasTitles];
    [self.defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification
                                                        object:self
                                                      userInfo:@{Key_CanvasNumber:[NSNumber numberWithInt:canvasIdToUpdate],
                                                                 Key_CanvasName:[self.canvasTitles objectAtIndex:self.pathOfCellToEdit.row]}];
    
    self.cellToEdit.textLabel.alpha = 1;
    self.currentTextField.alpha = 0;
    
    [self.tableView reloadData];
    
    self.cellToEdit = nil;
    self.currentTextField = nil;
    
    self.isEditingCanvasTitle = NO;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.currentTextField) {
        [self updateCanvas];
    }
    
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.currentTextField) {
        [self swapTextLabelWithTextField];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Add Canvas

-(void)addCanvas {
    if (self.isEditingTableView) {
        [self.tableView setEditing:NO animated:YES];
        self.isEditingTableView = NO;
    }
    
    if (self.isEditingCanvasTitle) {
        [self saveCurrentlyEditingCanvas];
    }
    
    if ([self checkCanvasLimit]) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Add Canvas"
                                                            message:@"The maximum number of canvases you can create is 5."
                                                           delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
        
        return;
    }
    
    NSIndexPath* newCanvasPath = [NSIndexPath indexPathForRow:[self.canvasTitles count] inSection:0];
    
    [self.canvasTitles addObject:@""];

    BOOL isIndexUpdated = NO;
    
    // Loop through canvas title indices and assign a unique number that has not been taken yet.
    for (int i = 0; i < [self.canvasTitlesIds count]; i++) {
        if ([self.canvasTitlesIds containsObject:[NSNumber numberWithInt:i]]) {
            continue;
        } else {
            [self.canvasTitlesIds addObject:[NSNumber numberWithInt:i]];
            isIndexUpdated = YES;
            break;
        }
    }
    
    if (isIndexUpdated == NO) {
        [self.canvasTitlesIds addObject:[NSNumber numberWithInt:self.canvasTitlesIds.count]];
    }
    
    [self.defaults setObject:[NSNumber numberWithInt:newCanvasPath.row] forKey:Key_CurrentCanvasIndex];
    [self.defaults setObject:self.canvasTitles forKey:Key_CanvasTitles];
    [self.defaults setObject:self.canvasTitlesIds forKey:Key_CanvasTitlesIds];
    [self.defaults synchronize];
    
    [self.tableView insertRowsAtIndexPaths:@[newCanvasPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if (self.cellToEdit == nil) {
        self.cellToEdit = [self.tableView cellForRowAtIndexPath:newCanvasPath];
        self.pathOfCellToEdit = [self.tableView indexPathForCell:self.cellToEdit];
        self.currentTextField = (UITextField*)[self.cellToEdit viewWithTag:1];
        
        self.currentTextField.text = @"";
        
        [self swapTextLabelWithTextField];
    }
    
    [self.tableView selectRowAtIndexPath:newCanvasPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasAddedorDeletedNotification object:self];
}

-(void)saveCurrentlyEditingCanvas {
    if ([self.currentTextField.text isEqualToString:@""]) {
        [self.canvasTitles replaceObjectAtIndex:self.pathOfCellToEdit.row withObject:@"No Title"];
    } else {
        [self.canvasTitles replaceObjectAtIndex:self.pathOfCellToEdit.row withObject:self.currentTextField.text];
    }
    
    [self.defaults setObject:[NSNumber numberWithInt:self.pathOfCellToEdit.row] forKey:Key_CurrentCanvasIndex];
    [self.defaults setObject:self.canvasTitles forKey:Key_CanvasTitles];
    [self.defaults synchronize];
    
    self.cellToEdit.textLabel.alpha = 1;
    self.currentTextField.alpha = 0;
    
    [self.tableView reloadData];
        
    self.cellToEdit = nil;
    self.currentTextField = nil;
    
    self.isEditingCanvasTitle = NO;
}

-(BOOL)checkCanvasLimit {
    if ([self.canvasTitles count] >= 5) {
        NSLog(@"Cannot allow more than 5 canvases.");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDisableAddButtonNotification object:self];
        
        return YES;
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kEnableAddButtonNotification object:self];
        
        return NO;
    }
}

#pragma mark - Select Canvas

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [self selectCanvas:indexPath.row];
    } else if (indexPath.section == 1) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowAboutPageNotification
                                                            object:self
                                                          userInfo:nil];
    }
}

-(void)selectCanvas:(int)canvasIndex {
    NSLog(@"Selected canvas = %d", canvasIndex);
    
    if (self.isEditingCanvasTitle) {
        [self swapTextLabelWithTextField];
    }
    
    // Store the currently selected canvas index for future reference.
    [self.defaults setObject:[NSNumber numberWithInt:canvasIndex] forKey:Key_CurrentCanvasIndex];
    [self.defaults synchronize];
    
    // Ask observer to change canvas.
    [[NSNotificationCenter defaultCenter] postNotificationName:kCanvasChangedNotification
                                                        object:self
                                                      userInfo:@{Key_CanvasNumber:self.canvasTitlesIds[canvasIndex],
                                                                 Key_CanvasName:[self.canvasTitles objectAtIndex:canvasIndex]}];
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
