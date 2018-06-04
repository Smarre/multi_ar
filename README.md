multi_ar
====

- [Homepage](http://smarre.github.io/multi_ar)
- [Repository (Github)](https://github.com/Smarre/multi_ar)
- [Documentation](http://www.rubydoc.info/github/Smarre/multi_ar/master)
- [Bugs (Github)](https://github.com/Smarre/multi_ar/issues)

Description
-----------

Allows you to use multiple databases with [ActiveRecord 5](https://rubygems.org/gems/activerecord), with
optional support for Rails’s migration generator (`rails generate migration ..`).

Our documentation uses [YARD](http://yardoc.org), you may want to see [the generated
documentation](http://www.rubydoc.info/github/Smarre/multi_ar/master) instead of Github README.

The project consists from two parts, the core library `multi_ar` and supplementary library `multi_ar_migrations`,
where former implements everything needed for usage of multiple databases in any application and latter providers
migration infrastructure for creating migrations for development needs.

Features
-----------------

- Streamlined way of using multiple databases with ActiveRecord
- Standard production/development/test (or whatever you want) labels
- CLI interface that allows fast creation of scripts using ActiveRecord models
- Works across different ActiveRecord versions; instead of using private, version dependent API,
  internal parts have been implemented in this project.

Installing
----------

    $ gem install multi_ar multi_ar_migrations

or with Bundler

    # In Gemfile
    gem "multi_ar"

    group :development do
      gem "multi_ar_migrations"
    end

and then install the bundle:

```shell
$ bundle install
```

Using
-----

### With the executable

```shell
# Look what you can do
$ multi_ar --help
# Create your new project
$ mkdir shiny_new_project
$ cd shiny_new_project
# Initialize the project
$ multi_ar --init
# Configure databases
$ vi config/database.yaml # change foo in foo_development to one of databases in multi_ar -l
# List rake tasks that the gem supports
$ multi_ar -T
# Read documentation of db:new_migration
$ multi_ar -t db:new_migration -d my_database
# Create new migration for database my_database
$ multi_ar -t db:new_migration[NewMigraine] -d my_database
# Run migrations for all databases
$ multi_ar -t db:migrate
```

### With the API

There is few different ways of using the API, by subclassing {MultiAR::MultiAR}, by using {MultiAR::MultiAR}
directly and by implementing your own executable using {MultiAR::Interface}.

#### Models

Models works like standard ActiveRecord models, with exception that they should be inherited from your custom model.

With multiple databases, you need to define connections in your models. For convenience, it’s usually good idea
to do one model per database, where your connection details to that database resides.

For example, if you have table named `my_new_models` in database `my_database`, you may want to save your model
to path like `lib/my_database/my_new_model.rb`:

    require_relative "../model"

    module MyDatabase
      class MyNewModel < MyDatabase::Model
      end
    end

And then at `lib/my_database/model.rb` you’d have your custom `model.rb`:

    require "multi_ar/model"

    module MyDatabase
      class Model < MultiAR::Model
        # Needed so ActiveRecord can determine correct names
        self.abstract_class = true

        # Database identifier, for example for development environment, you’d have my_database_development:
        # database settings block, as opposed to ActiveRecord’s standard development: block.
        # Environment will be applied to the name automatically by MultiAR, as specified to MultiAR#new.
        establish_connection "my_database"
      end
    end

#### MultiAR object

ActiveRecord models that uses MultiAR requires {MultiAR::MultiAR MultiAR} object initialized before the models will work. This object
takes care of settings handling and saves information about all databases that has been used.

    @multi_ar = MultiAR::MultiAR.new databases: [ "my_database" ], environment: "development"

Afterwards, you can use your models as you’d use them with pure ActiveRecord:

    require "my_new_model"
    puts MyNewModel.count

#### Subclassing

For further customization, {MultiAR::MultiAR MultiAR} class can also be subclassed, which allows you to do ready deployment packages,
and for example package them as a gem, which knows how to handle all your specific settings without any extra information
from the user.

    require "multi_ar"

    module MyApplication
      # Wrapper over MultiAR’s base class
      class MyMultiAR < MultiAR::MultiAR
        add_migration_dir "my_db_migrate/dir"
      end
    end

#### MultiAR::Interface

MultiAR can be used with {http://www.sinatrarb.com/ Sinatra}, for example, without any real extra trouble. If you wish to launch
{http://www.sinatrarb.com/ Sinatra} as executable (by `ruby yourservice.rb` or `./yourservice` for example),
it may make sense to use {MultiAR::Interface MultiAR’s CLI interface support} instead:

    # This example executable resides in bin/yourservice

    require "multi_ar/interface"

    require_relative "../lib/yourservice/version"

    interface = MultiAR::Interface.new
    interface.version = "yourservice-#{Yourservice::VERSION}"
    interface.description = "My totally useful utility no-one can live without."
    # interface.migration_framework = true # Enables Rake tasks for migration generation; not needed unless you plan to generate migrations with this executable
    interface.options["databases"] = true
    opts = interface.cli do |parser|
      # You can add your custom Trollop options here
      parser.opt :port, "Port where to bind Sinatra", default: "9999", type: :string
    end

    # MultiAR will be initialized by `MultiAR::Interface`, so now you can just run your program as you want

    raise "Invalid port" if opts["port"] != 10001

    require 'sinatra'

    get '/hi' do
      "Hello World!"
    end

Then you can just run your application:

    $ bundle exec ruby bin/yourservice.rb


Requirements
------------

* Ruby 2.1 or greater

Known issues
--------------

- May or may not work with Rails, please report if you test it
- There is no test for only multi_ar gem, all tests are using multi_ar_migrations at the moment


Developers
----------

    $ gem install bundler
    $ bundle install
    $ cucumber
    # write new feature
    $ cucumber
    # rinse and repeat :-)

Github
------

You can do pull requests at Github using the standard pattern :-)

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

License
-------

(The MIT License)

Copyright (c) 2018 Samu Voutilainen

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

This gem is inspired by code of [active_record_migrations](https://github.com/rosenfeld/active_record_migrations).


