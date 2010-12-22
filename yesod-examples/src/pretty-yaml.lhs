<p>This example uses the <a href="http://hackage.haskell.org/package/data-object-yaml">data-object-yaml package</a> to display YAML files as cleaned-up HTML. If you've read through the other tutorials, this one should be easy to follow.</p>

> {-# LANGUAGE TypeFamilies, QuasiQuotes, TemplateHaskell #-}

> import Yesod
> import Data.Object
> import Data.Object.Yaml
> import qualified Data.ByteString as B
> import qualified Data.ByteString.Lazy as L

> data PY = PY
> type Handler = GHandler PY PY

> mkYesod "PY" [$parseRoutes|
> / Homepage GET POST
> |]

> instance Yesod PY where approot _ = ""

> template :: Maybe (Hamlet url) -> Hamlet url
> template myaml = [$hamlet|
> !!!
> %html
>     %head
>         %meta!charset=utf-8
>         %title Pretty YAML
>     %body
>         %form!method=post!action=.!enctype=multipart/form-data
>             File name:
>             %input!type=file!name=yaml
>             %input!type=submit
>         $maybe myaml yaml
>             %div ^yaml^
> |]

> getHomepage :: Handler RepHtml
> getHomepage = hamletToRepHtml $ template Nothing

> postHomepage :: Handler RepHtml
> postHomepage = do
>     rr <- getRequest
>     (_, files) <- liftIO $ reqRequestBody rr
>     fi <- case lookup "yaml" files of
>             Nothing -> invalidArgs ["yaml: Missing input"]
>             Just x -> return x
>     so <- liftIO $ decode $ B.concat $ L.toChunks $ fileContent fi
>     hamletToRepHtml $ template $ Just $ objToHamlet so

> objToHamlet :: StringObject -> Hamlet url
> objToHamlet (Scalar s) = [$hamlet|$s$|]
> objToHamlet (Sequence list) = [$hamlet|
> %ul
>     $forall list o
>         %li ^objToHamlet.o^
> |]
> objToHamlet (Mapping pairs) = [$hamlet|
> %dl
>     $forall pairs pair
>         %dt $fst.pair$
>         %dd ^objToHamlet.snd.pair^
> |]

> main :: IO ()
> main = basicHandler 3000 PY
