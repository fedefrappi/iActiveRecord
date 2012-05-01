//
//  ARDatabaseManager.m
//  iActiveRecord
//
//  Created by Alex Denisov on 10.01.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "ARDatabaseManager.h"
#import "ActiveRecord.h"
#import "class_getSubclasses.h"
#import <sys/xattr.h>
#import "ARObjectProperty.h"
#import "sqlite3_unicode.h"
#import "ActiveRecord_Private.h"
#import "ARDataType.h"
#import "ARColumn.h"
#import "ARSQLBuilder.h"


#define DEFAULT_DBNAME @"database"

@implementation ARDatabaseManager

static ARDatabaseManager *instance = nil;
static BOOL useCacheDirectory = YES;
static NSString *databaseName = DEFAULT_DBNAME;
static BOOL migrationsEnabled = YES;

+ (void)registerDatabase:(NSString *)aDatabaseName cachesDirectory:(BOOL)isCache {
    databaseName = [aDatabaseName copy];
    useCacheDirectory = isCache;
}

+ (id)sharedInstance {
    @synchronized(self){
        if(nil == instance){
            instance = [[ARDatabaseManager alloc] init];
        }
        return instance;
    }    
}

- (id)init {
    self = [super init];
    if(nil != self){
#ifdef UNIT_TEST
        dbName = [[NSString alloc] initWithFormat:@"%@-test.sqlite", databaseName];
#else
        dbName = [[NSString alloc] initWithFormat:@"%@.sqlite", databaseName];
#endif
        NSString *storageDirectory = useCacheDirectory ? [self cachesDirectory] : [self documentsDirectory];
        dbPath = [[NSString alloc] initWithFormat:@"%@/%@", storageDirectory, dbName];
        NSLog(@"%@", dbPath);
        [self createDatabase];
    }
    return self;
}

- (void)dealloc{
    [self closeConnection];
    [dbName release];
    [dbPath release];
    [super dealloc];
}

- (void)createDatabase {
    if(![[NSFileManager defaultManager] fileExistsAtPath:dbPath]){
        [[NSFileManager defaultManager] createFileAtPath:dbPath contents:nil attributes:nil];
        if(!useCacheDirectory){
            [self skipBackupAttributeToFile:[NSURL fileURLWithPath:dbPath]];
        }
        [self openConnection];
        [self createTables];
        return;
    }
    [self openConnection];
    [self appendMigrations];
}

- (void)clearDatabase {
    NSArray *entities = class_getSubclasses([ActiveRecord class]);
    for(Class Record in entities){
        [Record performSelector:@selector(dropAllRecords)];
    }
}

- (void)createTables {
    NSArray *entities = class_getSubclasses([ActiveRecord class]);
    for(Class Record in entities){
        [self createTable:Record];
    }
}

- (void)createTable:(id)aRecord {
    const char *sqlQuery = (const char *)[aRecord performSelector:@selector(sqlOnCreate)];
    [self executeSqlQuery:sqlQuery];
}

- (void)appendMigrations {
    if(!migrationsEnabled){
        return;
    }
    NSArray *existedTables = [self tables];
    NSArray *describedTables = [self describedTables];
    for(NSString *table in describedTables){
        if(![existedTables containsObject:table]){
            [self createTable:NSClassFromString(table)];
        }else{
            Class Record = NSClassFromString(table);
            NSArray *existedColumns = [self columnsForTable:table];
            
            NSArray *describedProperties = [Record performSelector:@selector(tableFields)];
            NSMutableArray *describedColumns = [NSMutableArray array];
            for(ARObjectProperty *property in describedProperties){
                [describedColumns addObject:property.propertyName];
            }
            for(NSString *column in describedColumns){
                if(![existedColumns containsObject:column]){
                    const char *sql = (const char *)[Record performSelector:@selector(sqlOnAddColumn:) 
                                                                 withObject:column];
                    [self executeSqlQuery:sql];
                }
            }
        }
    }
}

- (void)addColumn:(NSString *)aColumn onTable:(NSString *)aTable {
    
}

- (NSArray *)describedTables {
    NSArray *entities = class_getSubclasses([ActiveRecord class]);
    NSMutableArray *tables = [NSMutableArray arrayWithCapacity:entities.count];
    for(Class record in entities){
        [tables addObject:NSStringFromClass(record)];
    }
    return tables;
}

