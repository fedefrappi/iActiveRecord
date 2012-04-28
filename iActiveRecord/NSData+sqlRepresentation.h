//
//  NSData+sqlRepresentation.h
//  iActiveRecord
//
//  Created by Alex Denisov on 25.03.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARDataType.h"

@interface NSData (sqlRepresentation)

- (id)toSql;
+ (id)fromSql:(id)sqlData;
+ (const char *)sqlType;
+ (ARDataType)dataType;

@end
