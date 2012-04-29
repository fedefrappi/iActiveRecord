//
//  SaveLoadSpecs.h
//  iActiveRecord
//
//  Created by Alex Denisov on 29.04.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

#import "Cedar-iOS/SpecHelper.h"
#define EXP_SHORTHAND
#import "Expecta.h"
#import "ARDatabaseManager.h"
#import "Car.h"

SPEC_BEGIN(SaveLoad)

beforeEach(^{
    [[ARDatabaseManager sharedInstance] clearDatabase];
});
afterEach(^{
    [[ARDatabaseManager sharedInstance] clearDatabase];
});

describe(@"ActiveRecord", ^{
    it(@"should success save and load record", ^{
        Car *car = [Car newRecord];
        car.model = @"UAZ 2101";
        [car save];
        Car *firstCar = [[Car allRecords] first];
        expect(car.model).toEqual(firstCar.model);
    });
});

SPEC_END
