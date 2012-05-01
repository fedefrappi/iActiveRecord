//
//  NSDecimalNumber+sqlRepresentation.m
//  iActiveRecord
//
//  Created by Alex Denisov on 18.01.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "NSDecimalNumber+sqlRepresentation.h"

@implementation NSDecimalNumber (sqlRepresentation)

- (id)toSql {
    return self;
}

+ (const char *)sqlType {
    return "real";
}

+ (id)fromSql:(id)sqlData {
    return sqlData;
}

- (id)sqlData {
    return self;
}

+ (ARDataType)dataType {
    return ARDataTypeFloat;
}

@end
