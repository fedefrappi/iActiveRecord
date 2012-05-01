//
//  NSNull+sqlRepresentation.m
//  iActiveRecord
//
//  Created by Alex Denisov on 01.05.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "NSNull+sqlRepresentation.h"

@implementation NSNull (sqlRepresentation)

- (id)sqlData {
    return nil;
}

+ (ARDataType)dataType {
    return ARDataTypeNull; 
}

@end
