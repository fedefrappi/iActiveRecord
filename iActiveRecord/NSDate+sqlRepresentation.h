//
//  NSDate+sqlRepresentation.h
//  iActiveRecord
//
//  Created by Alex Denisov on 29.03.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARDataType.h"

@interface NSDate (sqlRepresentation)

- (id)toSql;
+ (id)fromSql:(id)sqlData;
+ (const char *)sqlType;

- (id)sqlData;
+ (ARDataType)dataType;

@end
