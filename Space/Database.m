//
//  Database.m
//  Space
//
//  Created by Nigel Brooke on 2013-08-15.
//  Copyright (c) 2013 University of British Columbia. All rights reserved.
//

#import "Database.h"

@interface Database ()

@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;

@end

@implementation Database

+(Database*)sharedDatabase {
    static Database* sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Database alloc] init];
    });
    
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Space" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Space.sqlite"];
        
        NSError *error = nil;
        self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             
             Typical reasons for an error here include:
             * The persistent store is not accessible;
             * The schema for the persistent store is incompatible with current managed object model.
             Check the error message to determine what the actual problem was.
             
             
             If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
             
             If you encounter schema incompatibility errors during development, you can reduce their frequency by:
             * Simply deleting the existing store:
             [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
             
             * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
             @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }

        if (self.persistentStoreCoordinator != nil) {
            self.managedObjectContext = [[NSManagedObjectContext alloc] init];
            [self.managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
        }
    }
    return self;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)save
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

-(void)deleteAllNotesInCanvas:(int)canvas {
    
    NSLog(@"Canvas to delete = %@", [NSNumber numberWithInt:canvas]);
    
    NSFetchRequest* deleteRequest = [[NSFetchRequest alloc] init];
    [deleteRequest setEntity:[NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.managedObjectContext]];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"canvas == %@", [NSNumber numberWithInt:canvas]];
    [deleteRequest setPredicate:predicate];
    
    NSError* error = nil;
    NSArray* notesToDelete = [self.managedObjectContext executeFetchRequest:deleteRequest error:&error];
    
    for (Note* note in notesToDelete) {
        [self.managedObjectContext deleteObject:note];
    }
    
    NSError* saveError = nil;
    [self.managedObjectContext save:&saveError];
}

-(Note*)createNote {
    
    Note* newNote = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
    
    newNote.trashed = NO;

    return newNote;
}

-(NSArray*)notesInCanvas:(int)canvas {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.predicate = [NSPredicate predicateWithFormat:@"canvas == %@ AND trashed == %@", [NSNumber numberWithInt:canvas], [NSNumber numberWithBool:NO]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    return [self getNotesWithRequest:request];
}

-(NSArray*)trashedNotesInCanvas:(int)canvas {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.predicate = [NSPredicate predicateWithFormat:@"canvas == %@ AND trashed == %@", [NSNumber numberWithInt:canvas], [NSNumber numberWithBool:YES]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    return [self getNotesWithRequest:request];
}

-(NSArray*)getNotesWithRequest:(NSFetchRequest*)request {
    
    NSError* error = nil;
    
    NSArray* results = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    
    if (results == nil) {
        // TODO: Handle the error.
    }
    
    return results;
}

@end
