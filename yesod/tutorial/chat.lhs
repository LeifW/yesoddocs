---
title: Chat -- Tutorials -- Yesod
---
OK, maybe chat is a little over-reaching for this tutorial... but I like typing less, and chat is shorter than message board ;).

In this tutorial, we'll create an app that let's you log in and add messages. The server will display all messages to logged-in users.

> {-# LANGUAGE TypeFamilies, QuasiQuotes, TemplateHaskell #-}
> import Yesod
> import Yesod.Helpers.Auth
> import Control.Concurrent.MVar

> data Message = Message
>   { messageAuthor :: String
>   , messageContent :: String
>   }

Since we want to alter the list of messages, we're going to need a mutable variable. Note that this application- for simplicity- does not store any information on disk, so you'll lose your history on a server restart.

> data Chat = Chat
>   { chatMsgs :: MVar [Message]
>   , chatAuth :: Auth
>   }

> loadChat :: IO Chat
> loadChat = do
>   msgs <- newMVar []
>   return $ Chat msgs Auth
>       { authIsOpenIdEnabled = True
>       , authRpxnowApiKey = Just "c8043882f14387d7ad8dfc99a1a8dab2e028f690"
>       }

For those not familiar with Rpxnow, it's a service that makes it easy to support logins from external sites. You need to sign up for each site you create and get a private key. I guess I broke the rules by putting the one above in this tutorial... oh well.

> mkYesod "Chat" [$parseRoutes|
> /                  HomeR      GET
> /auth              AuthR      Auth   siteAuth   chatAuth
> /messages          MessagesR  GET POST
> |]

There are three resource patterns: the homepage, the auth subsite, and the messages page. When you GET the messages page, it will give you the history. POSTing will allow you to add a message. The homepage will have login information.

And now let's hit the typeclasses; as usual, we need the Yesod typeclass. Now, we'll also add the YesodAuth typeclass. Like Yesod, it provides default values when possible. Since we need to provide a return URL for OpenID, we now need a valid value for approot instead of just an empty string.

> instance Yesod Chat where
>   approot _ = "http://localhost:3000"

> instance YesodAuth Chat where
>   defaultDest _ = MessagesR
>   defaultLoginRoute _ = HomeR

This basically says "send users to MessagesR on login, and to HomeR when they *need* to login."

Now we'll write the homepage; that funny iframe bit at the bottom comes straight from RPXnow.

> getHomeR :: Handler Chat RepHtml
> getHomeR = applyLayout "Chat Home" (return ()) [$hamlet|
> %p You can log in with OpenId:
> %form!action=@AuthR.OpenIdForward@
>   OpenID:
>   %input!type=text!name=openid
>   %input!type=submit!value=Login
> Or use any of these:
> <iframe src="http://yesod-test.rpxnow.com/openid/embed?token_url=@AuthR.RpxnowR@" scrolling="no" frameBorder="no" allowtransparency="true" style="width:400px;height:240px"></iframe>
> |]

Next, we'll write the GET handler for messages. We use the "requireCreds" to get the user's credentials. If the user it not logged in, they are redirected to the homepage.

> getMessagesR :: Handler Chat RepHtml
> getMessagesR = do
>   creds <- requireCreds -- now we know we're logged in
>   msgs' <- chatMsgs `fmap` getYesod
>   msgs <- liftIO $ readMVar msgs'
>   hamletToRepHtml $ template msgs creds
>  where
>   template msgs creds = [$hamlet|
>       !!!
>       %html
>           %head
>               %title Silly Chat Server
>           %body
>               %p Logged in as $cs.credsIdent.creds$
>               %form!method=post!action=@MessagesR@
>                   Enter your message: 
>                   %input!type=text!name=message!width=400
>                   %input!type=submit
>               %h1 Messages
>               %dl
>                   $forall msgs msg
>                       %dt $cs.messageAuthor.msg$
>                       %dd $cs.messageContent.msg$
>   |]

Pretty straight-forward. Now we'll add the post handler.

> postMessagesR :: Handler Chat ()
> postMessagesR = do
>   creds <- requireCreds -- now we know we're logged in
>   message <- runFormPost $ notEmpty $ required $ input "message"
>   msgs <- chatMsgs `fmap` getYesod
>   let msg = Message (credsIdent creds) message
>   liftIO $ modifyMVar_ msgs $ return . (:) msg
>   redirect RedirectTemporary MessagesR

This includes a minor introduction to the Yesod.Form module. The second line in the do block essentially says to get the "message" POST parameter; there must be precisely one parameter and cannot be empty (ie, ""). The modifyMVar_ line simply tacks the new message onto the message MVar, and then we redirect to view the messages.

Finally, we'll do our standard main function.

> main :: IO ()
> main = do
>   chat <- loadChat
>   app <- toWaiApp chat
>   basicHandler 3000 app
