# Maid

[![Gem Version](https://badge.fury.io/rb/maid.svg)](http://badge.fury.io/rb/maid)
[![Build Status](https://secure.travis-ci.org/benjaminoakes/maid.svg)](http://travis-ci.org/benjaminoakes/maid)
[![Code Climate](https://codeclimate.com/github/benjaminoakes/maid.svg)](https://codeclimate.com/github/benjaminoakes/maid)
[![Hakiri](https://hakiri.io/github/benjaminoakes/maid/stable.svg)](https://hakiri.io/github/benjaminoakes/maid/stable)
[![StackOverflow](http://img.shields.io/badge/stackoverflow-maid-blue.svg)](http://stackoverflow.com/questions/tagged/maid)

**Be lazy!**  Let Maid clean up after you, based on rules you define.

[Installation](#installation)
| [Tutorial](#tutorial)
| [Example](https://github.com/benjaminoakes/maid-example)
| [User Community](https://github.com/benjaminoakes/maid/wiki)
| [Documentation][]
| [Change Log](https://github.com/benjaminoakes/maid/blob/master/ChangeLog)

Maid keeps files from sitting around too long, untouched.  Many of the downloads and temporary files you collect can
easily be categorized and handled appropriately by rules you define.  Let the `maid` in your computer take care of the
easy stuff, so you can spend more of your time on what matters.

Think of it like the email filters you might already have, but for files.  Worried about things happening that you don't
expect?  Maid doesn't overwrite files and actions are logged so you can tell what happened.

Maid is inspired by the Mac OS X shareware program [Hazel](http://www.noodlesoft.com/hazel.php).  Think of Maid as
**"Hazel for hackers"**.

Your rules are defined in Ruby, so simple rules are easy and difficult rules are possible.  This also makes Maid a great
general-purpose **advanced file renaming tool**.

## Want to help?

This project wouldn't be where it is today without its users and contributors.  Thank you!  See [AUTHORS][] and the
[contributors graph][] for more info.

  [authors]: https://github.com/benjaminoakes/maid/blob/master/AUTHORS.md
  [contributors graph]: https://github.com/benjaminoakes/maid/graphs/contributors

### For Users

[
![Flattr this git repo](https://api.flattr.com/button/flattr-badge-large.png)
](https://flattr.com/submit/auto?user_id=benjaminoakes&url=https://github.com/benjaminoakes/maid&title=maid&language=en_GB&tags=github&category=software)

* Participate in [beta testing](https://github.com/benjaminoakes/maid/issues/10)
* [Report an issue](https://github.com/benjaminoakes/maid/issues) (bug or feature request)
* Read through the [wiki](https://github.com/benjaminoakes/maid/wiki)
* Even just [share a link to Maid](https://twitter.com/intent/tweet?related=benjaminoakes&text=Be+lazy%21+Let+Maid+clean+up+after+you%2C+based+on+rules+you+define&url=https%3A%2F%2Fgithub.com%2Fbenjaminoakes%2Fmaid) :)

### For Developers

* Address a `TODO` or `FIXME` in the code.
* Complete an issue (easy ones [are labelled](https://github.com/benjaminoakes/maid/issues?labels=difficulty-1&page=1&state=open), and issues for future releases are [grouped by milestone](https://github.com/benjaminoakes/maid/issues/milestones)).
* **Working on an issue?** Please leave a comment so others know.
* See the [Contributing guide](https://github.com/benjaminoakes/maid/wiki/Contributing)

## Buzz

[
![Hacker News Logo](https://raw.github.com/benjaminoakes/maid/master/resources/hacker-news.png)
](http://news.ycombinator.com/)

[Hazel for hackers](http://news.ycombinator.com/item?id=4928605) - December 16th, 2012 (peaked at #2)

[![Ruby5 Logo](https://raw.github.com/benjaminoakes/maid/master/resources/ruby5.gif)](http://ruby5.envylabs.com/)

[Podcast #302](http://ruby5.envylabs.com/episodes/306-episode-302-august-31st-2012) (at 2:45) - August 31st, 2012

[
![OneThingWell Logo](https://raw.github.com/benjaminoakes/maid/master/resources/OneThingWell.png)
](http://onethingwell.org/)

[Maid](http://onethingwell.org/post/30455088809/maid) - August 29th, 2012

[More...](https://github.com/benjaminoakes/maid/wiki/In-the-Media)

## Installation

Maid is a gem, so just `gem install maid` like normal.  If you're unfamiliar with Ruby, please see below for details.

#### Requirements

Modern Ruby versions and Unix-like operating systems should work, but only OS X and Ubuntu are tested regularly.

Offically supported:

* **OS:** Mac OS X, Ubuntu
* **Ruby:** 1.9.3+ (2.0.x or 2.1.x are preferred)

Some features require OS X.  See the [documentation][] for more details.

### Manual Installation

First, you need Ruby.

Consider `rbenv` or `rvm`, especially if only Ruby 1.8.7 is available (e.g. if you are using an older version of OS X).

System Ruby works fine too, though:

* **Mac OS X:** Ruby 2.0.0 comes preinstalled in OS X 10.9.
* **Ubuntu:** Ruby is not preinstalled.  To install Ruby 1.9.3: `sudo apt-get install ruby1.9.1` (sic)
  ([Interested in a package?](https://github.com/benjaminoakes/maid/issues/3))

Then, you can install via RubyGems.  Open a terminal and run:

    gem install maid

(Use `sudo` if using system Ruby.)

At a later date, you can update by running:

    gem update maid

If you decide you don't want Maid installed anymore, remove it:

    gem uninstall maid

**NOTE:** This does not remove any files under `~/.maid` or crontab entries.  Please remove them at your convenience.

## Tutorial

In a nutshell, Maid uses "rules" to define how files are handled.  Once you have rules defined, you can either test what
cleaning would do (`maid clean -n`) or actually clean (`maid clean -f`).

To generate a [sample rules file](https://github.com/benjaminoakes/maid/blob/master/lib/maid/rules.sample.rb), run:

```bash
maid sample
```

Maid rules are defined using Ruby, with some common operations made easier with a small DSL (Domain Specific Language).

For example, this is a rule:

```ruby
Maid.rules do
  rule 'Old files downloaded while developing/testing' do
    dir('~/Downloads/*').each do |path|
      if downloaded_from(path).any? {|u| u.match 'http://localhost'} && 1.week.since?(accessed_at(path))
        trash(path)
      end
    end
  end
end
```

If you're new to Ruby and would prefer a more traditional `for` loop, you can also do this:

```ruby
Maid.rules do
  rule 'My rule' do
    for path in dir('~/Downloads/*')
      # ...
    end
  end
end
```

Before you start running your rules, you'll likely want to be able to test them.  Here's how:

```bash
# No actions are taken; you just see what would happen with your rules as defined.
maid clean --dry-run # Synonyms: -n, --noop
```

To run your rules on demand, you can run `maid` manually:

```bash
maid clean -f                 # Run the rules at ~/.maid/rules.rb, logging to ~/.maid/maid.log
maid clean -fr some_rules.rb  # Run the rules in the file 'some_rules.rb', logging to ~/.maid/maid.log
```

So, for example, if this is `some_rules.rb`:

```ruby
Maid.rules do
  rule 'downloaded PDF books' do
    move(dir('~/Downloads/*.pdf'), '~/Books')
  end
end
```

Then, this is the command to test, as well as some sample output:

    $ maid clean -nr some_rules.rb
    Rule: downloaded PDF books
    mv "/Users/ben/Downloads/book.pdf" "/Users/ben/Books/"
    mv "/Users/ben/Downloads/issue12.pdf" "/Users/ben/Books/"
    mv "/Users/ben/Downloads/spring2011newsletter.pdf" "/Users/ben/Books/"

For help with command line usage, run `maid help`.  For more help, please see the links at the top of this README.

### Automation

Once you get a hang for what you can do with Maid, let it do its stuff automatically throughout the day.  You'll find
your computer stays a little tidier with as you teach it how to handle your common files.

**Note:** Daemon support (using `fsevent`/`inotify`) was recently added.  That said, `cron` takes care of the needs of many users.

To do this, edit your crontab in your tool of choice:

    crontab -e

...and have it invoke the `maid clean -f` command.  The `--silent` option is provided to keep this from emailing you, if
desired.  A log of the actions taken is kept at `~/.maid/maid.log`.

Example for every day at 1am:

    # minute hour day_of_month month day_of_week command_to_execute
    0 1 * * * /bin/bash -li -c "maid clean --force --silent"
    
### Running as a daemon

To run Maid as a daemon you first have to specify watch/repeat rules.

They are defined like this:

```ruby
Maid.rules do
  repeat '1s' do
    rule 'This rule will run every second' do
      # some task
    end
  end

  watch '/home/user/Downloads' do
    rule 'This rule will run on every change to the downloads directory' do
      # another task
    end
  end

  watch '~/Desktop', ignore: /some_directory/ do
    # rules in here
  end
end
```

Here's a simple "watch" rule that organizes images by dimensions as soon as they're added to `~/Pictures`:

```ruby
Maid.rules do
  watch '~/Pictures' do
    rule 'organize images by dimensions' do
      where_content_type(dir('~/Pictures/*'), 'image').each do |image|
        width, height = dimensions_px(image)
        move(image, mkdir("~/Pictures/#{width}x#{height}"))
      end
    end
  end
end
```

The command to run the daemon is `maid daemon`.  Starting the daemon on login depends on the platform.

#### Ubuntu

You can run `maid daemon` as a normal startup application (Power/Gear Menu -> Startup Applications... -> Add).

#### OSX

Please see Jurriaan Pruis' blog post, [Maid as a Daemon on OS X](http://jurriaan.ninja/2015/01/01/maid-on-os-x.html).  ([Automating this setup would be welcome as a pull request!](https://github.com/benjaminoakes/maid/issues/136))

### Rake Tasks

Maid includes helpers that make file managment easier.  You may find them useful if you need to automate tasks in your Ruby projects.  This is available via support for Maid-based Rake tasks:

```ruby
# File: Rakefile
require 'maid'

Maid::Rake::Task.new :clean do
  # Clean up Rubinius-compilied Ruby
  trash(dir('**/*.rbc'))
end
```

In fact, the Maid project uses Maid in [its Rakefile](https://github.com/benjaminoakes/maid/blob/master/Rakefile).

You can also provide a custom description:

```ruby
Maid::Rake::Task.new clean_torrents: [:dependency], description: 'Clean Torrents' do
  trash(dir('~/Downloads/*.torrent'))
end
```

## Warranty

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING
THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU
ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

## License

GPLv2.  See LICENSE for a copy.

  [documentation]: http://www.rubydoc.info/github/benjaminoakes/maid/master/Maid/Tools
