//
//  NSNumber+sqlRepresentation.m
//  iActiveRecord
//
//  Created by Alex Denisov on 17.01.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "NSNumber+sqlRepresentation.h"

@implementation NSNumber (sqlRepresentation)

- (id)toSql {
    return self;
}

+ (const char *)sqlType {
    return "integer";
}

+ (id)fromSql:(id)sqlData{
    return sqlData;
}

- (id)sqlData {
    return self;
}

+ (ARDataType)dataType {
    return ARDataTypeInteger;
}

@end
