> {-# LANGUAGE QuasiQuotes #-}
> {-# LANGUAGE TemplateHaskell #-}
> {-# LANGUAGE TypeFamilies #-}

> import Yesod
> import Data.Monoid (mempty)

> data I18N = I18N
> type Handler = GHandler I18N I18N

> mkYesod "I18N" [$parseRoutes|
> /            HomepageR GET
> /set/#String SetLangR  GET
> |]

> instance Yesod I18N where
>     approot _ = "http://localhost:3000"

> getHomepageR :: Handler RepHtml
> getHomepageR = do
>     ls <- languages
>     let hello = chooseHello ls
>     let choices =
>             [ ("en", "English")
>             , ("es", "Spanish")
>             , ("he", "Hebrew")
>             ]
>     defaultLayout $ do
>       setTitle $ string "I18N Homepage"
>       addBody [$hamlet|
> %h1 $hello$
> %p In other languages:
> %ul
>     $forall choices choice
>         %li
>             %a!href=@SetLangR.fst.choice@ $snd.choice$
> |]

> chooseHello :: [String] -> String
> chooseHello [] = "Hello"
> chooseHello ("he":_) = "שלום"
> chooseHello ("es":_) = "Hola"
> chooseHello (_:rest) = chooseHello rest

> getSetLangR :: String -> Handler ()
> getSetLangR lang = do
>     setLanguage lang
>     redirect RedirectTemporary HomepageR

> main :: IO ()
> main = basicHandler 3000 I18N
