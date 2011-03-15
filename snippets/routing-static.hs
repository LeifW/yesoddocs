-- START
{-# LANGUAGE TypeFamilies, QuasiQuotes, MultiParamTypeClasses, TemplateHaskell #-}
import Yesod
import Yesod.Helpers.Static

data StaticExample = StaticExample
    { getStatic :: Static
    }

-- This will create an application which only serves static files.
mkYesod "StaticExample" [$parseRoutes|
/ StaticR Static getStatic
|]
instance Yesod StaticExample where approot _ = ""
main = warpDebug 3000 $ StaticExample $ static "static"
-- STOP
