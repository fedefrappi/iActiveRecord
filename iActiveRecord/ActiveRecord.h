#import <Foundation/Foundation.h>
#import "ARRelationships.h"
#import "ARValidations.h"
#import "ARValidatableProtocol.h"

@interface ActiveRecord : NSObject
{
    NSNumber *id;
    NSMutableSet *errorMessages;
}

//@property (nonatomic, retain) NSMutableSet *errorMessages;
@property (nonatomic, retain) NSNumber *id;

#pragma mark - validations

- (NSString *)recordName;
+ (void)validateField:(NSString *)aField 
             asUnique:(BOOL)aUnique;
+ (void)validateField:(NSString *)aField 
           asPresence:(BOOL)aPresence;

- (void)resetErrors;
- (void)addError:(NSString *)errMessage;
- (void)logErrors;
- (void)validate;
- (void)validateUniqueness;
- (void)validatePresence;

#pragma mark - 

+ (const char *)sqlOnCreate;
- (const char *)sqlOnSave;

+ (NSString *)tableName;
+ (id)newRecord;
+ (NSArray *)allRecords;
+ (id)findById:(NSNumber *)anId;

- (BOOL)isValid;
- (BOOL)save;

@end
