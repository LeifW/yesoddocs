# Introduction

One of the stories from the early days of the web is how search engines wiped out entire websites. When dynamic web sites were still a new concept, developers didn't appreciate the difference between a GET and POST request. As a result, they created pages- accessed with the GET method- that would delete pages. When search engines started crawling these sites, they could wipe out all the content.

If these web developers had followed the HTTP spec properly, this would not have happened. A GET request is supposed to cause no side effects (you know, like wiping out a site). Recently, there has been a move in web development called Representational State Transfer, also known as REST. This chapter describes the RESTful features in Yesod and how you can use them to create more robust web applications.

# Request methods

In many web frameworks, you write one handler function per resource. In Yesod, the default is to have a separate handler function for each **request method**. The two most common request methods you will deal with in creating web sites are GET and POST. These are the most well-supported methods in HTML, since they are the only ones supported by web forms. However, when creating RESTful APIs, the other methods are very useful.

Technically speaking, you can create whichever request methods you like, but it is strongly recommended to stick to the ones spelled out in the HTTP spec. The most common of these are:

<table border="1">
<tr>
<th>GET</th>
<td>Read-only requests. Assuming no other changes occur on the server, calling a GET request multiple times should result in the same response, barring such things as "current time" or randomly assigned results.</td>
</tr>
<tr>
<th>POST</th>
<td>A general mutating request. A POST request should never be submitted twice by the user. A common example of this would be to transfer funds from one bank account to another.</td>
</tr>
<tr>
<th>PUT</th>
<td>Create a new resource on the server, or replace an existing one. This method *is* same to be called multiple times.</td>
</tr>
<tr>
<th>DELETE</th>
<td>Just like it sounds: wipe out a resource on the server. Calling multiple times should be OK.</td>
</tr>
</table>

To a certain extent, this fits in very well with Haskell philosophy: a GET request is similar to a pure function, which cannot have side effects. Of course, in practice, your GET functions will probably perform IO, such as reading information from a database, logging user actions, and so on.

See the [routing and handlers chapter](/book/handler/) chapter for more information on the syntax of defining handler functions for each request method.

# Representations

Let's say we have a Haskell datatype and value:

    data Person = Person { name :: String, age :: Int }
    michael = Person "Michael" 25

We could represent that data as HTML:

    <table>
        <tr>
            <th>Name</th>
            <td>Michael</td>
        </tr>
        <tr>
            <th>Age</th>
            <td>25</td>
        </tr>
    </table>

or we could represent it as JSON:

    {"name":"Michael","age":25}

or as XML:

    <person>
        <name>Michael</name>
        <age>25</age>
    </person>

Often times, web applications will use a different URL to get each of these representations; perhaps /person/michael.html, /person/michael.json, etc. Yesod follows the RESTful principle of a single URL for each **resource**. So in Yesod, all of these would be accessed from /person/michael/.

Then the question becomes how do we determine *which* representation to serve. The answer is the HTTP Accept header: it gives a prioritized list of content types the client is expecting. Yesod will automatically determine which representation to serve based upon this header.

Let's make that last sentence a bit more concrete with some code:

    class HasReps a where
        chooseRep :: a -> [ContentType] -> IO (ContentType, Content)

The chooseRep function takes two arguments: the value we are getting representations for, and a list of content types that the client will accept. We determine this by reading the "Accept" request header. chooseRep returns a tuple containing the content type of our response and the actual content.

<p class="advanced"><code>Content</code> is actually just a synonym for the <code>ResponseBody</code> datatype from WAI. ResponseBody has three constructors: one for lazy bytestrings, one for files, and one for enumerators. Yesod comes with a <code>ToContent</code> typeclass that helps with these conversions. And usually you don't even need that: up until now you've been able to get by with just defaultLayout.</p>

This typeclass is the core of Yesod's RESTful approach to representations. Every handler function must return an instance of HasReps. Yesod provides a number of instances of HasReps out of the box. When we use defaultLayout, for example, the return type is RepHtml, which looks like:

    newtype RepHtml = RepHtml Content
    instance HasReps RepHtml where
        chooseRep (RepHtml content) _ = return ("text/html", content)

What's interesting here is that we ignore entirely the list of expected content types. A number of the built in representations (RepHtml, RepPlain, RepJson, RepXml) in fact only support a single representation, and therefore what the client wants is irrelevant.

## RepHtmlJson

An example to the contrary is RepHtmlJson, which provides either an HTML or JSON representation. This instance helps greatly in programming AJAX applications that degrade nicely. Here is an example that returns either HTML or JSON data, depnding on what the client wants.

~rest-rephtmljson

Our getRootR handler creates a page with three links and some Javascript which intercept clicks on the links and performs asynchronous requests. If the user has Javascript enabled, clicking on the link will cause a request to be sent with an "Accept" header of "application/json". In that case, getNameR will return the JSON representation defined on line 27.

If the user disables Javascript, clicking on the link will send the user to the appropriate URL. A web browser places priority on an HTML representation of the data, and therefore the page defined on lines 24-26 will be returned.

We can of course extend this to work with XML, Atom feeds, or even binary representations of the data. A fun exercise could be writing a web application that serves data simply using the default Show instances of datatypes, and then writing a web client that parses the results using the default Read instances.

# Atom feeds

You can check out the Atom module, which has some helper datatypes and functions for generating Atom feeds. This section will be expanded in the future with a working example.

# Other request headers

TODO: talk about how we determine gzip encoding, languages, etc.

# Summary

Yesod adheres to the following tenets of REST:

* Use the correct request method.
* Each resource should have precisely one URL.
* Allow multiple representations of data on the same URL.
* Inspect request headers to determine extra information about what the client wants.

This makes it easy to use Yesod not just for building websites, but for building APIs. In fact, using techniques such as RepHtmlJson, you can serve both a user-friendly, HTML page and a machine-friendly, JSON page from the same URL.
