{-# LANGUAGE TypeFamilies, QuasiQuotes, TemplateHaskell #-}
import Yesod

data Session = Session
mkYesod "Session" [$parseRoutes|
/ Root GET POST
|]
getRoot :: Handler Session RepHtml
getRoot = do
    sess <- reqSession `fmap` getRequest
    hamletToRepHtml [$hamlet|
%form!method=post
    %input!type=text!name=key
    %input!type=text!name=val
    %input!type=submit
%h1 $cs.show.sess$
|]

postRoot :: Handler Session ()
postRoot = do
    key <- runFormPost $ required $ input "key"
    val <- runFormPost $ required $ input "val"
    setSession key val
    liftIO $ print (key, val)
    redirect RedirectTemporary Root

instance Yesod Session where
    approot _ = ""
    clientSessionDuration _ = 1
main = toWaiApp Session >>= basicHandler 3000