- (NSArray *)columnsForTable:(NSString *)aTableName {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info('%@')", aTableName];
    NSMutableArray *resultArray = nil;
    char **results;
    int nRows;
    int nColumns;
    const char *pszSql = [sql UTF8String];
    if(SQLITE_OK == sqlite3_get_table(database,
                                      pszSql,
                                      &results,
                                      &nRows,
                                      &nColumns,
                                      NULL))
    {
        resultArray = [NSMutableArray arrayWithCapacity:nRows++];
        for(int i=0;i<nRows-1;i++){
            int index = (i + 1)*nColumns + 1;
            const char *pszValue = results[index];
            if(pszValue){
                [resultArray addObject:[NSString stringWithUTF8String:pszValue]];
            }
        }
        sqlite3_free_table(results);
    }else
    {
        NSLog(@"Couldn't retrieve data from database: %s", sqlite3_errmsg(database));
    }
    return resultArray;
}

//  select tbl_name from sqlite_master where type='table' and name not like 'sqlite_%'
- (NSArray *)tables {
    NSMutableArray *resultArray = nil;
    char **results;
    int nRows;
    int nColumns;
    const char *pszSql = [@"select tbl_name from sqlite_master where type='table' and name not like 'sqlite_%'" UTF8String];
    if(SQLITE_OK == sqlite3_get_table(database,
                                      pszSql,
                                      &results,
                                      &nRows,
                                      &nColumns,
                                      NULL))
    {
        resultArray = [NSMutableArray arrayWithCapacity:nRows++];
        for(int i=0;i<nRows-1;i++){
            for(int j=0;j<nColumns;j++){
                int index = (i+1)*nColumns + j;
                [resultArray addObject:[NSString stringWithUTF8String:results[index]]];
            }
        }
        sqlite3_free_table(results);
    }else
    {
        NSLog(@"Couldn't retrieve data from database: %s", sqlite3_errmsg(database));
    }
    return resultArray;
}

- (void)openConnection {
    sqlite3_unicode_load();
    if(SQLITE_OK != sqlite3_open([dbPath UTF8String], &database)){
        NSLog(@"Couldn't open database connection: %s", sqlite3_errmsg(database));
    }
}

- (void)closeConnection {
    sqlite3_close(database);
    sqlite3_unicode_free();
}

//- (NSNumber *)insertRecord:(NSString *)aRecordName withSqlQuery:(const char *)anSqlQuery {
//    [self executeSqlQuery:anSqlQuery];
//    return [self getLastId:aRecordName];
//}

- (void)executeSqlQuery:(const char *)anSqlQuery {
    if(SQLITE_OK != sqlite3_exec(database, anSqlQuery, NULL, NULL, NULL)){
        NSLog(@"Couldn't execute query %s : %s", anSqlQuery, sqlite3_errmsg(database));
    }
}
 
- (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
}

- (NSString *)cachesDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
}

- (NSArray *)allRecordsWithName:(NSString *)aName withSql:(NSString *)aSqlRequest{
    NSMutableArray *resultArray = nil;
    NSString *propertyName;
    id aValue;
    Class Record;
    char **results;
    int nRows;
    int nColumns;
    const char *pszSql = [aSqlRequest UTF8String];
    if(SQLITE_OK == sqlite3_get_table(database,
                                      pszSql,
                                      &results,
                                      &nRows,
                                      &nColumns,
                                      NULL))
    {
        resultArray = [NSMutableArray arrayWithCapacity:nRows++];
        Record = NSClassFromString(aName);
        for(int i=0;i<nRows-1;i++){
            id record = [Record new];
            for(int j=0;j<nColumns;j++){
                propertyName = [NSString stringWithUTF8String:results[j]];
                int index = (i+1)*nColumns + j;
                const char *pszValue = results[index];
                
                if(pszValue){
                    NSString *propertyClassName = [Record 
                                                   performSelector:@selector(propertyClassNameWithPropertyName:) 
                                                   withObject:propertyName];
                    Class propertyClass = NSClassFromString(propertyClassName);
                    NSString *sqlData = [NSString stringWithUTF8String:pszValue];
                    aValue = [propertyClass performSelector:@selector(fromSql:) 
                                                 withObject:sqlData];
                }else{
                    aValue = @"";
                }
                [record setValue:aValue forKey:propertyName];
            }
            [resultArray addObject:record];
            [record release];
        }
        sqlite3_free_table(results);
    }else
    {
        NSLog(@"%@", aSqlRequest);
        NSLog(@"Couldn't retrieve data from database: %s", sqlite3_errmsg(database));
    }
    return resultArray;
}

