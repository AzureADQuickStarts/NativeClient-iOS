//------------------------------------------------------------------------------
//
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

import UIKit
import ADAL

/// 😃 A View Controller that will respond to the events of the Storyboard.

class ViewController: UIViewController, UITextFieldDelegate, URLSessionDelegate {
    
    // Update the below to your client ID you received in the portal. The below is for running the demo only
    let kClientID = "1e305e96-7362-45a3-bab5-cb56f46df4c1"
    
    // These settings you don't need to edit unless you wish to attempt deeper scenarios with the app.
    let kGraphURI = "https://graph.microsoft.com"
    let kAuthority = "https://login.microsoftonline.com/common"
    let kRedirectUri = URL(string: "urn:ietf:wg:oauth:2.0:oob")
    
    var applicationContext : ADAuthenticationContext?
    var accessToken = String()
    
    @IBOutlet weak var loggingText: UITextView!
    @IBOutlet weak var signoutButton: UIButton!

    override func viewDidLoad() {
        
        /**
         Initialize a ADAuthenticationContext with a given authority
         
         - authority:           A URL indicating a directory that ADAL can use to obtain tokens. In Azure AD
                                it is of the form https://<instance/<tenant>, where <instance> is the
                                directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
                                identifier within the directory itself (e.g. a domain associated to the
                                tenant, such as contoso.onmicrosoft.com, or the GUID representing the
                                TenantID property of the directory)
         - error                The error that occurred creating the application object, if any, if you're
                                not interested in the specific error pass in nil.
         */
        
        self.applicationContext = ADAuthenticationContext(authority: kAuthority, error: nil)
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        signoutButton.isEnabled = (currentAccount()?.accessToken != nil)
    }
    
    /**
     This button will invoke the authorization flow.
    */

    @IBAction func callGraphButton(_ sender: UIButton) {

        if self.currentAccount() == nil {
            // We check to see if we have a current logged in account.
            // If we don't, then we need to sign someone in.
            self.acquireTokenInteractively()
        } else {
            self.acquireTokenSilently()
        }
    }

    func acquireTokenInteractively() {
        
        guard let applicationContext = self.applicationContext else { return }

        /**
         
         Acquire a token for an account
         
         - withResource:        The resource you wish to access. This will the Microsoft Graph API for this sample.
         - clientId:            The clientID of your application, you should get this from the app portal.
         - redirectUri:         The redirect URI that your application will listen for to get a response of the
                                Auth code after authentication. Since this a native application where authentication
                                happens inside the app itself, we can listen on a custom URI that the SDK knows to
                                look for from within the application process doing authentication.
         - completionBlock:     The completion block that will be called when the authentication
         flow completes, or encounters an error.
         */

        applicationContext.acquireToken(withResource: kGraphURI, clientId: kClientID, redirectUri:kRedirectUri){ (result) in
            
        guard let result = result else {
                
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }

            if (result.status != AD_SUCCEEDED) {

                if result.error.domain == ADAuthenticationErrorDomain
                    && result.error.code == ADErrorCode.ERROR_UNEXPECTED.rawValue {
                    
                    self.updateLogging(text: "Unexpected internal error occured");
                    
                } else {
                    
                    self.updateLogging(text: result.error.description)
                }
                
                return
            }
            
            self.accessToken = result.accessToken
            self.updateLogging(text: "Access token is \(self.accessToken)")
            self.updateSignoutButton(enabled: true)
            self.getContentWithToken()
        }
    }

    func acquireTokenSilently() {

        guard let applicationContext = self.applicationContext else { return }
        
        /**

         Acquire a token for an existing account silently
         - withResource:        The resource you wish to access. This will the Microsoft Graph API for this sample.
         - clientId:            The clientID of your application, you should get this from the app portal.
         - redirectUri:         The redirect URI that your application will listen for to get a response of the
                                Auth code after authentication. Since this a native application where authentication
                                happens inside the app itself, we can listen on a custom URI that the SDK knows to
                                look for from within the application process doing authentication.
         - completionBlock:     The completion block that will be called when the authentication
                                flow completes, or encounters an error.
         
         */
        
        

        applicationContext.acquireTokenSilent(withResource: kGraphURI, clientId: kClientID, redirectUri:kRedirectUri) { (result) in
            
            guard let result = result else {
                
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }

           if (result.status != AD_SUCCEEDED) {

                // USER_INPUT_NEEDED means we need to ask the user to sign-in. This usually happens
                // when the user's Refresh Token is expired or if the user has changed their password
                // among other possible reasons.

            if result.error.domain == ADAuthenticationErrorDomain
                && result.error.code == ADErrorCode.ERROR_SERVER_USER_INPUT_NEEDED.rawValue {
                
                    DispatchQueue.main.async {
                        self.acquireTokenInteractively()
                    }

                } else {
                    self.updateLogging(text: "Could not acquire token silently: \(result.error.description)")
                }

                return
            }

            self.accessToken = result.accessToken
            self.updateLogging(text: "Refreshed Access token is \(self.accessToken)")
            self.updateSignoutButton(enabled: true)
            self.getContentWithToken()
        }
    }

    func currentAccount() -> ADTokenCacheItem? {


        // We retrieve our current account by getting the last account from cache
        // In multi-account applications, account should be retrieved by home account identifier or username instead

        
            guard let cachedTokens = ADKeychainTokenCache.defaultKeychain().allItems(nil) else {
                self.updateLogging(text: "Didn't find any accounts in cache.")
                
                return nil
            }

            if !(cachedTokens.isEmpty) {
                return cachedTokens.last
            }

        return nil
    }

    func updateLogging(text : String) {

        if Thread.isMainThread {
            self.loggingText.text = text
        } else {
            DispatchQueue.main.async {
                self.loggingText.text = text
            }
        }
    }

    func updateSignoutButton(enabled : Bool) {
        if Thread.isMainThread {
            self.signoutButton.isEnabled = enabled
        } else {
            DispatchQueue.main.async {
                self.signoutButton.isEnabled = enabled
            }
        }
    }
    
    /**
        This button will invoke the call to the Microsoft Graph API. It uses the
        built in URLSession to create a connection.
     */

    func getContentWithToken() {

        // Specify the Graph API endpoint
        let url = URL(string: kGraphURI + "/v1.0/me/")
        var request = URLRequest(url: url!)
    
        // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                self.updateLogging(text: "Couldn't get graph result: \(error)")
                return
            }

            guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {

                self.updateLogging(text: "Couldn't deserialize result JSON")
                return
            }

            self.updateLogging(text: "Result from Graph: \(result))")

        }.resume()
    }

      /**
        This button will invoke the signout APIs to clear the token cache.
      */
    @IBAction func signoutButton(_ sender: UIButton) {

            /**
             Removes all tokens from the cache for this application for the current account in use
             - account:    The account user ID to remove from the cache
             */
            
            guard let account = currentAccount()?.userInformation?.userId else {
                self.updateLogging(text: "Didn't find a logged in account in the cache.")
                
                return
            }

            ADKeychainTokenCache.defaultKeychain().removeAll(forUserId: account, clientId: kClientID, error: nil)
                self.loggingText.text = ""
                self.signoutButton.isEnabled = false
                self.updateLogging(text: "Removed account")
    }

}

