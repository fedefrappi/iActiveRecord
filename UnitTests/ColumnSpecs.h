//
//  ColumnSpecs.h
//  iActiveRecord
//
//  Created by Alex Denisov on 01.05.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "Cedar-iOS/SpecHelper.h"
#define EXP_SHORTHAND
#import "Expecta.h"
#import "ARDatabaseManager.h"
#import "User.h"
#import "ARColumn.h"

SPEC_BEGIN(ColumnSpecs)

beforeEach(^{
    [[ARDatabaseManager sharedInstance] clearDatabase];
});
afterEach(^{
    [[ARDatabaseManager sharedInstance] clearDatabase];
});

describe(@"User", ^{
    it(@"should have changed columns", ^{
        User *user = [User newRecord];
        user.name = @"Alex";
        expect([user updatedFields].count).Not.toEqual(0);
    });
});

SPEC_END