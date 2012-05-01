//
//  NSDecimalNumber+sqlRepresentation.h
//  iActiveRecord
//
//  Created by Alex Denisov on 18.01.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARDataType.h"

@interface NSDecimalNumber (sqlRepresentation)

+ (const char *)sqlType;
- (id)toSql;
+ (id)fromSql:(id)sqlData;

- (id)sqlData;
+ (ARDataType)dataType;

@end
