Shapelib bindings for Ruby
===============================

GitHub CI builds and tests each Ruby below on Linux (Ubuntu 24.04, x86_64)
and macOS (macOS 15, Apple Silicon). Badges show the latest push to `main`.

| Ruby | Linux | macOS (Apple Silicon) |
| --- | --- | --- |
| 2.6 | [![Ruby 2.6 / Linux](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-2.6.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-2.6.yml) | [![Ruby 2.6 / macOS](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-2.6.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-2.6.yml) |
| 3.3 | [![Ruby 3.3 / Linux](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-3.3.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-3.3.yml) | [![Ruby 3.3 / macOS](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-3.3.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-3.3.yml) |
| 3.4 | [![Ruby 3.4 / Linux](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-3.4.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-3.4.yml) | [![Ruby 3.4 / macOS](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-3.4.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-3.4.yml) |
| 4.0 | [![Ruby 4.0 / Linux](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-4.0.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-4.0.yml) | [![Ruby 4.0 / macOS](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-4.0.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-4.0.yml) |
| 4.1.0-preview1 | [![Ruby 4.1.0-preview1 / Linux](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-4.1-preview.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/linux-ruby-4.1-preview.yml) | [![Ruby 4.1.0-preview1 / macOS](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-4.1-preview.yml/badge.svg?branch=main&event=push)](https://github.com/gravatite/shapelib/actions/workflows/macos-ruby-4.1-preview.yml) |

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
* `rake rdoc` builds HTML documentation when the optional `rdoc` gem is
  installed. `rake rerdoc` rebuilds it and `rake clobber_rdoc` removes it.
* `rake clean` removes the current Ruby's build directory. `rake clobber`
  also removes compiled extensions, all build directories, packages, and
  generated documentation.
* `rake release` runs the local tests, packages the gem, and pushes it to
  RubyGems.org using your configured credentials.

Edit metadata in `shapelib.gemspec` and the version in `lib/shapelib/version.rb`.
Set `MAKE` to use another make command, or pass configuration options with
`rake compile -- --with-shapelib-include=... --with-shapelib-lib=...`.

License issues
==============

Ruby-ShapeLib code and documentation are available under either MIT or LGPL
version 2.0, at your option. See [LICENSE](LICENSE), [LICENSE-MIT](LICENSE-MIT),
and [LICENSE-LGPL](LICENSE-LGPL).

The bundled Zillow neighborhood test data has a separate CC BY-SA 3.0 license.
Its attribution is in [LICENSE](LICENSE), with the full terms in
[LICENSE-CC-BY-SA-3.0](LICENSE-CC-BY-SA-3.0). The native shapelib dependency
retains its own license terms.
