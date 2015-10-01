slam
====

- [Homepage](TODO)
- [Gerrit](TODO)
- [Documentation](TODO)
- [Bugs](TODO)

Description
-----------

Multi database support for ActiveRecord 4 with migration support.

Features
-----------------

- Streamlined way of using multiple databases with ActiveRecord
- Standard production/development/test (or whatever you want) labels
- CLI interface that allows fast creation of scripts using ActiveRecord models

Synopsis
--------

With the executable:

  # look what you can actually do
  multi_ar --help
  # list available databases for usage
  multi_ar -l
  # configure database
  cp config/database.yaml.example config/database.yaml
  vi config/database.yaml # change foo in foo_development to one of databases in multi_ar -l
  # list rake tasks that the gem supports
  multi_ar -T
  # run migrations for all databases
  multi_ar -t db:migrate
  # read documentation of db:new_migration
  multi_ar -t db:new_migration -d nya
  # create new migration for database nya
  multi_ar -t db:new_migration[NewMigraine] -d nya

When using the API, MultiAR.new must be called before anything else.

TODO: example about using the API

Requirements
------------

* Ruby 2.1 or greater (tested with 2.1 and 2.2; may work with earlier version but no guarantees)

Known problems
--------------

TODO: I don’t think info is actually correct, but I need to figure out common causes of that and document it, I guess.
ActiveRecord may give an error like `No connection pool for Foo::Bar::Model (ActiveRecord::ConnectionNotEstablished)`
in case there is no available connection. This means you need to pass database YAML file which contains this database
with `--db-config`, in slam’s configuration file with key db_config or with `MultiAR.initialize(db_config: "")`.
Also note that environment affects to this.

These should eventually be fixed, feel free to open a pull request for these :-)

Install
-------

  gem install multi_ar

Assuming you know where to install the gem from, of course...

The configuration options can be specified in config file. There is example config in gem’s

Developers
----------

  gem install bundler
  bundle install
  cucumber
  # write new feature
  cucumber
  # rinse and repeat :-)

License
-------

(The MIT License)

Copyright (c) 2015 Samu Voutilainen

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

This gem is inspired by code of [active_record_migrations](://github.com/rosenfeld/active_record_migrations).


