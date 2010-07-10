Shapelib bindings for Ruby
===============================

This is a wrapper module of Shapefile C Library for Ruby.  Originally authored by
prasinos@users.sourceforge.net.

How to install
-----------------

* Install the shapelib C library with your Unix package management system.
* It is expected to run on all ruby-running environments. But it is tested
  only on RedHat Enterprise Linux 4.0 and Vine Linux 3.0.
  
OSX
----------------

Install MacPorts.  Use it to install the shapelib C library:

    sudo port install shapelib

Now install the Rubygem:

    gem install shapelib

Troubleshooting
---------------

* I have shapelib installed but the build fails

  Try --with-shapelib-include= and --with-shapelib-lib= options:
  gem install shapelib -- --with-shapelib-include=...

If above advice doesn't help, please visit http://github.com/mperham/shapelib and post an issue.

How to use
==========

    Please see doc/Interface.html.

License issues
==============

Ruby-ShapeLib is provided under LGPL or ShapeLib's MIT-style default license.
