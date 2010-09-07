{-# LANGUAGE QuasiQuotes, TypeFamilies #-}
-- START
import Yesod
import Web.Routes.Quasi.Parse
data NoQuasi = NoQuasi
mkYesod "NoQuasi"
    [ Resource "HomeR" [] ["GET"]
    , Resource "NameR" [ StaticPiece "name"
                       , SinglePiece "String"
                       ] ["GET"]
    ]
getHomeR = defaultLayout $ addBody [$hamlet|Hello|]
getNameR name = defaultLayout $ addBody [$hamlet|Hello $name$|]
-- STOP
instance Yesod NoQuasi where approot _ = ""
main = basicHandler 3001 NoQuasi
