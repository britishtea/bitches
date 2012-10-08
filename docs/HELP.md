## !help

Bitches is your bitch. For quick help on IRC, simply type `!help [module]` (e.g. `!help choons`).

### Choons

Bitches maintains a jukebox of choons.

**Usage**: `!choon [--delete] [url] [tag[, tag ...]]`

* `!choon [tag 1, [tag 2, …]]`: selects a random choon from the jukebox, matching the tags.
* `!choon url [tag 1, [tag 2, …]]`: adds a choon to the jukebox.
* `!choon --delete url` : deletes a choon from the jukebox*.

* ops only

### IMDb

Bitches can search the [IMDb](http://imdb.com) for you.

**Usage**: `!imdb [--detail] (searchterm / imdb_id)`

* `!imdb searchterm`: sends you a summary of a movie.
* `!imdb imdb_id`: sends you a summary of the movie what that imdb id.
* `!imdb --detail searchterm`: sends you just that detail about a movie (e.g. `!imdb --runtime amelie`).

Possible details are `title`, `imdb_id`, `tagline`, `plot`, `runtime`, `rating`, `release_date`, `poster_url`, `certification`, `trailer`, `genres`, `writers`, `directors` and `actors`.

### Links

Bitches has a handy list of links that are associated with the channel in one way or another.

**Usage**: `!link[s] [link name]`

* `!links`: sends you *all* links as NOTICEs.
* `!link [link name]`: sends you the one link you specified (e.g. collage).

### Pictures

Bitches adds all pictures linked in the channel to a [gallery](http://indie-gallery.no.de). It ignores pictures that are specified as *nsfw*, *nsfl* (please do), *ignore* and *personal*.

**Usage**: `-`

* `!picture --delete url`: deletes a picture from the gallery*.

* ops only

### What (**currently unavailable!**)

Bitches can search [what.cd](https://what.cd) for you. It can search for torrents, requests and users. It also has some of that Rippy magic.

**Usage**: `!what [request, rippy, torrent, user] [searchterm] [--extra parameter[, --extra parameter ...]]`

* `!what [torrent] searchterm`: searches for a torrent with the name 'searchterm'.
* `!what request searchterm`: searches for a request with the name 'searchterm'.
* `!what rippy`: sends you one of Rippy's magnificent quotes. There's also `!rippy`.
* `!what user searchterm`: searches for a user with the name 'searchterm'.

Sometimes you need a more advanced search query. Bitches got you covered. Any of the parameters described in [the What.cd JSON API](https://ssl.what.cd/wiki.php?action=article&id=998) can be sent to Bitches. For example, if you want the Crystal Castles album released in 2008, you can search for it using `!what [torrent] crystal castles - crystal castles --year 2008`. For a complete list of extra parameters, see [the API documentation](https://ssl.what.cd/wiki.php?action=article&id=998).