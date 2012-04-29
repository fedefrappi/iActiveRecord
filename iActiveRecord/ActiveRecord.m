//
//  ActiveRecord.m
//  iActiveRecord
//
//  Created by Alex Denisov on 10.01.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "ActiveRecord.h"
#import "ARDatabaseManager.h"
#import "NSString+lowercaseFirst.h"
#import <objc/runtime.h>
#import "ARObjectProperty.h"
#import "ARValidationsHelper.h"
#import "ARValidatableProtocol.h"
#import "ARErrorHelper.h"
#import "ARMigrationsHelper.h"
#import "NSObject+properties.h"
#import "NSArray+objectsAccessors.h"
#import "NSString+quotedString.h"
#import "ARDatabaseManager.h"

#import "ARRelationBelongsTo.h"
#import "ARRelationHasMany.h"
#import "ARRelationHasManyThrough.h"

#import "ARObjectProperty.h"

#import "ARValidator.h"
#import "ARValidatorUniqueness.h"
#import "ARValidatorPresence.h"
#import "ARException.h"

#import "NSString+stringWithEscapedQuote.h"
#import "NSMutableDictionary+valueToArray.h"

#import "ActiveRecord_Private.h"

#import "ARColumn.h"
#import "ARColumn_Private.h"

static NSMutableDictionary *relationshipsDictionary = nil;
static NSMutableDictionary *columnsDictionary = nil;

@implementation ActiveRecord

migration_helper

@synthesize id;
@synthesize createdAt;
@synthesize updatedAt;

#pragma mark - Initialize

+ (void)initialize {
    [super initialize];    
    [self initIgnoredFields];
    if([self conformsToProtocol:@protocol(ARValidatableProtocol)]){
        [self performSelector:@selector(initValidations)];
    }
    [self registerRelationships];
}

#pragma mark - registering relationships

static NSMutableSet *belongsToRelations = nil;
static NSMutableSet *hasManyRelations = nil;
static NSMutableSet *hasManyThroughRelations = nil;

static NSString *registerBelongs = @"_ar_registerBelongsTo";
static NSString *registerHasMany = @"_ar_registerHasMany";
static NSString *registerHasManyThrough = @"_ar_registerHasManyThrough";

+ (void)registerRelationships {
    if(relationshipsDictionary == nil){
        relationshipsDictionary = [NSMutableDictionary new];
    }
    uint count = 0;
    Method *methods = class_copyMethodList(object_getClass(self), &count);
    for(int i=0;i<count;i++){
        NSString *selectorName = NSStringFromSelector(method_getName(methods[i]));
        if([selectorName hasPrefix:registerBelongs]){
            [self registerBelongs:selectorName];
            continue;
        }
        if([selectorName hasPrefix:registerHasManyThrough]){
            [self registerHasManyThrough:selectorName];
            continue;
        }
        if([selectorName hasPrefix:registerHasMany]){
            [self registerHasMany:selectorName];
            continue;
        }
    }
    free(methods);
}

+ (void)registerBelongs:(NSString *)aSelectorName {
    if(belongsToRelations == nil){
        belongsToRelations = [NSMutableSet new];
    }
    SEL selector = NSSelectorFromString(aSelectorName);
    NSString *relationName = [aSelectorName stringByReplacingOccurrencesOfString:registerBelongs
                                                                 withString:@""];
    ARDependency dependency = (ARDependency)[self performSelector:selector];
    ARRelationBelongsTo *relation = [[ARRelationBelongsTo alloc] initWithRecord:[self className]
                                                                       relation:relationName
                                                                      dependent:dependency];
    [relationshipsDictionary addValue:relation
                         toArrayNamed:[self tableName]];
    [relation release];
} 

