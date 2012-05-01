//
//  NSMutableDictionary+valueToArray.m
//  iActiveRecord
//
//  Created by Alex Denisov on 22.04.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "NSMutableDictionary+valueToArray.h"

@implementation NSMutableDictionary (valueToArray)

- (void)addValue:(id)aValue toArrayNamed:(NSString *)anArrayName {
    NSMutableArray *anArray = [self objectForKey:anArrayName];
    if (anArray == nil) {
        anArray = [NSMutableArray array];
        [self setValue:anArray
                forKey:anArrayName];
    }
    if(aValue == nil){
        aValue = [NSNull null];
    }
    [anArray addObject:aValue];
}

@end
