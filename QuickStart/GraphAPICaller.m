//
//  GraphAPICaller.m
//  QuickStart
//
//  Created by Brandon Werner on 6/1/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADALiOS/ADAuthenticationContext.h"
#import "ADALiOS/ADAuthenticationSettings.h"
#import "GraphAPICaller.h"
#import "AppData.h"
#import "NSDictionary+UrlEncoding.h"
#import "User.h"

@implementation GraphAPICaller

ADAuthenticationContext* authContext;
bool loadedApplicationSettings;

+ (void) readApplicationSettings {
    loadedApplicationSettings = YES;
}

+(NSString*) trimString: (NSString*) toTrim
{
    //The white characters set is cached by the system:
    NSCharacterSet* set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [toTrim stringByTrimmingCharactersInSet:set];
}

//getToken for generic Web API flows. Returns a token with no additional parameters provided.
//
//

+(void) getToken : (BOOL) clearCache
           parent:(UIViewController*) parent
completionHandler:(void (^) (NSString*, NSError*))completionBlock;
{
    AppData* data = [AppData getInstance];
    if(data.userItem){
        completionBlock(data.userItem.accessToken, nil);
        return;
    }
    
    ADAuthenticationError *error;
    authContext = [ADAuthenticationContext authenticationContextWithAuthority:data.authority error:&error];
    authContext.parentController = parent;
    NSURL *redirectUri = [[NSURL alloc]initWithString:data.redirectUriString];
    
    [ADAuthenticationSettings sharedInstance].enableFullScreen = YES;
    [authContext acquireTokenWithResource:data.resourceId
                                 clientId:data.clientId
                              redirectUri:redirectUri
                           promptBehavior:AD_PROMPT_AUTO
                                   userId:data.userItem.userInformation.userId
                     extraQueryParameters: @"nux=1" // if this strikes you as strange it was legacy to display the correct mobile UX. You most likely won't need it in your code.
                          completionBlock:^(ADAuthenticationResult *result) {
                              
                              if (result.status != AD_SUCCEEDED)
                              {
                                  completionBlock(nil, result.error);
                              }
                              else
                              {
                                  data.userItem = result.tokenCacheStoreItem;
                                  completionBlock(result.tokenCacheStoreItem.accessToken, nil);
                              }
                          }];
}

+(void) searchUserList:(NSString*)searchString
                parent:(UIViewController*) parent
       completionBlock:(void (^) (NSMutableArray* Users, NSError* error)) completionBlock
{
    if (!loadedApplicationSettings)
    {
        [self readApplicationSettings];
    }
    
    AppData* data = [AppData getInstance];
    
    NSString *graphURL = [NSString stringWithFormat:@"%@%@/users?api-version=%@&$filter=startswith(userPrincipalName, '%@')", data.taskWebApiUrlString, data.tenant, data.apiversion, searchString];

    
    [self craftRequest:[self.class trimString:graphURL]
                parent:parent
     completionHandler:^(NSMutableURLRequest *request, NSError *error) {
         
         if (error != nil)
         {
             completionBlock(nil, error);
         }
         else
         {
             
             NSOperationQueue *queue = [[NSOperationQueue alloc]init];
             
             [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 
                 if (error == nil && data != nil){
                     
                     NSDictionary *dataReturned = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                     
                     // We can grab the top most JSON node to get our graph data.
                     NSArray *graphDataArray = [dataReturned objectForKey:@"value"];
                     
                     // Don't be thrown off by the key name being "value". It really is the name of the
                     // first node. :-)
                     
                     //each object is a key value pair
                     NSDictionary *keyValuePairs;
                     NSMutableArray* Users = [[NSMutableArray alloc]init];
                     
                     for(int i =0; i < graphDataArray.count; i++)
                     {
                         keyValuePairs = [graphDataArray objectAtIndex:i];
                         
                         User *s = [[User alloc]init];
                         s.upn = [keyValuePairs valueForKey:@"userPrincipalName"];
                         s.name =[keyValuePairs valueForKey:@"givenName"];
                         
                         [Users addObject:s];
                     }
                     
                     completionBlock(Users, nil);
                 }
                 else
                 {
                     completionBlock(nil, error);
                 }
                 
             }];
         }
     }];
    
}



+(void) craftRequest : (NSString*)webApiUrlString
               parent:(UIViewController*) parent
    completionHandler:(void (^)(NSMutableURLRequest*, NSError* error))completionBlock
{
    [self getToken:NO parent:parent completionHandler:^(NSString* accessToken, NSError* error){
        
        if (accessToken == nil)
        {
            completionBlock(nil,error);
        }
        else
        {
          //  NSURL *webApiURL = [[NSURL alloc]initWithString:webApiUrlString];
            
            NSURL *webApiURL = [NSURL URLWithString:[webApiUrlString
                                                     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:webApiURL];
            
            NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
            
            [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
            
            completionBlock(request, nil);
        }
    }];
}



@end

