Ubuntu Packaging
================

Why?
----

Having an Ubuntu package makes installing Maid a lot easier on Ubuntu, especially for people unfamiliar with Ruby.

How?
----

As you probably know, Ubuntu uses Debian-style packages.  Debian packaging is a surprisingly hard thing to do with Ruby if you rely on gem dependencies.

There seem to be 3 levels:

1. Make a meta package that makes sure Ruby and RubyGems are installed, and then install the gem you want.  (Essentially, this just automates the current method of installation.)
2. Remove as many external dependencies as you can.  Embed them directly into your package.  (Vagrant does this, as does the Heroku toolbelt.)
3. Make Debian packages for all gem dependencies and then distribute them yourself.

Although it's less "pure" than I might like, I've chosen to make meta packages (**level 1**, above).  They simply install the core dependencies (Ruby and RubyGems), the given version of the gem, and its gem dependencies.  In concept:

    maid-0.1.0.all.deb => maid-0.1.0.gem
    maid-0.1.1.all.deb => maid-0.1.1.gem
    etc.

References:

* [Create Debian Linux packages](http://www.ibm.com/developerworks/linux/library/l-debpkg/index.html) - A lot of good background info
* [How do I package a Ruby application for Ubuntu, including its gem dependencies?](http://stackoverflow.com/questions/12233350/how-do-i-package-a-ruby-application-for-ubuntu-including-its-gem-dependencies) - My question

Relevant tools:

* `fpm`
* `gem2deb`, `dh-make-ruby`, and friends

What else?
----------

Despite its name, `ruby1.9.1` actually packages Ruby 1.9 (e.g., `ruby 1.9.3p0`).  Also, as of Ruby 1.9, RubyGems is included with Ruby.  The `rubygems` package is for Ruby 1.8.
