//
//  NSMutableDictionary+addValueToSet.h
//  iActiveRecord
//
//  Created by Alex Denisov on 01.05.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (addValueToSet)

- (void)addValue:(id)aValue toSetNamed:(NSString *)anArrayName;

@end