- (NSArray *)joinedRecordsWithSql:(NSString *)aSqlRequest {
    NSMutableArray *resultArray = nil;
    NSString *propertyName;
    NSString *header;
    id aValue;
    char **results;
    int nRows;
    int nColumns;
    const char *pszSql = [aSqlRequest UTF8String];
    if(SQLITE_OK == sqlite3_get_table(database,
                                      pszSql,
                                      &results,
                                      &nRows,
                                      &nColumns,
                                      NULL))
    {
        resultArray = [NSMutableArray arrayWithCapacity:nRows++];
        for(int i=0;i<nRows-1;i++){
            NSMutableDictionary *dictionary = [NSMutableDictionary new];
            NSString *recordName = nil;
            for(int j=0;j<nColumns;j++){
                header = [NSString stringWithUTF8String:results[j]];
                
                recordName = [[header componentsSeparatedByString:@"#"] objectAtIndex:0];
                propertyName = [[header componentsSeparatedByString:@"#"] objectAtIndex:1];
                
                Class Record = NSClassFromString(recordName);
                
                int index = (i+1)*nColumns + j;
                const char *pszValue = results[index];
                if(pszValue){
                    NSString *propertyClassName = [Record 
                                                   performSelector:@selector(propertyClassNameWithPropertyName:) 
                                                        withObject:propertyName];
                    Class propertyClass = NSClassFromString(propertyClassName);
                    NSString *sqlData = [NSString stringWithUTF8String:pszValue];
                    aValue = [propertyClass performSelector:@selector(fromSql:) 
                                                 withObject:sqlData];
                }else{
                    aValue = @"";
                }
                id currentRecord = [dictionary valueForKey:recordName];
                if(currentRecord == nil){
                    currentRecord = [Record new];
                    [dictionary setValue:currentRecord
                                  forKey:recordName];
                }
                [currentRecord setValue:aValue
                                 forKey:propertyName];
            }
            [resultArray addObject:dictionary];
            [dictionary release];
        }
        sqlite3_free_table(results);
    }else
    {
        NSLog(@"%@", aSqlRequest);
        NSLog(@"Couldn't retrieve data from database: %s", sqlite3_errmsg(database));
    }
    return resultArray;
}

//- (NSInteger)countOfRecordsWithName:(NSString *)aName {
//    NSString *aSqlRequest = [NSString stringWithFormat:
//                             @"SELECT count(id) FROM %@", 
//                             [self tableName:aName]];
//    return [self functionResult:aSqlRequest];
//}

//- (NSNumber *)getLastId:(NSString *)aRecordName {
//    NSString *aSqlRequest = [NSString stringWithFormat:@"select MAX(id) from %@", 
//                             aRecordName ];
//    NSInteger res = [self functionResult:aSqlRequest];
//    return [NSNumber numberWithInt:res];
//}

- (NSInteger)functionResult:(NSString *)anSql {
    char **results;
    NSInteger resId = 0;
    int nRows;
    int nColumns;
    const char *pszSql = [anSql UTF8String];
    if(SQLITE_OK == sqlite3_get_table(database,
                                      pszSql,
                                      &results,
                                      &nRows,
                                      &nColumns,
                                      NULL))
    {
        if(nRows == 0 || nColumns == 0){
            resId = -1;
        }else{
            resId = [[NSString stringWithUTF8String:results[1]] integerValue];
        }

        sqlite3_free_table(results);
    }else
    {
        NSLog(@"%@", anSql);
        NSLog(@"Couldn't retrieve data from database: %s", sqlite3_errmsg(database));
    }
    return resId;
}

