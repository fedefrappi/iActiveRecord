//
//  ARColumn.m
//  iActiveRecord
//
//  Created by Alex Denisov on 29.04.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "ARColumn.h"
#import "ARColumn_Private.h"

@implementation ARColumn

@synthesize columnName;
@synthesize columnClass;

- (id)initWithProperty:(objc_property_t)property {
    self = [super init];
    if(nil != self){
        self.columnName = [NSString stringWithUTF8String:property_getName(property)];
        NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
        NSString *type = [[propertyAttributes componentsSeparatedByString:@","] objectAtIndex:0];
        NSString *propertyType = [type stringByTrimmingCharactersInSet:
                                  [NSCharacterSet characterSetWithCharactersInString:@"T@\""]];
        self.columnClass = NSClassFromString(propertyType);
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:
            @"Column: %@ %@", 
            self.columnName, 
            NSStringFromClass(self.columnClass)];
}

@end
