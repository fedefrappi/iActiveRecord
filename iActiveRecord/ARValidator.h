//
//  ARValidation.h
//  iActiveRecord
//
//  Created by Alex Denisov on 30.03.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARValidatorProtocol.h"

@class ARColumn;

@interface ARValidator : NSObject

+ (BOOL)isValidOnSave:(id)aRecord;
+ (BOOL)isValidOnUpdate:(id)aRecord;
+ (void)registerValidator:(Class)aValidator 
                forRecord:(NSString *)aRecord 
                 onColumn:(ARColumn *)aColumn;

@end
