//
//  NSNull+sqlRepresentation.h
//  iActiveRecord
//
//  Created by Alex Denisov on 01.05.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARDataType.h"

@interface NSNull (sqlRepresentation)

- (id)sqlData;
+ (ARDataType)dataType;

@end