- (void)skipBackupAttributeToFile:(NSURL *)url {
    u_int8_t b = 1;
    setxattr([[url path] fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
}

+ (void)disableMigrations {
    migrationsEnabled = NO;
}

#pragma mark - new logic

- (NSInteger)saveRecord:(ActiveRecord *)aRecord {
    ARSQLBuilder *builder = [ARSQLBuilder builderWithRecord:aRecord];
    [builder buildForCreate];
    sqlite3_stmt *statement = [self statementFromBuilder:builder];
    if(sqlite3_step(statement) != SQLITE_DONE){
        NSLog(@"Cannot execute step %s", sqlite3_errmsg(database));
        return 0;
    }
    return sqlite3_last_insert_rowid(database);
}

- (NSInteger)updateRecord:(ActiveRecord *)aRecord {
    ARSQLBuilder *builder = [ARSQLBuilder builderWithRecord:aRecord];
    [builder buildForUpdate];
    sqlite3_stmt *statement = [self statementFromBuilder:builder];
    if(sqlite3_step(statement) != SQLITE_DONE){
        NSLog(@"Cannot execute step %s", sqlite3_errmsg(database));
        return 0;
    }
    return 1;
}

- (sqlite3_stmt *)statementFromBuilder:(ARSQLBuilder *)aBuilder {
    const char *query = [aBuilder.sql UTF8String];
    sqlite3_stmt *statement = nil;
    int result = sqlite3_prepare_v2(database, query, -1, &statement, NULL);
    if(result != SQLITE_OK){
        NSLog(@"Could not prepare: %s", sqlite3_errmsg(database));
        NSLog(@"%s", query);
    }
    NSInteger index = 1;
    
    for(id value in aBuilder.values){
        Class ValueClass = [value class];
        ARDataType dataType = (ARDataType)[ValueClass performSelector:@selector(dataType)];
        NSString *bindSelector = [NSString stringWithFormat:
                                  @"bind_%s:columnData:columnIndex:", 
                                  kDataTypes[dataType]];
            objc_msgSend(self, 
                         sel_getUid([bindSelector UTF8String]),
                         statement, 
                         [value performSelector:@selector(sqlData)],
                         index++);
    }
    return statement;
}

#pragma mark - Bindings


- (BOOL)bind_blob:(sqlite3_stmt *)stmt 
       columnData:(NSData *)columnData 
      columnIndex:(NSInteger)index 
{
    int result = sqlite3_bind_blob(stmt, 
                                   index, 
                                   [columnData bytes],
                                   [columnData length], 
                                   nil);
    if(result != SQLITE_OK){
        NSLog(@"Could not bind blob: %s", sqlite3_errmsg(database));
        NSLog(@"%@", columnData);
    }
    return result == SQLITE_OK;
}

- (BOOL)bind_text:(sqlite3_stmt *)stmt 
       columnData:(NSString *)columnData 
      columnIndex:(NSInteger)index 
{
    int result = sqlite3_bind_text(stmt,
                                   index,
                                   [columnData UTF8String],
                                   -1,
                                   SQLITE_TRANSIENT);
    if(result != SQLITE_OK){
        NSLog(@"Could not bind text: %s", sqlite3_errmsg(database));
        NSLog(@"%@", columnData);
    }
    return result == SQLITE_OK;
}

- (BOOL)bind_integer:(sqlite3_stmt *)stmt 
      columnData:(NSNumber *)columnData 
     columnIndex:(NSInteger)index 
{
    int result = sqlite3_bind_int(stmt, index, columnData.intValue);
    if(result != SQLITE_OK){
        NSLog(@"Could not bind int: %s", sqlite3_errmsg(database));
        NSLog(@"%@", columnData);
    }
    return result == SQLITE_OK;
}

- (BOOL)bind_real:(sqlite3_stmt *)stmt 
         columnData:(NSDecimalNumber *)columnData 
        columnIndex:(NSInteger)index 
{
    int result = sqlite3_bind_double(stmt, index, columnData.doubleValue);
    if(result != SQLITE_OK){
        NSLog(@"Could not bind double: %s", sqlite3_errmsg(database));
        NSLog(@"%@", columnData);
    }
    return result == SQLITE_OK;
}

- (BOOL)bind_null:(sqlite3_stmt *)stmt 
       columnData:(id)alwaysNil 
      columnIndex:(NSInteger)index 
{
    int result = sqlite3_bind_null(stmt, index);
    if(result != SQLITE_OK){
        NSLog(@"Could not bind null: %s", sqlite3_errmsg(database));
    }
    
    return result == SQLITE_OK;
}

@end
