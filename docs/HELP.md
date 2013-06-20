# !help

Bitches is your bitch. For quick help on IRC, simply type `!help [module]` (e.g. `!help choons`).

## Google

**Usage**: `!g[oogle] <search term>` or `!<yt|youtube> <search term>`

* `!g <search term>`: Gets the first result from Google.
* `!google <search term>`: Gets the first three results from Google.
* `!yt <search term>`: Gets the first result from Youtube.
* `!youtube <search term>`: Gets the first three results from Youtube. 

## IMDb

Bitches can search the [IMDb](http://imdb.com) for you.

**Usage**: `!imdb [--<detail>] (<searchterm>|<imdb id>|more)`

* `!imdb <searchterm>`: sends you a summary of a movie.
* `!imdb <imdb id>`: sends you a summary of the movie what that imdb id.
* `!imdb --<detail> <searchterm>`: sends you just that detail about a movie (e.g. `!imdb --runtime amelie`).
* `!imdb more`: sends you a link to a search query on IMDb (in case bitches fucked up).

Possible details are `title`, `imdb_id`, `tagline`, `plot`, `runtime`, `rating`, `release_date`, `poster_url`, `certification`, `trailer`, `genres`, `writers`, `directors` and `actors`.

## Last

**Usage**: see below.

* `!artist [<artist name>]`: looks up artist information.
* `!compare <nickname one> [<nickname two>]`: compares two users.
* `!getusername [<nickname>]`: looks up your or `nickname`'s last.fm username.
* `!np [<nickname>]`: looks up the track you or 'nickname' is currently listening to.
* `!setusername <last.fm username>`: registers your last.fm username with bitches.
* `!similar [<artist name>]`: looks up similar artists.*

\* The artist name listened to the artist last listened to if no artist is given.

## Links

Bitches has a handy list of links that are associated with the channel in one way or another.

**Usage**: `!link[s] <link name>`

* `!links`: sends you *all* links as NOTICEs.
* `!link <link name>`: sends you the one link you specified (e.g. `!link collage`).

## Media

Bitches adds all pictures linked in the channel to a [gallery](http://indie-gallery.herokuapp.com). It ignores pictures that are specified as *nsfw*, *nsfl* (please do), *ignore* and *personal*.

**Usage**: `-`

* `!delete url`: deletes a picture from the gallery**\***.

\* ops only

## Recommend

**Usage**: `!rec (clear|get|<nickname> <recommendation>)`

* `!rec clear`: deletes all recommendations.
* `!rec get`: gets all reccomendations.
* `!rec <nickname> <recommendation>`: makes a recommendation to `<nickname>`.

## Slang

Bitches can search the [Urban Dictionary](http://urbandictionary.com/) for you.

**Usage**: `!slang <word>`

## Weather

**Usage**: `!weather [<location>]`

\* The location defaults to the location you last used.

## What

Bitches can search [what.cd](https://what.cd) for you. It can search for torrents, requests and users. It also has some of that Rippy magic.

**Usage**: `!what [(request|torrent|user)] [<searchterm>] [--<parameter> <value> ...]`

* `!what <searchterm> [options]`: searches for a torrent with the name 'searchterm'.
* `!what request <searchterm> [options]`: searches for a request with the name 'searchterm'.
If no arguments are specified then the most recent requests are shown.
* `!what user <username> [options]`: searches for a user with the name 'username'.

Sometimes you need a more advanced search query. Bitches got you covered. Any of the parameters described in [the What.cd JSON API](https://ssl.what.cd/wiki.php?action=article&id=998) can be sent to Bitches. For example, if you want the Crystal Castles album released in 2008, you can search for it using `!what [torrent] crystal castles - crystal castles --year 2008`. For a complete list of extra parameters, see [the API documentation](https://ssl.what.cd/wiki.php?action=article&id=998).
