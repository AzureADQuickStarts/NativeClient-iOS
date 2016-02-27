//
//  LoginViewController.h
//  QuickStart
//
//  Created by Brandon Werner on 2/24/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController: UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *loginView;


- (void)handleOAuth2AccessResult:(NSString *)accessResult;
- (void)setupOAuth2AccountStore;
- (void)requestOAuth2Access;

@end
