//
//  NSData+sqlRepresentation.m
//  iActiveRecord
//
//  Created by Alex Denisov on 25.03.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "NSData+sqlRepresentation.h"

#import "NSData+Base64.h"

@implementation NSData (sqlRepresentation)

- (id)toSql {
    return self;
}

+ (id)fromSql:(id)sqlData {
    return sqlData;
}

+ (const char *)sqlType {
    return "blob";
}


- (id)sqlData {
    return self;
}

+ (ARDataType)dataType {
    return ARDataTypeBlob;
}

@end
