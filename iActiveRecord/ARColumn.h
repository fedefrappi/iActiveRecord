//
//  ARColumn.h
//  iActiveRecord
//
//  Created by Alex Denisov on 29.04.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARColumn : NSObject

@property (nonatomic, readonly, copy) NSString *propertyName;
@property (nonatomic, copy, readonly) Class propertyClass;

@end
