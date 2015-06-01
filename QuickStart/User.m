//
//  User.m
//  QuickStart
//
//  Created by Brandon Werner on 5/22/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@implementation User
@synthesize upn;
@synthesize name;

+ (id)NameOfUpn:(NSString *)upn name:(NSString *)name
{
    User *newUser = [[self alloc] init];
    newUser.name = name;
    newUser.upn = upn;
    return newUser;
}

@end
