//
//  ARWhereStatement.m
//  iActiveRecord
//
//  Created by Alex Denisov on 23.03.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "ARWhereStatement.h"
#import "ARWhereStatement_Private.h"

@implementation ARWhereStatement

@synthesize field;
@synthesize values;

#pragma mark - private

+ (ARWhereStatement *)statement:(NSString *)aStmt {
    return [[[ARWhereStatement alloc] initWithStatement:aStmt] autorelease];
}

+ (ARWhereStatement *)statementForField:(NSString *)aField 
                              fromArray:(NSArray *)aValues 
                          withOperation:(NSString *)anOperation
{
    NSMutableArray *sqlValues = [NSMutableArray arrayWithCapacity:aValues.count];
    for(id value in aValues){
        [sqlValues addObject:@"?"];
    }
    NSString *values = [sqlValues componentsJoinedByString:@" , "];
    NSString *stmt = [NSString stringWithFormat:@" %@ %@ (%@)", 
                      aField, 
                      anOperation,
                      values];
    ARWhereStatement *statement = [ARWhereStatement statement:stmt];
    [statement.values addObjectsFromArray:aValues];
    return statement;
}

#pragma mark - public

- (id)initWithStatement:(NSString *)aStatement {
    self = [super init];
    if(nil != self){
        statement = [aStatement copy];
        self.values = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    [statement release];
    [super dealloc];
}

+ (ARWhereStatement *)whereField:(NSString *)aField equalToValue:(id)aValue {
    NSString *stmt = [NSString stringWithFormat:
                      @" '%@' = ? ",
                      aField];
    ARWhereStatement *statement = [ARWhereStatement statement:stmt];
    [statement.values addObject:aValue];
    return statement;
}

+ (ARWhereStatement *)whereField:(NSString *)aField 
                        ofRecord:(Class)aRecord 
                            like:(NSString *)aPattern 
{
    NSString *stmt = [NSString stringWithFormat:
                      @" '%@'.'%@' LIKE ? ",
                      [aRecord performSelector:@selector(recordName)],
                      aField];
    ARWhereStatement *statement = [ARWhereStatement statement:stmt];
    [statement.values addObject:aPattern];
    return statement;
}

+ (ARWhereStatement *)whereField:(NSString *)aField 
                        ofRecord:(Class)aRecord 
                         notLike:(NSString *)aPattern
{
    NSString *stmt = [NSString stringWithFormat:
                      @" '%@'.'%@' NOT LIKE ? ",
                      [aRecord performSelector:@selector(recordName)],
                      aField];
    ARWhereStatement *statement = [ARWhereStatement statement:stmt];
    [statement.values addObject:aPattern];
    return statement;
}

+ (ARWhereStatement *)whereField:(NSString *)aField notEqualToValue:(id)aValue {
    NSString *stmt = [NSString stringWithFormat:
                      @" '%@' <> ? ",
                      aField];
    ARWhereStatement *statement = [ARWhereStatement statement:stmt];
    [statement.values addObject:aValue];
    return statement;
}

+ (ARWhereStatement *)whereField:(NSString *)aField in:(NSArray *)aValues {
    return [self statementForField:aField
                         fromArray:aValues
                     withOperation:@"IN"];
}

+ (ARWhereStatement *)whereField:(NSString *)aField notIn:(NSArray *)aValues {
    return [self statementForField:aField
                         fromArray:aValues
                     withOperation:@"NOT IN"];
}

+ (ARWhereStatement *)whereField:(NSString *)aField ofRecord:(Class)aRecord equalToValue:(id)aValue 
{
    NSString *stmt = [NSString stringWithFormat:
                      @" '%@'.'%@' = ? ",
                      [aRecord performSelector:@selector(recordName)],
                      aField];
    ARWhereStatement *statement = [ARWhereStatement statement:stmt];
    [statement.values addObject:aValue];
    return statement;
}

+ (ARWhereStatement *)whereField:(NSString *)aField ofRecord:(Class)aRecord notEqualToValue:(id)aValue 
{
    NSString *stmt = [NSString stringWithFormat:
                      @" '%@'.'%@' <> ? ",
                      [aRecord performSelector:@selector(recordName)],
                      aField];
    ARWhereStatement *statement = [ARWhereStatement statement:stmt];
    [statement.values addObject:aValue];
    return statement;
}

+ (ARWhereStatement *)whereField:(NSString *)aField ofRecord:(Class)aRecord in:(NSArray *)aValues
{
    NSString *field = [NSString stringWithFormat:
                       @"'%@'.'%@'", 
                       [aRecord performSelector:@selector(recordName)],
                       aField];
    return [self statementForField:field
                         fromArray:aValues
                     withOperation:@"IN"];
}

+ (ARWhereStatement *)whereField:(NSString *)aField ofRecord:(Class)aRecord notIn:(NSArray *)aValues
{
    NSString *field = [NSString stringWithFormat:
                       @"'%@'.'%@'", 
                       [aRecord performSelector:@selector(recordName)],
                       aField];
    return [self statementForField:field
                         fromArray:aValues
                     withOperation:@"NOT IN"];
}

+ (ARWhereStatement *)concatenateStatement:(ARWhereStatement *)aFirstStatement 
                                   withStatement:(ARWhereStatement *)aSecondStatement
                             useLogicalOperation:(ARLogicalOperation)logicalOperation
{
    NSString *logic = logicalOperation == ARLogicalOr ? @"OR" : @"AND";
    NSString *stmt = [NSString stringWithFormat:
                      @" (%@) %@ (%@) ", 
                      [aFirstStatement statement],
                      logic,
                      [aSecondStatement statement]];
    ARWhereStatement *statement = [ARWhereStatement statement:stmt];
    [statement.values addObjectsFromArray:aFirstStatement.values];
    [statement.values addObjectsFromArray:aSecondStatement.values];
    return statement;
}

- (NSString *)statement {
    return statement;
}

@end

