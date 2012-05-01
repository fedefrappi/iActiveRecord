//
//  NSString+sqlRepresentation.h
//  iActiveRecord
//
//  Created by Alex Denisov on 17.01.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARDataType.h"

@interface NSString (sqlRepresentation)

+ (const char *)sqlType;

+ (id)fromSql:(id)sqlData;
- (id)toSql;

- (id)sqlData;
+ (ARDataType)dataType;

@end