+ (void)registerHasMany:(NSString *)aSelectorName {
    if(hasManyRelations == nil){
        hasManyRelations = [NSMutableSet new];
    }
    SEL selector = NSSelectorFromString(aSelectorName);
    NSString *relationName = [aSelectorName stringByReplacingOccurrencesOfString:registerHasMany
                                                                      withString:@""];
    ARDependency dependency = (ARDependency)[self performSelector:selector];
    ARRelationHasMany *relation = [[ARRelationHasMany alloc] initWithRecord:[self className]
                                                                       relation:relationName
                                                                      dependent:dependency];
    [relationshipsDictionary addValue:relation
                         toArrayNamed:[self tableName]];
    [relation release];
}

+ (void)registerHasManyThrough:(NSString *)aSelectorName {
    if(hasManyThroughRelations == nil){
        hasManyThroughRelations = [NSMutableSet new];
    }
    SEL selector = NSSelectorFromString(aSelectorName);
    NSString *records = [aSelectorName stringByReplacingOccurrencesOfString:registerHasManyThrough
                                                                 withString:@""];
    ARDependency dependency = (ARDependency)[self performSelector:selector];
    NSArray *components = [records componentsSeparatedByString:@"_ar_"];
    NSString *relationName = [components objectAtIndex:0];
    NSString *throughRelationname = [components objectAtIndex:1];
    ARRelationHasManyThrough *relation = [[ARRelationHasManyThrough alloc] initWithRecord:[self className]
                                                                            throughRecord:throughRelationname
                                                                                 relation:relationName
                                                                                dependent:dependency];
    [relationshipsDictionary addValue:relation
                         toArrayNamed:[self tableName]];
    [relation release];
}

#pragma mark - private before filter

- (void)privateAfterDestroy {
    for(ARBaseRelationship *relation in [self relationships]){
        if(relation.dependency == ARDependencyDestroy){
            switch ([relation type]) {
                case ARRelationTypeBelongsTo:
                {
                    [[self belongsTo:relation.relation] dropRecord];
                }break;
                case ARRelationTypeHasManyThrough:
                {
                    [[[self hasMany:relation.relation
                            through:relation.throughRecord] 
                      fetchRecords] 
                     makeObjectsPerformSelector:@selector(dropRecord)];
                }break;
                case ARRelationTypeHasMany:
                {
                    [[[self hasManyRecords:relation.relation] 
                      fetchRecords] 
                     makeObjectsPerformSelector:@selector(dropRecord)];
                }break;
                default:
                    break;
            }
        }
    }
}

#pragma mark - IgnoreFields

- (id)init {
    self = [super init];
    if(nil != self){
        self.updatedAt = [NSDate dateWithTimeIntervalSinceNow:0];
        self.createdAt = [NSDate dateWithTimeIntervalSinceNow:0];
    }
    return self;    
}

- (void)dealloc {
    self.id = nil;
    [errors release];
    [changedFields release];
    [super dealloc];
}

- (void)markAsNew {
    isNew = YES;
}

#pragma mark - ObserveChanges

- (void)didChangeField:(NSString *)aField {
    if([ignoredFields containsObject:aField]){
        return;
    }
    if(nil == changedFields){
        changedFields = [NSMutableSet new];
    }
    [changedFields addObject:aField];
    
    if(updatedColumns == nil){
        updatedColumns = [NSMutableSet new];
    }
    ARColumn *column = [self columnNamed:aField];
    [updatedColumns addObject:column];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    NSLog(@"%@ %@", value, key);
    if([[self valueForKey:key] isEqual:value]){
        return;
    }
    [self didChangeField:key];
    [super setValue:value forKey:key];
}

+ (void)initIgnoredFields {
}

+ (void)ignoreField:(NSString *)aField {
    if(nil == ignoredFields){
        ignoredFields = [[NSMutableSet alloc] init];
    }
    [ignoredFields addObject:aField];
}

#pragma mark - 

- (void)resetErrors {
    [errors release];
    errors = nil;
}

- (void)addError:(ARError *)anError {
    if(nil == errors){
        errors = [NSMutableSet new];
    }
    [errors addObject:anError];
}

- (void)initialize {
    
}

#pragma mark - SQLQueries

