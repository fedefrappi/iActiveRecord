//
//  NSString+sqlRepresentation.m
//  iActiveRecord
//
//  Created by Alex Denisov on 17.01.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "NSString+sqlRepresentation.h"

@implementation NSString (sqlRepresentation)

+ (id)fromSql:(id)sqlData{
    return sqlData;
}

- (id)toSql {
    return self;
}

+ (const char *)sqlType {
    return "text";
}

+ (ARDataType)dataType {
    return ARDataTypeString;
}

@end
