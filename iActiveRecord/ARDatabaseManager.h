//
//  ARDatabaseManager.m
//  iActiveRecord
//
//  Created by Alex Denisov on 10.01.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class ActiveRecord;
@class ARSQLBuilder;
@class ARLazyFetcher;

@interface ARDatabaseManager : NSObject
{
    @private
    sqlite3 *database;
    NSString *dbPath;
    NSString *dbName;
}

+ (void)disableMigrations;

- (void)createDatabase;
- (void)clearDatabase;

- (void)createTables;
- (void)createTable:(id)aRecord;
- (void)addColumn:(NSString *)aColumn onTable:(NSString *)aTable;
- (void)appendMigrations;

- (void)openConnection;
- (void)closeConnection;

- (NSArray *)tables;
- (NSArray *)describedTables;
- (NSArray *)columnsForTable:(NSString *)aTableName;

//- (NSString *)tableName:(NSString *)modelName;
- (NSString *)documentsDirectory;
- (NSString *)cachesDirectory;

+ (id)sharedInstance;

//- (NSNumber *)insertRecord:(NSString *)aRecordName withSqlQuery:(const char *)anSqlQuery;
- (void)executeSqlQuery:(const char *)anSqlQuery;
- (NSArray *)allRecordsWithName:(NSString *)aName withSql:(NSString *)aSqlRequest;
- (NSArray *)joinedRecordsWithSql:(NSString *)aSqlRequest;
//- (NSInteger)countOfRecordsWithName:(NSString *)aName;
- (NSInteger)functionResult:(NSString *)anSql;

+ (void)registerDatabase:(NSString *)aDatabaseName cachesDirectory:(BOOL)isCache;

- (void)skipBackupAttributeToFile:(NSURL*) url;

//  returns new record ID
//  or 0 if save failure
- (NSInteger)saveRecord:(ActiveRecord *)aRecord;
- (NSInteger)updateRecord:(ActiveRecord *)aRecord;
- (NSArray *)recordsWithFetcher:(ARLazyFetcher *)aFetcher;

- (sqlite3_stmt *)statementFromBuilder:(ARSQLBuilder *)aBuilder;

@end
 