+ (const char *)sqlOnAddColumn:(NSString *)aColumn {
    NSMutableString *sqlString = [NSMutableString stringWithFormat:
                                  @"ALTER TABLE %@ ADD COLUMN ", 
                                  [[self tableName] quotedString]];
    NSString *propertyClassName = [self propertyClassNameWithPropertyName:aColumn];
    Class PropertyClass = NSClassFromString(propertyClassName);
    [sqlString appendFormat:
     @"%@ %s", 
     [aColumn quotedString],
     [PropertyClass performSelector:@selector(sqlType)]];
    return [sqlString UTF8String];
}

+ (const char *)sqlOnCreate {
    [self initIgnoredFields];
    NSMutableString *sqlString = [NSMutableString stringWithFormat:
                                  @"create table %@(id integer primary key unique ", 
                                  [[self tableName] quotedString]];
    NSArray *properties = [self activeRecordProperties];
    if([properties count] == 0){
        return NULL;
    }
    Class propertyClass = nil;
    for(ARObjectProperty *property in [self tableFields]){
        if(![property.propertyName isEqualToString:@"id"]){
            propertyClass = NSClassFromString(property.propertyType);
            [sqlString appendFormat:@", %@ %s", 
             [property.propertyName quotedString], 
            [propertyClass performSelector:@selector(sqlType)]];
        }
    }
    [sqlString appendFormat:@")"];
    return [sqlString UTF8String];
}

- (const char *)sqlOnDelete {
    NSString *sqlString = [NSString stringWithFormat:
                           @"delete from %@ where id = %@", 
                           [[self tableName] quotedString], 
                           self.id];
    return [sqlString UTF8String];
}

- (const char *)sqlOnSave {
    NSArray *properties = [[self class] tableFields];
    if([properties count] == 0){
        return NULL;
    }
    
    ARObjectProperty *property = nil;
    NSMutableArray *existedProperties = [NSMutableArray new];
    for(property in properties){
        id value = [self valueForKey:property.propertyName];
        if(nil != value){
            [existedProperties addObject:property];
        }
    }
    if([existedProperties count] == 0){
        [existedProperties release];
        return NULL;
    }
    
    NSMutableString *sqlString = [NSMutableString stringWithFormat:@"INSERT INTO %@(", 
                                  [[self tableName] quotedString]];
    NSMutableString *sqlValues = [NSMutableString stringWithFormat:@" VALUES("];
    
    int index = 0;
    property = [existedProperties objectAtIndex:index++];
    id propertyValue = [self valueForKey:property.propertyName];
    if(propertyValue == nil){
        propertyValue = @"";
    }
    [sqlString appendFormat:@"%@", [property.propertyName quotedString]];
    [sqlValues appendFormat:@"%@", [[[propertyValue performSelector:@selector(toSql)] 
                                     stringWithEscapedQuote] 
                                    quotedString]];
    
    for(;index < [existedProperties count];index++){
        property = [existedProperties objectAtIndex:index];
        id propertyValue = [self valueForKey:property.propertyName];
        if(propertyValue == nil){
            propertyValue = @"";
        }
        [sqlString appendFormat:@", %@", [property.propertyName quotedString]];
        [sqlValues appendFormat:@", %@", [[[propertyValue performSelector:@selector(toSql)] 
                                           stringWithEscapedQuote] 
                                          quotedString]];
    }
    [existedProperties release];
    [sqlValues appendString:@") "];
    [sqlString appendString:@") "];
    [sqlString appendString:sqlValues];
    return [sqlString UTF8String];
}

- (const char *)sqlOnUpdate {
    NSMutableString *sqlString = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", 
                                  [[self tableName] quotedString]];
    NSArray *updatedValues = [changedFields allObjects];
    NSInteger index = 0;
    NSString *propertyName = [updatedValues objectAtIndex:index++];
    id propertyValue = [self valueForKey:propertyName];
    [sqlString appendFormat:@"%@=%@", [propertyName quotedString], 
     [[[propertyValue performSelector:@selector(toSql)] 
       stringWithEscapedQuote] 
      quotedString]];
   
    for(;index<[updatedValues count];index++){
        propertyName = [updatedValues objectAtIndex:index++];
        propertyValue = [self valueForKey:propertyName];
        [sqlString appendFormat:@", %@=%@", [propertyName quotedString], 
         [[[propertyValue performSelector:@selector(toSql)] 
           stringWithEscapedQuote] 
          quotedString]];
    }
    [sqlString appendFormat:@" WHERE id = %@", self.id];
    return [sqlString UTF8String];
}

