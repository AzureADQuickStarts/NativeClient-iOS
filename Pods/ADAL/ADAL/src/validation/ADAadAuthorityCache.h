// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@interface ADAadAuthorityCacheRecord : NSObject

@property BOOL validated;
@property ADAuthenticationError *error;

@property NSString *networkHost;
@property NSString *cacheHost;
@property NSArray<NSString *> *aliases;

@end

@interface ADAadAuthorityCache : NSObject
{
    NSMutableDictionary<NSString *, ADAadAuthorityCacheRecord *> *_recordMap;
    pthread_rwlock_t _rwLock;
}

- (BOOL)processMetadata:(NSArray<NSDictionary *> *)metadata
              authority:(NSURL *)authority
                context:(id<ADRequestContext>)context
                  error:(ADAuthenticationError * __autoreleasing *)error;
- (void)addInvalidRecord:(NSURL *)authority
              oauthError:(ADAuthenticationError *)oauthError
                 context:(id<ADRequestContext>)context;

- (NSURL *)networkUrlForAuthority:(NSURL *)authority;
- (NSURL *)cacheUrlForAuthority:(NSURL *)authority;

/*!
    Returns an array of authority URLs for the provided URL, in the order that cache lookups
    should be attempted.
 
    @param  authority   The authority URL the developer provided for the authority context
 */
- (NSArray<NSURL *> *)cacheAliasesForAuthority:(NSURL *)authority;

- (ADAadAuthorityCacheRecord *)tryCheckCache:(NSURL *)authority;
- (ADAadAuthorityCacheRecord *)checkCache:(NSURL *)authority;

@end
