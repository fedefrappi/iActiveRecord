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

@synthesize propertyName;
@synthesize propertyClass;

- (id)initWithProperty:(objc_property_t)property {
    self = [super init];
    if(nil != self){
        self.propertyName = [NSString stringWithUTF8String:property_getName(property)];
        NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
        NSString *type = [[propertyAttributes componentsSeparatedByString:@","] objectAtIndex:0];
        NSString *propertyType = [type stringByTrimmingCharactersInSet:
                                  [NSCharacterSet characterSetWithCharactersInString:@"T@\""]];
        self.propertyClass = NSClassFromString(propertyType);
    }
    return self;
}

@end