+ (const char *)sqlOnDeleteAll {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", [[self tableName] quotedString]];
    return [sql UTF8String];
}

#pragma mark - 

+ (NSArray *)relationships {
    return [relationshipsDictionary objectForKey:[self tableName]];
}

- (NSArray *)relationships {
    return [[self class] relationships];
}

+ (NSString *)tableName {
    return [self className];
}

- (NSString *)tableName {
    return [[self class] tableName];
}

+ (NSString *)className {
    return [self description];
}
- (NSString *)className {
    return [[self class] className];
}

+ (id)newRecord {
    Class RecordClass = [self class];
    ActiveRecord *record = [[RecordClass alloc] init];
    [record markAsNew];
    return record;
}

#pragma mark - Fetchers

+ (NSArray *)allRecords {
    ARLazyFetcher *fetcher = [[[ARLazyFetcher alloc] initWithRecord:[self class]] autorelease];
    return [fetcher fetchRecords];
}

+ (ARLazyFetcher *)lazyFetcher {
    ARLazyFetcher *fetcher = [[ARLazyFetcher alloc] initWithRecord:[self class]];
    return [fetcher autorelease];
}

#pragma mark - Equal

- (BOOL)isEqualToRecord:(ActiveRecord *)anOtherRecord {
    if(nil == anOtherRecord){
        return NO;
    }
    NSArray *properties = [[self class] activeRecordProperties];
    for(ARObjectProperty *property in properties){
        id lValue = [self valueForKey:property.propertyName];
        id rValue = [anOtherRecord valueForKey:property.propertyName];
        if( ![lValue isEqual:rValue] ){
            return NO;
        }
    }
    return YES;
}


#pragma mark - Validations

+ (void)validateUniquenessOfField:(NSString *)aField {
    [ARValidator registerValidator:[ARValidatorUniqueness class]
                         forRecord:[self className]
                           onField:aField];
}

+ (void)validatePresenceOfField:(NSString *)aField {
    [ARValidator registerValidator:[ARValidatorPresence class]
                         forRecord:[self className]
                           onField:aField];
}

+ (void)validateField:(NSString *)aField withValidator:(NSString *)aValidator {
    [ARValidator registerValidator:NSClassFromString(aValidator)
                         forRecord:[self className]
                           onField:aField];
}

- (BOOL)isValid {
    BOOL valid = YES;
    [self resetErrors];
    if(isNew){
        valid = [ARValidator isValidOnSave:self];             
    }else{
        valid = [ARValidator isValidOnUpdate:self];
    }
    return valid;
}

- (NSArray *)errors {
    return [errors allObjects];
}

- (NSArray *)changedFields {
    return [changedFields allObjects];
}

#pragma mark - Save/Update

- (BOOL)save {
    if(!isNew){
        return [self update];
    }
    if(![self isValid]){
        return NO;
    }
    self.updatedAt = [NSDate dateWithTimeIntervalSinceNow:0];
    
    return [[ARDatabaseManager sharedInstance] saveRecord:self];
    /*
    const char *sql = [self sqlOnSave];
    if(NULL != sql){
        NSNumber *tmpId = [[ARDatabaseManager sharedInstance] 
                          insertRecord:[[self class] tableName] 
                           withSqlQuery:sql];
        self.id = self.id == nil ? tmpId : self.id;
        isNew = NO;
        return YES;
    }
    return NO;
     */
}

- (BOOL)update {
    if(![self isValid]){
        return NO;
    }
    if(![changedFields count]){
        return YES;
    }
    self.updatedAt = [NSDate dateWithTimeIntervalSinceNow:0];
    const char *sql = [self sqlOnUpdate];
    if(NULL != sql){
        [[ARDatabaseManager sharedInstance] executeSqlQuery:sql];
        isNew = NO;
        [changedFields removeAllObjects];
        return YES;
    }
    return NO;
}

