---
title: Usage -- web-routes-quasi
---
Most of the time, there are only two functions you'll need from this package: parseRoutes and createRoutes. The former is a quasi-quoter that converts [the web-routes-quasi syntax](syntax.html) into a list of resources; the latter declares datatypes and functions based on a list of resources.

The createRoutes function is necesarily quite complicated; please see the haddock documentation. In an ideal world, normal users will never need to use that function directly, as web frameworks will provide wrappers around it. For example, Yesod does this.

However, users will always need to write their own handlers. When calling createRoutes, you will need to provide some datatype for handler functions to return; for our purposes here, we will assume that this datatype is Handler. You also need an argument datatype; we'll assume that it is MyArgs. Finally, let's assume that we have the following routes ([see the syntax page for explanation](syntax.html)):

    /                        Home    GET
    /user/#userid            User    GET POST
    /auth                    Auth    AuthRoutes authSite
    /page/$pagename          Page
    /static/*rest            Static  GET

You would need to provide functions with the following type signatures:

    getHome :: Handler
    getUser :: Integer -> Handler
    postUser :: Integer -> Handler
    authSite :: MyArgs -> Site AuthRoutes Application
    handlePage :: String -> Handler
    getStatic :: [String] -> Handler
