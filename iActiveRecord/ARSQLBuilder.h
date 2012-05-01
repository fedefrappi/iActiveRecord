//
//  ARSQLBuilder.h
//  iActiveRecord
//
//  Created by Alex Denisov on 01.05.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ActiveRecord;
@class ARLazyFetcher;

@interface ARSQLBuilder : NSObject

+ (ARSQLBuilder *)builderWithRecord:(ActiveRecord *)aRecord;
+ (ARSQLBuilder *)builderWithFetcher:(ARLazyFetcher *)aFetcher;

- (void)buildForCreate;
- (void)buildForUpdate;

- (NSString *)sql;
- (NSArray *)values;

@end