+ (NSInteger)count {
    return [[ARDatabaseManager sharedInstance] countOfRecordsWithName:[[self class] description]];
}

#pragma mark - Relationships

#pragma mark BelongsTo

- (id)belongsTo:(NSString *)aClassName {
    NSString *selectorString = [NSString stringWithFormat:@"%@Id", [aClassName lowercaseFirst]];
    SEL selector = NSSelectorFromString(selectorString);
    NSNumber *rec_id = [self performSelector:selector];
    ARLazyFetcher *fetcher = [[[ARLazyFetcher alloc] initWithRecord:NSClassFromString(aClassName)] autorelease];
    [fetcher whereField:@"id"
           equalToValue:rec_id];
    return [[fetcher fetchRecords] first];
}

- (void)setRecord:(ActiveRecord *)aRecord 
        belongsTo:(NSString *)aRelation
{
    NSString *relId = [NSString stringWithFormat:
                       @"%@Id", 
                       [aRelation lowercaseFirst]];
    [self setValue:aRecord.id forKey:relId];
    [self update];
}

#pragma mark HasMany

- (void)addRecord:(ActiveRecord *)aRecord {
    NSString *relationIdKey = [NSString stringWithFormat:@"%@Id", [[self className] lowercaseFirst]];
    [aRecord setValue:self.id forKey:relationIdKey];
    [aRecord save];
}

- (void)removeRecord:(ActiveRecord *)aRecord {
    NSString *relationIdKey = [NSString stringWithFormat:@"%@Id", [[self className] lowercaseFirst]];
    [aRecord setValue:nil forKey:relationIdKey];
    [aRecord save];
}

- (ARLazyFetcher *)hasManyRecords:(NSString *)aClassName {
    ARLazyFetcher *fetcher = [[ARLazyFetcher alloc] initWithRecord:NSClassFromString(aClassName)];
    NSString *selfId = [NSString stringWithFormat:@"%@Id", [[self class] description]];
    [fetcher whereField:selfId equalToValue:self.id];
    return [fetcher autorelease];
}

#pragma mark HasManyThrough

- (ARLazyFetcher *)hasMany:(NSString *)aClassName through:(NSString *)aRelationsipClassName {
    
    NSString *relId = [NSString stringWithFormat:@"%@Id", [[self className] lowercaseFirst]];
    ARLazyFetcher *fetcher = [[ARLazyFetcher alloc] initWithRecord:NSClassFromString(aClassName)];
    [fetcher join:NSClassFromString(aRelationsipClassName)];
    [fetcher whereField:relId
               ofRecord:NSClassFromString(aRelationsipClassName)
           equalToValue:self.id];
    return [fetcher autorelease];
}

- (void)addRecord:(ActiveRecord *)aRecord 
          ofClass:(NSString *)aClassname 
          through:(NSString *)aRelationshipClassName 
{
    Class RelationshipClass = NSClassFromString(aRelationshipClassName);
    
    NSString *currentIdSelectorString = [NSString stringWithFormat:@"set%@Id:", [[self class] description]];
    NSString *relativeIdSlectorString = [NSString stringWithFormat:@"set%@Id:", aClassname];
    
    SEL currentIdSelector = NSSelectorFromString(currentIdSelectorString);
    SEL relativeIdSelector = NSSelectorFromString(relativeIdSlectorString);
    
    NSNumber *relativeRecordId = aRecord.id;
    ActiveRecord *relationshipRecord = [RelationshipClass newRecord];
    [relationshipRecord performSelector:currentIdSelector withObject:self.id];
    [relationshipRecord performSelector:relativeIdSelector withObject:relativeRecordId];
    [relationshipRecord save];
    [relationshipRecord release];
}

