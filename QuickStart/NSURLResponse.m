//
//  NSURLResponse.m
//  QuickStart
//
//  Created by Brandon Werner on 2/26/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/message.h> 
#import <objc/runtime.h>

@implementation NSURLResponse(webViewHack)

static IMP originalImp;

static char *rot13decode(const char *input)
{
    static char output[100];
    
    char *result = output;
    
    // rot13 decode the string
    while (*input) {
        if (isalpha(*input))
        {
            int inputCase = isupper(*input) ? 'A' : 'a';
            
            *result = (((*input - inputCase) + 13) % 26) + inputCase;
        }
        else {
            *result = *input;
        }
        
        input++;
        result++;
    }
    
    *result = '\0';
    return output;
}

+(void) load {
    SEL oldSel = sel_getUid(rot13decode("_vavgJvguPSHEYErfcbafr:"));
    
    Method old = class_getInstanceMethod(self, oldSel);
    Method new = class_getInstanceMethod(self, @selector(__initWithCFURLResponse:));
    
    originalImp = method_getImplementation(old);
    method_exchangeImplementations(old, new);
}

-(id) __initWithCFURLResponse:(void *) cf {
    if ((self = originalImp(self, _cmd, cf))) {
        printf("-[%s %s]: %s", class_getName([self class]), sel_getName(_cmd), [[[self URL] description] UTF8String]);
        
        if ([self isKindOfClass:[NSHTTPURLResponse class]])
        {
            printf(" - %s", [[[(NSHTTPURLResponse *) self allHeaderFields] description] UTF8String]);
            printf(" - %ld", (long)[(NSHTTPURLResponse *) self statusCode]);
        }
        
        printf("\n");
    }
    
    return self;
}

@end
