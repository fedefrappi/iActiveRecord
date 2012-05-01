//
//  NSMutableDictionary+addValueToSet.m
//  iActiveRecord
//
//  Created by Alex Denisov on 01.05.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "NSMutableDictionary+addValueToSet.h"

@implementation NSMutableDictionary (addValueToSet)

- (void)addValue:(id)aValue toSetNamed:(NSString *)anArrayName {
    if (aValue == nil) {
        return;
    }
    
    NSMutableSet *anArray = [self objectForKey:anArrayName];
    if (anArray == nil) {
        anArray = [NSMutableSet set];
        [self setValue:anArray
                forKey:anArrayName];
    }
    if(aValue == nil){
        aValue = [NSNull null];
    }
    [anArray addObject:aValue];
}

@end
