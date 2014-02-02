# !help

Bitches is your bitch. For quick help on IRC, simply type `!help [module]` 
(e.g. `!help what`).

## IMDb

**Usage**: `!imdb <search term or id>`

* `!imdb search term`: Gives a summary for the movie "search term".
* `!imdb 0068284`: Gives a summary for the movie with id "0068284". You can 
leave the tt on the id if you like.

## Last

**Usage**: see below.

* `!artist [<artist name>]`: Looks up artist information.*
* `!compare <nickname one> [<nickname two>]`: Compares two users.
* `!getusername [<nickname>]`: Looks up your or `nickname`'s last.fm username.
* `!np [<nickname>]`: Looks up the track you or 'nickname' is currently 
listening to.
* `!setusername <last.fm username>`: registers your last.fm username with 
bitches.
* `!similar [<artist name>]`: looks up similar artists.*

\* If the artist name is not given, the artist you are currently listening to is
used.

## Links

Bitches has a handy list of links that are associated with the channel in one 
way or another.

**Usage**: `!link[s] <link name>`

* `!links`: sends you *all* links as NOTICEs.
* `!link <link name>`: sends you the one link you specified (e.g. `!link 
collage`).

## Media

Bitches adds all pictures linked in the channel to a [gallery][gallery]. It 
ignores pictures that are specified as *nsfw* and *nsfl* (please do).

**Usage**: `-`

* `!delete url`: deletes a picture from the gallery**\***.

\* ops only

[gallery]: http://indie-gallery.herokuapp.com

## Search

**Usage**: `!g[oogle] <search term>` or `!<yt|youtube> <search term>`

* `!g search term`: Gets the first Google result for "search term".
* `!google search term`: Gets the first three Google results for "search 
term".
* `!yt search term`: Gets the first Youtube result for "search term".
* `!youtube search term`: Gets the first three YouTube results for "search 
term". 

## Weather

**Usage**: `!weather [<location>]`

* `!weather location`: Gets the weather for "location".
* `!weather`: Gets the weather for the location you last used.

## What

**Usage**: `!what <searchterm> [options]`

* `!what searchterm`: searches for a torrent with the name 'searchterm'.
* `!whois <irc nickname>`: links an IRC nick to a WhatCD user.

Possible options are `--year` and `--tag`.
