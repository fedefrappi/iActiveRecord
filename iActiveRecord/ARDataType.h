//
//  ARDataType.h
//  iActiveRecord
//
//  Created by Alex Denisov on 28.04.12.
//  Copyright (c) 2012 CoreInvader. All rights reserved.
//

typedef enum {
    ARDataTypeInteger   = 0,    //  integer
    ARDataTypeFloat     = 1,    //  real
    ARDataTypeString    = 2,    //  text
    ARDataTypeBlob      = 3,     //  blob
    ARDataTypeNull      = 4
} ARDataType;

const static char *const kDataTypes[] = {"integer", "real", "text", "blob", "null"};
