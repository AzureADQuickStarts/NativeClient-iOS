

Azure AD provides the Active Directory Authentication Library, or ADAL, for iOS clients that need to access protected resources.  ADAL’s sole purpose in life is to make it easy for your app to get access tokens.  To demonstrate just how easy it is, here we’ll build a Swift application that:

-	Gets access tokens for calling the Azure AD Graph API using the [OAuth 2.0 authentication protocol](https://msdn.microsoft.com/library/azure/dn645545.aspx).
-	Displays user information from the Microsoft Graph.

To build the complete working application, you’ll need to:

2. Register your application with Azure AD.
3. Install & Configure ADAL.
5. Use ADAL to get tokens from Azure AD.

To get started, [download the completed sample](https://github.com/AzureADQuickStarts/NativeClient-iOS/archive/complete.zip).  You'll also need an Azure AD tenant in which you can create users and register an application.  If you don't already have a tenant, [learn how to get one](active-directory-howto-tenant.md).

## *1. Determine what your Redirect URI will be for iOS*

In order to securely launch your applications in certain SSO scenarios we require that you create a **Redirect URI** in a particular format. A Redirect URI is used to ensure that the tokens return to the correct application that asked for them.

The iOS format for a Redirect URI is:

```
<app-scheme>://<bundle-id>
```

- 	**aap-scheme** - This is registered in your XCode project. It is how other applications can call you. You can find this under Info.plist -> URL types -> URL Identifier. You should create one if you don't already have one or more configured.
- 	**bundle-id** - This is the Bundle Identifier found under "identity" un your project settings in XCode.

An example for this QuickStart code would be: ***msquickstart://com.microsoft.identity.client.sample.quickstart***

## *2. Create an Application*
To enable your app to get tokens, you'll first need to create an app in your Azure AD tenant and grant it permission to access the Azure AD Graph API:

-	Sign into the Azure Management Portal
-	In the left hand nav, click on **Active Directory**
-	Select a tenant in which to register the application.
-	Click the **Applications** tab, and click **Add** in the bottom drawer.
-	Follow the prompts and create a new **Native Client Application**.
    -	The **Name** of the application will describe your application to end-users
    -	The **Redirect Uri** is a scheme and string combination that Azure AD will use to return token responses.  Enter a value specific to your application based on the information above.
-	Once you've completed registration, AAD will assign your app a unique client identifier.  You'll need this value in the next sections, so copy it from the **Configure** tab.
- Also in **Configure** tab, locate the "Permissions to Other Applications" section.  For the "Azure Active Directory" application, add the **Access Your Organization's Directory** permission under **Delegated Permissions**.  This will enable your application to query the Graph API for users.

## *3. Install & Configure ADAL*
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

-	In the QuickStart project, open the file `sViewController.swift`.  Replace the values of the elements in the section to reflect the values you input into the Azure Portal.  Your code will reference these values whenever it uses ADAL.
    -	The `kClientID` is the clientId of your application you copied from the portal.
    -	The `kRedirectUri` is the redirect url you registered in the portal.

## *4.	Use ADAL to Get Tokens from AAD*
The basic principle behind ADAL is that whenever your app needs an access token, it simply calls a completionBlock `acquireToken`, and ADAL does the rest.  

-	In the `QuickStart` project, open `ViewController.swift` and locate the `// TODO: getToken interactively.` comment near the top.  This is where you pass ADAL the coordinates through a CompletionBlock to communicate with Azure AD and tell it how to cache tokens.

```Swift
func acquireTokenInteractively() {
        
        guard let applicationContext = self.applicationContext else { return }

        /**
         
         Acquire a token for an account
         
         - withResource:        The resource you wish to access. This will the Microsoft Graph API for this sample.
         - clientId:            The clientID of your application, you should get this from the app portal.
         - redirectUri:         The redirect URI that your application will listen for to get a response of the Auth code after authentication. Since       this a native application where authentication happens inside the app itself, we can listen on a custom URI that the SDK knows to look for from within the application process doing authentication.
         - completionBlock:     The completion block that will be called when the authentication
         flow completes, or encounters an error.
         */

        applicationContext.acquireToken(withResource: kGraphURI, clientId: kClientID, redirectUri:kRedirectUri){ (result) in

            if (result!.status != AD_SUCCEEDED) {

                if result!.error.domain == ADAuthenticationErrorDomain
                    && result!.error.code == ADErrorCode.ERROR_UNEXPECTED.rawValue {
                    
                    self.updateLogging(text: "Unexpected internal error occured");
                    
                } else {
                    
                    self.updateLogging(text: result!.error.description)
                }
                
                return
            }
            
            guard let result = result else {
                
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }

            self.accessToken = result.accessToken!
            self.updateLogging(text: "Access token is \(self.accessToken)")
            self.updateSignoutButton(enabled: true)
            self.getContentWithToken()
        }
    }
```

- Now we need to use this token to call the Microsoft Graph. Find the `// TODO: implement Graph API Call` comment. This method makes a GET request to the Microsoft Graph API to query the current logged in user.  But in order to query the Microsoft Graph API, you need to include an access_token in the `Authorization` header of the request - this is where ADAL comes in.

```Swift
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
```


## Step 5: Build and Run the application



Congratulations! You now have a working iOS application that has the ability to authenticate users, securely call Web APIs using OAuth 2.0, and get basic information about the user.  If you haven't already, now is the time to populate your tenant with some users.  Run your QuickStart app, and sign in with one of those users. Close the app, and re-run it.  Notice how the user's session remains intact.

ADAL makes it easy to incorporate all of these common identity features into your application.  It takes care of all the dirty work for you - cache management, OAuth protocol support, presenting the user with a login UI, refreshing expired tokens, and more.

For reference, the completed sample (without your configuration values) is provided [here](https://github.com/AzureADQuickStarts/NativeClient-iOS/archive/complete.zip).  You can now move on to additional scenarios.

For additional resources, check out:
- [AzureADSamples on GitHub >>](https://github.com/AzureAdSamples)
- [CloudIdentity.com >>](https://cloudidentity.com)
- Azure AD documentation on [Azure.com >>](http://azure.microsoft.com/documentation/services/active-directory/)
