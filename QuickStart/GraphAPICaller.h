
//
//  GraphAPICaller.h
//  QuickStart
//
//  Created by Brandon Werner on 6/1/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "ADALiOS/ADAuthenticationContext.h"

@interface GraphAPICaller : NSObject<NSURLConnectionDataDelegate>

+(void) searchUserList:(NSString*)searchString
             parent:(UIViewController*) parent
      completionBlock:(void (^) (NSMutableArray*, NSError* error))completionBlock;

@end