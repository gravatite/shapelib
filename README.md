Shapelib bindings for Ruby
===============================

This is a wrapper module of Shapefile C Library for Ruby.  Originally authored by
prasinos@users.sourceforge.net.

How to install
-----------------

* Install the shapelib C library with your Unix package management system.
* It is currently tested against Ruby 2.6 through 4.1 using RVM on Ubuntu
  
OSX
----------------

Ruby 2.6 compatibility is currently being maintained to support the old Ruby version on MacOS.

Install MacPorts.  Use it to install the shapelib C library:

    sudo port install shapelib

Now install the Rubygem:

    gem install shapelib

Troubleshooting
---------------

* I have shapelib installed but the build fails

  Try --with-shapelib-include= and --with-shapelib-lib= options:
  gem install shapelib -- --with-shapelib-include=...

If above advice doesn't help, please visit http://github.com/gravatite/shapelib and post an issue.

How to use
==========

    Please see doc/Interface.html.

Development
===========

Use Ruby 2.6 or newer with the development dependencies declared in
`shapelib.gemspec` and the shapelib C library installed.

* `rake compile` builds the extension locally.
* `rake test` (or `rake`) builds the extension and runs the tests.
* `rake gem` packages the sources as `pkg/shapelib-<version>.gem`.
  `rake package` also builds this gem.
* `rake rvm-test` builds and tests every installed RVM Ruby.
* `rake release` runs the local tests, packages the gem, and pushes it to
  RubyGems.org using your configured credentials.

Edit metadata in `shapelib.gemspec` and the version in `lib/shapelib/version.rb`.

License issues
==============

Ruby-ShapeLib is provided under LGPL or ShapeLib's MIT-style default license.
