//
//  ARValidation.m
//  iActiveRecord
//
//  Created by Alex Denisov on 30.03.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "ARValidator.h"
#import "ARValidation.h"
#import "ActiveRecord.h"
#import "ARColumn.h"

@interface ARValidator ()
{
    NSMutableSet *validations;
}

+ (id)sharedInstance;

- (BOOL)isValidOnSave:(id)aRecord;
- (BOOL)isValidOnUpdate:(id)aRecord;
- (void)registerValidator:(Class)aValidator 
                forRecord:(NSString *)aRecord 
                 onColumn:(ARColumn *)aColumn;

@end

@implementation ARValidator

- (id)init {
    self = [super init];
    if(self){
        validations = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    [validations release];
    [super dealloc];
}

+ (id)sharedInstance {
    @synchronized(self){
        if(_instance == nil){
            _instance = [[ARValidator alloc] init];
        }
        return _instance;
    }
}

- (void)registerValidator:(Class)aValidator 
                forRecord:(NSString *)aRecord 
                 onColumn:(ARColumn *)aColumn
{
    ARValidation *validation = [[ARValidation alloc] initWithRecord:aRecord
                                                             column:aColumn
                                                          validator:aValidator];
    [validations addObject:validation];
    [validation release];
}

#warning refactor!!!

- (BOOL)isValidOnSave:(id)aRecord {
    BOOL valid = YES;
    NSString *className = [aRecord performSelector:@selector(recordName)];
    for(int i=0;i<validations.count;i++){
        ARValidation *validation = [[validations allObjects] objectAtIndex:i];
        if([validation.record isEqualToString:className]){
            id<ARValidatorProtocol> validator = [[validation.validator alloc] init];
            BOOL result = [validator validateField:validation.column.columnName
                                          ofRecord:aRecord];
            
            if(!result){
                NSString *errMsg = @"";
                if([validator respondsToSelector:@selector(errorMessage)]){
                    errMsg = [validator errorMessage];
                }
                ARError *error = [[ARError alloc] initWithModel:validation.record
                                                       property:validation.column.columnName
                                                          error:errMsg];
                [aRecord performSelector:@selector(addError:) 
                              withObject:error];
                [error release];
                valid  = NO;
            }
            [validator release];
        }
    }
    return valid;
}

- (BOOL)isValidOnUpdate:(id)aRecord {
    BOOL valid = YES;
    NSString *className = [aRecord performSelector:@selector(recordName)];
    for(ARValidation *validation in validations){
        if([validation.record isEqualToString:className]){
            if([[aRecord updatedFields] containsObject:validation.column]){
                id<ARValidatorProtocol> validator = [[validation.validator alloc] init];
                BOOL result = [validator validateField:validation.column.columnName
                                              ofRecord:aRecord];
                
                if(!result){
                    NSString *errMsg = @"";
                    if([validator respondsToSelector:@selector(errorMessage)]){
                        errMsg = [validator errorMessage];
                    }
                    ARError *error = [[ARError alloc] initWithModel:validation.record
                                                           property:validation.column.columnName
                                                              error:errMsg];
                    [aRecord performSelector:@selector(addError:) 
                                  withObject:error];
                    [error release];
                    valid  = NO;
                }
                [validator release];
            }
        }
    }
    return valid;
}

#pragma mark - Public

+ (BOOL)isValidOnSave:(id)aRecord {
    if(![aRecord conformsToProtocol:@protocol(ARValidatableProtocol)]){
        return YES;
    }
    return [[self sharedInstance] isValidOnSave:aRecord];
}

+ (BOOL)isValidOnUpdate:(id)aRecord {
    if(![aRecord conformsToProtocol:@protocol(ARValidatableProtocol)]){
        return YES;
    }
    return [[self sharedInstance] isValidOnUpdate:aRecord];
}

static ARValidator *_instance = nil;

+ (void)registerValidator:(Class)aValidator 
                forRecord:(NSString *)aRecord 
                 onColumn:(ARColumn *)aColumn
{
    [[self sharedInstance] registerValidator:aValidator
                                   forRecord:aRecord
                                    onColumn:aColumn];
}

@end
