# Maid

Be lazy!  Let Maid clean up after you, based on rules you define.

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
[Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)
](https://flattr.com/submit/auto?user_id=benjaminoakes&url=https://github.com/benjaminoakes/maid&title=maid&language=en_GB&tags=github&category=software)

* Participate in [beta testing](https://github.com/benjaminoakes/maid/issues/10)
* [Report an issue](https://github.com/benjaminoakes/maid/issues) (bug or feature request)
* Read through the [wiki](https://github.com/benjaminoakes/maid/wiki)
* Even just [share a link to Maid](https://twitter.com/intent/tweet?related=benjaminoakes&text=Be+lazy%21+Let+Maid+clean+up+after+you%2C+based+on+rules+you+define&url=https%3A%2F%2Fgithub.com%2Fbenjaminoakes%2Fmaid) :)

### For Developers

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/benjaminoakes/maid)
[![Build Status](https://secure.travis-ci.org/benjaminoakes/maid.png)](http://travis-ci.org/benjaminoakes/maid)
[![Dependency Status](https://gemnasium.com/benjaminoakes/maid.png)](https://gemnasium.com/benjaminoakes/maid)

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

[
![Download for Ubuntu](https://github.com/benjaminoakes/maid/raw/master/resources/download-for-ubuntu.png)
](https://github.com/benjaminoakes/maid/issues/3)

#### Offically supported:

* **OS:** Mac OS X, Ubuntu
* **Ruby:** 1.8.7, 1.9.3 (preferred)

Some features require OS X.  See the [documentation][] for more details.  Other Ruby versions and Linux distributions
may work, but are not officially supported.  (Contributions are welcome, however.)

### Manual Installation

First, you need Ruby:

* **Mac OS X:** Ruby 1.8.7 comes preinstalled.
* **Ubuntu:** Ruby is not preinstalled.  To install Ruby 1.9.3: `sudo apt-get install ruby1.9.1 # (sic)`
  ([Interested in a package?](https://github.com/benjaminoakes/maid/issues/3))

Then, you can install via RubyGems.  Open a terminal and run:

    sudo gem install maid

At a later date, you can update by running:

    sudo gem update maid

If you decide you don't want Maid installed anymore, remove it:

    sudo gem uninstall maid

**NOTE:** This does not remove any files under `~/.maid` or crontab entries.  Please remove them at your convenience.

### Troubleshooting

* Having multiple Ruby versions installed can confuse things.  If you're a Ruby developer, you may prefer to just
  `gem install maid` with your preferred setup.  Ruby 1.9.3 is recommended.
* Older packages of Ruby for Ubuntu may not automatically add the RubyGems `bin` directory to your `$PATH`.  Double
  check your settings.

## Tutorial

In a nutshell, Maid uses "rules" to define how files are handled.  Once you have rules defined, you can either test what
cleaning would do (`maid clean -n`) or actually clean (`maid clean`).

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
      if downloaded_from(path).any? {|u| u.match 'http://localhost'} && 1.week.since?(last_accessed(path))
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
maid clean                    # Run the rules at ~/.maid/rules.rb, logging to ~/.maid/maid.log
maid clean -r some_rules.rb   # Run the rules in the file 'some_rules.rb', logging to ~/.maid/maid.log
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

**Note:** Both Mac OS X and Ubuntu support callbacks when folders are changed (`fsevent`/`inotify`), and that may be a forthcoming feature in Maid.
That said, I find `cron` to take care of most of my needs.  Pull requests are welcome, however.  :)

To do this, edit your crontab in your tool of choice:

    crontab -e

...and have it invoke the `maid clean` command.  The `--silent` option is provided to keep this from emailing you, if
desired.  A log of the actions taken is kept at `~/.maid/maid.log`.

Example for every day at 1am:

    # minute hour day_of_month month day_of_week command_to_execute
    0 1 * * * /bin/bash -li -c "maid clean --silent"

## Warranty

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING
THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU
ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

## License

GPLv2.  See LICENSE for a copy.

  [documentation]: http://rubydoc.info/gems/maid/Maid/Tools
