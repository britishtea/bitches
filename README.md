# Bitches

## What is it?

Bitches is an IRC bot written for [#indie](irc://irc.what-network.com/#indie). It is written in Ruby and relies on [Cinch](https://github.com/cinchrb/cinch).

## Installation

If you simply want to run bitches:

1. Clone the repository: `git clone git://github.com/britishtea/bitches.git`.
2. Set up some environment variables: `NICKSERV_PASSWORD`, `DATABASE_URL`, `WHATCD_USERNAME` and `WHATCD_PASSWORD`.
3. Install dependencies: `bundle install`.
4. Run it: `rake run`.

If you would like to run it from a remote server:

1. Clone the repository: `git clone git://github.com/britishtea/bitches.git`.
2. Set up a remote repository:

```shell
mkdir bitches.git && cd bitches.git
git init && git config receive.denyCurrentBranch ignore
```

3. Edit the post-receive hook (the `post-receive.sample` file from the cloned repository). Copy it to the remote repository to the hooks folder: `./bitches.git/hooks/post-receive`.
4. Add the remote repository to your local repository: `git remote add remote server.com:bitches.git`
5. Push changes to the remote repository: `git push remote master`.

## Usage

See [HELP.md](https://github.com/britishtea/bitches/blob/master/HELP.md).

## License - MIT License

Copyright (C) 2012 Paul Brickfeld

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.