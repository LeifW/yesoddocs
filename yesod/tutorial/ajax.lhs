<p>We're going to write a very simple AJAX application. It will be a simple site with a few pages and a navbar; when you have Javascript, clicking on the links will load the pages via AJAX. Otherwise, it will use static HTML.</p>

<p>We're going to use jQuery for the Javascript, though anything would work just fine. Also, the AJAX responses will be served as JSON. Let's get started.</p>

> {-# LANGUAGE TypeFamilies, QuasiQuotes, TemplateHaskell #-}
> import Yesod
> import Yesod.Helpers.Static
> import Data.Monoid (mempty)

Like the blog example, we'll define some data first.

> data Page = Page
>   { pageName :: String
>   , pageSlug :: String
>   , pageContent :: String
>   }

> loadPages :: IO [Page]
> loadPages = return
>   [ Page "Page 1" "page-1" "My first page"
>   , Page "Page 2" "page-2" "My second page"
>   , Page "Page 3" "page-3" "My third page"
>   ]

> data Ajax = Ajax
>   { ajaxPages :: [Page]
>   , ajaxStatic :: Static
>   }
> type Handler = GHandler Ajax Ajax

Next we'll generate a function for each file in our static folder. This way, we get a compiler warning when trying to using a file which does not exist.

> staticFiles "static/yesod/ajax"

Now the routes; we'll have a homepage, a pattern for the pages, and use a static subsite for the Javascript and CSS files.

> mkYesod "Ajax" [$parseRoutes|
> /                  HomeR   GET
> /page/#String      PageR   GET
> /static            StaticR Static ajaxStatic
> |]

<p>That third line there is the syntax for a subsite: Static is the datatype for the subsite argument; siteStatic returns the site itself (parse, render and dispatch functions); and ajaxStatic gets the subsite argument from the master argument.</p>

<p>Now, we'll define the Yesod instance. We'll still use a dummy approot value, but we're also going to define a default layout.</p>

> instance Yesod Ajax where
>   approot _ = ""
>   defaultLayout widget = do
>   Ajax pages _ <- getYesod
>   content <- widgetToPageContent widget
>   hamletToRepHtml [$hamlet|
> !!!
> %html
>   %head
>     %title $pageTitle.content$
>     %link!rel=stylesheet!href=@StaticR.style_css@
>     %script!src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
>     %script!src=@StaticR.script_js@
>     ^pageHead.content^
>   %body
>     %ul#navbar
>       $forall pages page
>         %li
>           %a!href=@PageR.pageSlug.page@ $pageName.page$
>     #content
>       ^pageBody.content^
> |]

<p>The Hamlet template refers to style_css and style_js; these were generated by the call to staticFiles above.  There's nothing Yesod-specific about the <a href="/static/yesod/ajax/style.css">style.css</a> and <a href="/static/yesod/ajax/script.js">script.js</a> files, so I won't describe them here.</p>

<p>Now we need our handler functions. We'll have the homepage simply redirect to the first page, so:</p>

> getHomeR :: Handler ()
> getHomeR = do
>   Ajax pages _ <- getYesod
>   let first = head pages
>   redirect RedirectTemporary $ PageR $ pageSlug first

And now the cool part: a handler that returns either HTML or JSON data, depending on the request headers.

> getPageR :: String -> Handler RepHtmlJson
> getPageR slug = do
>   Ajax pages _ <- getYesod
>   case filter (\e -> pageSlug e == slug) pages of
>       [] -> notFound
>       page:_ -> defaultLayoutJson (do
>           setTitle $ string $ pageName page
>           addHamlet $ html page
>           ) (json page)
>  where
>   html page = [$hamlet|
> %h1 $pageName.page$
> %article $pageContent.page$
> |]
>   json page = jsonMap
>       [ ("name", jsonScalar $ pageName page)
>       , ("content", jsonScalar $ pageContent page)
>       ]

<p>We first try and find the appropriate Page, returning a 404 if it's not there. We then use the applyLayoutJson function, which is really the heart of this example. It allows you an easy way to create responses that will be either HTML or JSON, and which use the default layout in the HTML responses. It takes four arguments: 1) the title of the HTML page, 2) some value, 3) a function from that value to a Hamlet value, and 4) a function from that value to a Json value.</p>

<p>Under the scenes, the Json monad is really just using the Hamlet monad, so it gets all of the benefits thereof, namely interleaved IO and enumerator output. It is pretty straight-forward to generate JSON output by using the three functions jsonMap, jsonList and jsonMap. One thing to note: the input to jsonScalar must be HtmlContent; this helps avoid cross-site scripting attacks, by ensuring that any HTML entities will be escaped.</p>

<p>And now our typical main function. We need two parameters to build our Ajax value: the pages, and the static loader. We'll load up from a local directory.</p>

> main :: IO ()
> main = do
>   pages <- loadPages
>   let static = fileLookupDir "static/yesod/ajax" typeByExt
>   basicHandler 3000 $ Ajax pages static
