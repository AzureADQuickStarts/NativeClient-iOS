

Azure AD provides the Active Directory Authentication Library, or ADAL, for iOS clients that need to access protected resources.  ADAL’s sole purpose in life is to make it easy for your app to get access tokens.  To demonstrate just how easy it is, here we’ll build a Swift application that:

-	Gets access tokens for calling the Azure AD Graph API using the [OAuth 2.0 authentication protocol](https://msdn.microsoft.com/library/azure/dn645545.aspx).
-	Displays user information from the Microsoft Graph.

To build the complete working application, you’ll need to:

2. Register your application with Azure AD.
3. Install & Configure ADAL.
5. Use ADAL to get tokens from Azure AD.

To get started, [download the completed sample](https://github.com/AzureADQuickStarts/NativeClient-iOS/archive/complete.zip).  You'll also need an Azure AD tenant in which you can create users and register an application.  If you don't already have a tenant, [learn how to get one](active-directory-howto-tenant.md).

**Supporting Enterprise Protection Scenarios**

To support Intune MDM, Intune MaM, Conditional Access, or device wide SSO you'll need additional configuration after this sample is running to support a broker. Check out [this documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-v1-enable-sso-ios) and then [look at this branch](https://github.com/AzureADQuickStarts/NativeClient-iOS/tree/Scenario_SupportBroker) for a running sample supporting a broker. The changes are miminal. You may find [this Github Issue](https://github.com/AzureADQuickStarts/NativeClient-iOS/issues/3) interesting as well.


## *1. Create an Application*
To enable your app to get tokens, you'll first need to create an app in your Azure AD tenant and grant it permission to access the Azure AD Graph API:

-	Sign into the Azure Management Portal
-	In the left hand nav, click on **Active Directory**
-	Select a tenant in which to register the application.
-	Click the **Applications** tab, and click **Add** in the bottom drawer.
-	Follow the prompts and create a new **Native Client Application**.
    -	The **Name** of the application will describe your application to end-users
    -	The **Redirect Uri** is a scheme and string combination that Azure AD will use to return token responses.  We use the default value for native applications, `urn:ietf:wg:oauth:2.0:oob`
-	Once you've completed registration, AAD will assign your app a unique client identifier.  You'll need this value in the next sections, so copy it from the **Configure** tab.
- Also in **Configure** tab, locate the "Permissions to Other Applications" section.  For the "Azure Active Directory" application, add the **Access Your Organization's Directory** permission under **Delegated Permissions**.  This will enable your application to query the Graph API for users.

## *2. Install & Configure ADAL*
Now that you have an application in Azure AD, you can install ADAL and write your identity-related code.  In order for ADAL to be able to communicate with Azure AD, you need to provide it with some information about your app registration.
-	Begin by adding ADAL to the project using Cocapods.

```
$ vi Podfile
```
Add the following to this podfile:

```
 target 'QuickStart' do
   use_frameworks!
 pod 'ADAL'
 end
```

Now load the podfile using cocoapods. This will create a new XCode Workspace you will load.

```
$ pod install
...
$ open QuickStart.xcworkspace
```

-	In the QuickStart project, open the file `ViewController.swift`.  Replace the values of the elements in the section to reflect the values you input into the Azure Portal.  Your code will reference these values whenever it uses ADAL.
    -	The `kClientID` is the clientId of your application you copied from the portal.
    -	The `kRedirectUri` is the redirect url you registered in the portal.

## *3.	Use ADAL to Get Tokens from AAD*
The basic principle behind ADAL is that whenever your app needs an access token, it simply calls a completionBlock `acquireToken`, and ADAL does the rest.  

-	In the `QuickStart` project, open `ViewController.swift` and locate the `// TODO: getToken interactively.` comment near the top.  This is where you pass ADAL the coordinates through a CompletionBlock to communicate with Azure AD and tell it how to cache tokens.

```Swift
        
   func acquireToken(completion: @escaping (_ success: Bool) -> Void) {
        
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
                completion(false)
                return
            }

            if (result.status != AD_SUCCEEDED) {

                if result.error.domain == ADAuthenticationErrorDomain
                    && result.error.code == ADErrorCode.ERROR_UNEXPECTED.rawValue {
                    
                    self.updateLogging(text: "Unexpected internal error occured: \(result.error.description))");
                    completion(false)
                    
                } else {
                    
                    self.updateLogging(text: result.error.description)
                    
                }
                
                completion(false)
                
            }
            
            self.updateLogging(text: "Access token is \(String(describing: result.accessToken))")
            self.updateSignoutButton(enabled: true)
            completion(true)
        }
    }
```

- Now we need to use this token to call the Microsoft Graph. Find the `// TODO: implement Graph API Call` comment. This method makes a GET request to the Microsoft Graph API to query the current logged in user.  But in order to query the Microsoft Graph API, you need to include an access_token in the `Authorization` header of the request - this is where ADAL comes in.

```Swift
     func callAPI(retry: Bool = true) {

        // Specify the Graph API endpoint
        let url = URL(string: kGraphURI + "/v1.0/me/")
        var request = URLRequest(url: url!)
        
        guard let accessToken = currentAccount()?.accessToken else {
            // We haven't signed in yet, so let's do so now, then retry.
            // To ensure we don't prompt the user twice,
            // we set retry to false. If acquireToken() has some
            // other issue we don't want an infinite loop.
            
            if retry {
                
                self.acquireToken() { (success) -> Void in
                    if success {
                        self.callAPI(retry: false)
                    }
                }
            } else {
                
                self.updateLogging(text: "Couldn't get access token and we were told to not retry.")
            }
            return
        }
    
        // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        dataTask = defaultSession.dataTask(with: request) { data, response, error in
                
            if let error = error {
                self.updateLogging(text: "Couldn't get graph result: \(error)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                    self.updateLogging(text: "Couldn't get graph result")
                    return
            }
             
            // If we get HTTP 200: Success, go ahead and parse the JSON
            if httpResponse.statusCode == 200 {
                
                guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {
                    self.updateLogging(text: "Couldn't deserialize result JSON")
                    return
                }
                
                self.updateLogging(text: "Result from Graph: \(result))")
            }
            
            // Sometimes the server API will throw HTTP 401: Unauthorized if it is expired or needs some
            // other interaction from the authentication service. You should always refresh the
            // token on first failure just to make sure that you cannot recover.
                
            if httpResponse.statusCode == 401 {
            
                if retry {
                    // We will try to refresh the token silently first. This way if there are any
                    // issues that can be resolved by getting a new access token from the refresh
                    // token, we avoid prompting the user. If user interaction is required, the
                    // acquireTokenSilently() will call acquireToken()
                    
                        self.acquireTokenSilently() { (success) -> Void in
                            if success {
                                self.callAPI(retry: false)
                            }
                        }
                } else {
                    self.updateLogging(text: "Couldn't access API with current access token, and we were told to not retry.")
                    
                }
             }
            }
        
        dataTask?.resume()
    }
 ```


## *4. Build and Run the application*



Congratulations! You now have a working iOS application that has the ability to authenticate users, securely call Web APIs using OAuth 2.0, and get basic information about the user.  If you haven't already, now is the time to populate your tenant with some users.  Run your QuickStart app, and sign in with one of those users. Close the app, and re-run it.  Notice how the user's session remains intact.

ADAL makes it easy to incorporate all of these common identity features into your application.  It takes care of all the dirty work for you - cache management, OAuth protocol support, presenting the user with a login UI, refreshing expired tokens, and more.

For reference, the completed sample (without your configuration values) is provided [here](https://github.com/AzureADQuickStarts/NativeClient-iOS/archive/complete.zip).  You can now move on to additional scenarios.

For additional resources, check out:
- [AzureADSamples on GitHub >>](https://github.com/AzureAdSamples)
- Azure AD documentation on [Azure.com >>](http://azure.microsoft.com/documentation/services/active-directory/)
