# Maid

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=benjaminoakes&url=https://github.com/benjaminoakes/maid&title=maid&language=en_GB&tags=github&category=software)

Be lazy!  Let Maid clean up after you, based on rules you define.

Maid keeps files from sitting around too long, untouched.  Many of the downloads and other files you collect can easily be categorized and handled appropriately by rules you define.  Let the maid in your computer take care of the easy stuff, so you can spend more of your time on what matters.

Think of it like the email filters you might already have, but for files.  Worried about things happening that you don't expect?  Maid doesn't overwrite files and actions are logged so you can tell what happened.

Maid is inspired by the Mac OS X shareware program [Hazel](http://www.noodlesoft.com/hazel.php).  This tool was created on Mac OS X 10.6, but should be generally portable to other systems.  (Some of the more advanced features such as `downloaded_from` require OS X, however.)

Your rules are defined in Ruby, so easy rules are easy and difficult rules are possible.

![Still Maintained?](http://stillmaintained.com/benjaminoakes/maid.png)
[![Build Status](http://travis-ci.org/benjaminoakes/maid.png)](http://travis-ci.org/benjaminoakes/maid)

## Want to help?

* Participate in [beta testing](https://github.com/benjaminoakes/maid/issues/10)
* [Report an issue](https://github.com/benjaminoakes/maid/issues) (bug or feature request)
* Even just [share a link to Maid](https://twitter.com/intent/tweet?related=benjaminoakes&text=Be+lazy%21+Let+Maid+clean+up+after+you%2C+based+on+rules+you+define&url=https%3A%2F%2Fgithub.com%2Fbenjaminoakes%2Fmaid) :)

## Buzz

* [OneThingWell: Maid](http://onethingwell.org/post/30455088809/maid) - August 29th, 2012
* [Maid – Paresseux mais ordonné!](http://korben.info/maid-ruby-script.html) (FR) - August 30th, 2012

<blockquote class="twitter-tweet"><p>gem install maid するとメイドさんが手に入るので Ruby 便利．<a href="https://t.co/gH6XgWJH" title="https://github.com/benjaminoakes/maid">github.com/benjaminoakes/…</a></p>&mdash; りんだん（実際犬） (@Linda_pp) <a href="https://twitter.com/Linda_pp/status/241588990166310912" data-datetime="2012-08-31T17:31:18+00:00">August 31, 2012</a></blockquote>
<script src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet"><p><a href="https://t.co/YnOzpwRV" title="https://github.com/benjaminoakes/maid">github.com/benjaminoakes/…</a> 這個拿來整理檔案似乎不錯.... <a href="http://t.co/rUt2f258" title="http://fb.me/1CxgLtmyq">fb.me/1CxgLtmyq</a></p>&mdash; xdite (@xdite) <a href="https://twitter.com/xdite/status/242335478626521088" data-datetime="2012-09-02T18:57:35+00:00">September 2, 2012</a></blockquote>
<script src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

## Installation and Updating

Maid supports Mac OS X and Ubuntu.  Other Unix-like operating systems may work, but are not officially supported.  (Contributions are welcome, however.)

### Mac OS X

To install, open a terminal and run:

    sudo gem install maid

At a later date, you can update by running:

    sudo gem update maid

### Ubuntu

#### From a Package

[![Download for Ubuntu](https://github.com/benjaminoakes/maid/raw/master/resources/download-for-ubuntu.png)](https://github.com/benjaminoakes/maid/issues/3)

#### Manually

You'll need to have installed Ruby and RubyGems.  Open a terminal and run:

    # Installs Ruby 1.9.3p0 and RubyGems
    sudo apt-get install ruby1.9.1

Then install Maid itself:

    sudo gem install maid

At a later date, you can update by running:

    sudo gem update maid

### Troubleshooting

* Older releases of Ruby for Ubuntu may not automatically add the RubyGems `bin` directory to your `$PATH`.  Double check your settings.
* Having multiple Ruby versions installed can confuse things.  If you're a Ruby developer, you may prefer to just `gem install maid` with your preferred setup.  Ruby 1.9.3 is preferred.

## Tutorial

Maid rules are defined using Ruby, with some common operations made easier with a small DSL (Domain Specific Language).  Here's a sample:

    Maid.rules do
      rule 'Old files downloaded while developing/testing' do
        dir('~/Downloads/*').each do |path|
          if downloaded_from(path).any? {|u| u.match 'http://localhost'} && 1.week.since?(last_accessed(path))
            trash(path)
          end
        end
      end
    end

Before you start running your rules, you'll likely want to be able to test them.  Here's how:

    # No actions are taken; you just see what would happen with your rules as defined.
    maid clean --dry-run
    maid clean --noop
    maid clean -n

To run your rules on demand, you can run `maid` manually:

    maid clean                    # Run the rules at ~/.maid/rules.rb, logging to ~/.maid/maid.log
    maid clean -r some_rules.rb   # Run the rules in the file 'some_rules.rb', logging to ~/.maid/maid.log

So, for example, if this is `some_rules.rb`:

    Maid.rules do
      rule 'downloaded PDF books' do
        dir('~/Downloads/*.pdf').each do |path|
          move(path, '~/Books')
        end
      end
    end

This is the command to test, as well as some sample output:

    $ maid clean -nr some_rules.rb
    Rule: downloaded PDF books
    mv "/Users/ben/Downloads/book.pdf" "/Users/ben/Books/"
    mv "/Users/ben/Downloads/issue12.pdf" "/Users/ben/Books/"
    mv "/Users/ben/Downloads/spring2011newsletter.pdf" "/Users/ben/Books/"

For more DSL helper methods, please see the documentation of [Maid::Tools](http://rubydoc.info/gems/maid/0.1.0/Maid/Tools).

### Automation

Once you get a hang for what you can do with Maid, let it do its stuff automatically throughout the day.  You'll find your computer stays a little tidier with as you teach it how to handle your common files.

To do this, edit your crontab in your tool of choice and have it invoke the `maid` command.  The `--silent` option is provided to keep this from emailing you, if desired.  A log of the actions taken is kept at `~/.maid/maid.log`.

Example for every day at 1am:

    # minute hour day_of_month month day_of_week command_to_execute
    0 1 * * * /bin/bash -li -c "maid --silent"

Both Mac OS X and Linux support callbacks when folders are changed, and that may be a forthcoming feature in Maid.  That said, I find `cron` to take care of most of my needs.

## Sample

For a sample rules file, run:

    maid sample

## Warranty

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

## License

GPLv2.  See LICENSE for a copy.
