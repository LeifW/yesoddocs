-- START
{-# LANGUAGE TypeFamilies, QuasiQuotes, MultiParamTypeClasses #-}
module HelloWorld where
import Yesod
data HelloWorld = HelloWorld
mkYesod "HelloWorld" [$parseRoutes|
/ HomeR GET
|]
instance Yesod HelloWorld where approot _ = ""
getHomeR = defaultLayout [$hamlet|\Hello World!
|]
withHelloWorld f = toWaiApp HelloWorld >>= f
