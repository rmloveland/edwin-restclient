# Scurl

Scurl is a highly simplified Scsh wrapper for
[curl(1)](http://curl.haxx.se/docs/manpage.html). You generate
s-expressions of the form

    '(HTTP-VERB API-URL PATH+PARAMS PAYLOAD)

and send them to this script on standard input. It returns the results
of the `curl` request to standard output. The main virtue of this
approach is that you don't need to play the UNIX "write my own
mini-parser for every data format" game. Instead, you just use
Scheme's built-in `read` procedure to do the parsing for you as
`$DEITY` intended. For a much more eloquent description of this idea
(and others), see Olin Shivers' excellent paper, ["A Scheme
Shell"](http://www.scsh.net/docu/scsh-paper/scsh-paper.html).

## Example

Here's an example call to an API; `"@auth"` is the _PAYLOAD_ we
need to send, a JSON file containing my username and password:

    $ echo '("POST" "http://sand.api.appnexus.com" "/auth" "@auth")' | ./scurl.scm
    {"response":{"status":"OK","token":"d91tf6e31bj09gfdj4fvlof466","dbg_info":{"instance": ...

We send a `POST` to a URL built out of _API-URL_ and _PATH+PARAMS_.
Separating the pathname from the base URL just makes it easier to send
in different paths and query strings programmatically.  Finally, the
`"@auth"` part is how `curl` knows to look in the file named `auth` in
my working directory (this can be changed; see *Customization*
below). Finally, we happen to get some kind of JSON response back from
the server, but since this is `curl`, we can send whatever we like and
receive whatever we like, such as XML or CSV or a binary format.

## Customization

Scurl defines two user-customizable variables at the top of the source
code file, `preferred-working-directory` and `cookie-file`, which you
can edit to suit. The former is the working directory the `curl` call
is made from, and the latter tells `curl` which file to read and write
your cookies from.

## Motivation

Why another simplified `curl` wrapper? This was written to aid
integrating a key-command-driven REST client workflow with the
[Edwin](http://www.gnu.org/software/mit-scheme/documentation/mit-scheme-user/Edwin.html)
editor for my daily work as a technical writer documenting APIs. I'd
like to be able to edit a JSON buffer, and with a key command (e.g.
''C-x C-p'') `POST` that buffer directly to an API server, and then
have the results of that request pop up in yet another buffer.
However, I also think it's a neat tool in its own right, and it's easy
to support more of the `curl` interface if one is so inclined. Stay
tuned for the code integrating this with Edwin.