- (void)removeRecord:(ActiveRecord *)aRecord through:(NSString *)aClassName
{
    NSString *selfId = [NSString stringWithFormat:@"%@Id", [[self className] lowercaseFirst]];
    NSString *relId = [NSString stringWithFormat:@"%@Id", [[aRecord className] lowercaseFirst]];
    ARLazyFetcher *fetcher = [[ARLazyFetcher alloc] initWithRecord:NSClassFromString(aClassName)];
    [fetcher whereField:selfId equalToValue:self.id];
    [fetcher whereField:relId equalToValue:aRecord.id];
    ActiveRecord *record = [[fetcher fetchRecords] first];
    [record dropRecord];
    [fetcher release];
}

#pragma mark - Description

- (NSString *)description {
    NSMutableString *descr = [NSMutableString stringWithFormat:@"%@\n", [[self class] description]];
    NSArray *properties = [[self class] activeRecordProperties];
    for(ARObjectProperty *property in properties){
        [descr appendFormat:@"%@ => %@\n", 
        property.propertyName, 
        [self valueForKey:property.propertyName]];
    }
    return descr;
}

#pragma mark - Drop records

+ (void)dropAllRecords {
    [[self allRecords] makeObjectsPerformSelector:@selector(dropRecord)];
}
 
- (void)dropRecord {
    [[ARDatabaseManager sharedInstance] executeSqlQuery:[self sqlOnDelete]];
    [self privateAfterDestroy];
}

#pragma mark - TableFields

+ (NSArray *)tableFields {
    NSArray *properties = [self activeRecordProperties];
    NSMutableArray *tableFields = [NSMutableArray arrayWithCapacity:[properties count]];
    for(ARObjectProperty *property in properties){
        if(![ignoredFields containsObject:property.propertyName]){
            [tableFields addObject:property];
        }
    }
    return tableFields;
}

#pragma mark - Storage

+ (void)registerDatabaseName:(NSString *)aDbName useDirectory:(ARStorageDirectory)aDirectory {
    BOOL isCache = YES;
    if(aDirectory == ARStorageDocuments){
        isCache = NO;
    }
    [ARDatabaseManager registerDatabase:aDbName  cachesDirectory:isCache];
}

#pragma mark - Clear database

+ (void)clearDatabase {
    [[ARDatabaseManager sharedInstance] clearDatabase];
}

+ (void)disableMigrations {
    [ARDatabaseManager disableMigrations];
}

#pragma mark - Transactions

+ (void)transaction:(ARTransactionBlock)aTransactionBlock {
    @synchronized(self){
        [[ARDatabaseManager sharedInstance] executeSqlQuery:"BEGIN"];
        @try {
            aTransactionBlock();
            [[ARDatabaseManager sharedInstance] executeSqlQuery:"COMMIT"];
        }
        @catch (ARException *exception) {
            [[ARDatabaseManager sharedInstance] executeSqlQuery:"ROLLBACK"];
        }
    }
}

+ (void)registerColumns {
    if(columnsDictionary == nil){
        columnsDictionary = [NSMutableDictionary new];
    }
    Class ActiveRecordClass = NSClassFromString(@"NSObject");
    id CurrentClass = self;
    while(nil != CurrentClass && CurrentClass != ActiveRecordClass){
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(CurrentClass, &outCount);
        for (i = 0; i < outCount; i++) {
            ARColumn *column = [[ARColumn alloc] initWithProperty:properties[i]];
            [columnsDictionary addValue:column
                           toArrayNamed:[self tableName]];
            [column release];
        }
        CurrentClass = class_getSuperclass(CurrentClass);
    }    
}

+ (NSArray *)columns {
    if (columnsDictionary == nil) {
        [self registerColumns];
    }
    return [columnsDictionary objectForKey:[self tableName]];
}

- (NSArray *)columns {
    return [self columns];
}

- (NSArray *)updatedColumns {
    return [updatedColumns allObjects];
}

- (ARColumn *)columnNamed:(NSString *)aColumnName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"columnName = %@", aColumnName];
    return [[[self columns] filteredArrayUsingPredicate:predicate] first];
}

@end
