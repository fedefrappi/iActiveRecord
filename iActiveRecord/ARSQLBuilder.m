//
//  ARSQLBuilder.m
//  iActiveRecord
//
//  Created by Alex Denisov on 01.05.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "ARSQLBuilder.h"
#import "ActiveRecord.h"
#import "ActiveRecord_Private.h"
#import "ARLazyFetcher.h"
#import "ARColumn.h"

@interface ARSQLBuilder ()
{
    BOOL isBuilded;
}
@property (nonatomic, retain) ActiveRecord *record;
@property (nonatomic, retain) ARLazyFetcher *fetcher;

@property (nonatomic, retain) NSMutableString *sqlString;
@property (nonatomic, retain) NSMutableArray *valuesArray;

@end

@implementation ARSQLBuilder

@synthesize record;
@synthesize fetcher;
@synthesize sqlString;
@synthesize valuesArray;

- (id)init {
    self = [super init];
    isBuilded = NO;
    self.valuesArray = [NSMutableArray array];
    return self;
}

+ (ARSQLBuilder *)builderWithRecord:(ActiveRecord *)aRecord {
    ARSQLBuilder *builder = [ARSQLBuilder new];
    builder.record = aRecord;
    return [builder autorelease];
}

+ (ARSQLBuilder *)builderWithFetcher:(ARLazyFetcher *)aFetcher {
    ARSQLBuilder *builder = [ARSQLBuilder new];
    builder.fetcher = aFetcher;
    return [builder autorelease];
}

- (void)buildForCreate {
    isBuilded = YES;
    if(self.record == nil){
        [NSException raise:@"You must specify record with builder"
                    format:@""];
    }
    NSArray *updatedColumns = [[self.record updatedColumns] copy];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:updatedColumns.count];
    NSMutableArray *columns = [NSMutableArray arrayWithCapacity:updatedColumns.count];
    
    for(ARColumn *column in updatedColumns){
        [values addObject:@"?"];
        [columns addObject:[NSString stringWithFormat:
                            @"'%@'", 
                            column.columnName]];
        [self.valuesArray addObject:[self.record 
                                     valueForKey:column.columnName]];
    }
    [updatedColumns release];
    
    self.sqlString = [NSMutableString 
                      stringWithFormat:@"INSERT INTO %@(%@) VALUES(%@)", 
                      self.record.recordName,
                      [columns componentsJoinedByString:@","],
                      [values componentsJoinedByString:@","]];
}



- (NSString *)sql {
    return self.sqlString;
}

- (NSArray *)values {
    return self.valuesArray;
}

@end
