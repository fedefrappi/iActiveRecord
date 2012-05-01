//
//  ARValidation.m
//  iActiveRecord
//
//  Created by Alex Denisov on 31.03.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "ARValidation.h"

@implementation ARValidation

@synthesize record;
@synthesize validator;
@synthesize column;

- (id)initWithRecord:(NSString *)aRecord column:(ARColumn *)aColumn validator:(Class)aValidator {
    self = [super init];
    if(self != nil){
        self.record = aRecord;
        self.column = aColumn;
        self.validator = aValidator;
    }
    return self;
    
}

- (void)dealloc {
    self.record = nil;
    self.validator = nil;
    [super dealloc];
}

- (BOOL)isEqual:(id)object {
    ARValidation *otherObject = (ARValidation *)object;
    if(![self.record isEqualToString:otherObject.record]){
        return NO;
    }
    if(![self.validator isEqual:otherObject.validator]){
        return NO;
    }
    return YES;
}

@end
