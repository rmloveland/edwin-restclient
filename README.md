# A REST client workflow for Edwin

## Overview

This project aims to integrate a REST client into the Edwin editor. Right now the basic workflow is as follows:

1. Navigate to a buffer containing JSON (or other) text you'd like to send in a request

2. Select all text in the region

3. Call the combination of shell and Edwin commands that properly escape that text and send it to the API as defined by `restclient.scm`.

So far it has three moving parts: `scurl`, a simplified curl wrapper written in Scsh, `json-escape.scm`, which escapes JSON strings into a format suitable to feed to `scurl`, and `restclient.scm`, some MIT Scheme code that runs in Edwin and tries to glue it all together.

Read on for the ugly details.

## Scurl, a curl wrapper

`Scurl.scm` is a highly simplified Scsh wrapper for [curl(1)](http://curl.haxx.se/docs/manpage.html). You generate s-expressions of the form

    '(HTTP-VERB API-URL PATH+PARAMS PAYLOAD)

and send them to this script on standard input. It returns the results of the `curl` request to standard output. The main virtue of this approach is that you don't need to play the UNIX "write my own mini-parser for every data format" game. Instead, you just use Scheme's built-in `read` procedure to do the parsing for you as `$DEITY` intended. For a much more eloquent description of this idea (and others), see Olin Shivers' excellent paper, ["A Scheme Shell"](http://www.scsh.net/docu/scsh-paper/scsh-paper.html).

### Example Usage

Here's an example API call using `scurl`; `"@auth"` is the _PAYLOAD_ we need to send. It's a JSON file containing my username and password:

    $ echo '("POST" "http://sand.api.appnexus.com" "/auth" "@auth")' | ./scurl.scm
    {"response":{"status":"OK","token":"d91tf6e31bj09gfdj4fvlof466","dbg_info":{"instance": ...

We `POST` to a URL built out of _API-URL_ and _PATH+PARAMS_. Separating the pathname from the base URL just makes it easier to send in different paths and query strings programmatically.  Finally, the `"@auth"` part is how `curl` knows to look in the file named `auth` in my working directory (this can be changed; see *Customization* below). Finally, we happen to get some kind of JSON response back from the server, but since this is `curl`, we can send whatever we like and receive whatever we like, such as XML or CSV or a binary format.

### Customizing Scurl

Scurl defines two user-customizable variables at the top of the source code file, `preferred-working-directory` and `cookie-file`, which you can edit to suit your needs. The former is the working directory the `curl` call is made from, and the latter tells `curl` which file (in that directory) to read and write your cookies from.

### Why another curl wrapper?

Why another simplified `curl` wrapper? This was written to aid integrating a key-command-driven REST client workflow with the [Edwin](http://www.gnu.org/software/mit-scheme/documentation/mit-scheme-user/Edwin.html) editor for my daily work as a technical writer documenting APIs. I like to be able to edit a JSON buffer, and with a key command (e.g. `'C-x C-p'`) `POST` that buffer directly to an API server, and then have the results of my API request pop up in yet another buffer. However, I also think `scurl` is a neat tool in its own right, and it's easy to support more of the `curl` interface if one is so inclined. Read on for more information about how to integrate this with Edwin.

## Edwin

### Sending properly escaped JSON strings to `scurl`

The included `scsh` script `json-escape.scm` is used to add the necessary escape characters to JSON strings before sending them to `scurl`. If you're using other data formats, you'll need to use the right tool to ensure that those strings are being escaped properly as well (XML, for example).

### Where's the Edwin integration?

These tools are used in Edwin like so:

1. Navigate to a JSON file you want to send to the server.

2. Issue the Edwin command `mark-whole-buffer` to mark the entire file as the current region, and then call Edwin's `shell-command-on-region` with the script `json-escape.scm` (using a handy shell alias like `json-esc`). A temporary buffer named `"*REST client output"` pops up with the JSON modified to include the necessary escape characters. Change to that buffer. Now you're sitting in a temporary Edwin buffer, with data ready to send to the API server. (This is where Edwin, and the file `restclient.scm`, come in.)

4. Once again, you need to mark the region you want to send to the API, and call the interactive Edwin command `api-send-region`. It asks what _PATH+PARAMS_ you'd like to add to the _BASE-URL_, as well as what _HTTP-VERB_ you'd like to use (`PUT`, `POST`, etc.). It uses `scurl` to make the API call, and pops up a new buffer with the output of the call.

It's much more laborious to describe the steps involved than it is to actually perform them. Especially if you're an experienced Emacs/Edwin user.

This is a work in progress. Currently, it's targeted at the APIs I use most in my daily work at AppNexus. However, much of the code is very general, and I'd like it to evolve into a general HTTP client interface for Edwin.