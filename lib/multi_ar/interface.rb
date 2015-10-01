
require "fileutils"
require "trollop"

require_relative "../multi_ar"
require_relative "version"

module MultiAR

  # An utility to ease creation of executable using multi database ActiveRecord
  # through command line interface.
  #
  # Usage:
  #
  # TODO: write usage
  # TODO: mention this usage in README.md too
  class Interface

    # Options that will be enabled.
    #
    # Options supported by this system are:
    # - config
    # - db_config
    # - dry
    # - environment
    # - verbose
    # - databases
    #
    # environment is enabled by default, rest are disabled.
    attr_accessor :options

    # Version shown with --version flag on CLI
    attr_accessor :version

    # Description of the application show in usage texts on CLI
    attr_accessor :description

    # Array of databases that will be used insted if none have not been passed through CLI.
    attr_accessor :databases

    # Boolean of whether no arguments are needed
    attr_accessor :run_by_default

    # Hash of gems the application depends to.
    #
    # Format should be:
    #     { "gem_name" => "~> 2.0", "another_gem" => nil }
    #
    # This is used in --init.
    #
    # TODO: what for this actually is? Write an example or just tell what for this should be used.
    attr_accessor :dependencies

    def initialize
      @options = {}
      @dependencies = {}
      @run_by_default = false
    end

    # @note Consumes ARGV, create copy of it if you need it for something.
    # TODO: hardcode shorthands
    def cli
      p = Trollop::Parser.new
      p.version @version if @version
      p.banner @description if @description
      p.opt "init",         "Create stub environment with configuration and database.yaml",           type: :string
      p.opt "databases",    "Databases that will be enabled",                                         type: :strings if @options["databases"]
      p.opt "db_config",    "Path to database config file",                                           type: :string, default: "config/database.yaml" if @options["db_config"]
      p.opt "config",       "Path to config file",                                                    type: :string, default: "config/settings.yaml" if @options["config"]
      p.opt "dry",          "Run the program without doing anything. Useful for debugging with -v",   type: :flag if @options["dry"]
      p.opt "environment",  "Environment to run the alarms for",                                      type: :string, default: "development"
      p.opt "verbose",      "Be verbose",                                                             type: :flag if @options["verbose"]

      yield p if block_given?

      opts = Trollop::with_standard_exception_handling p do
        args = ARGV.clone

        result = p.parse ARGV

        if not @run_by_default
          raise Trollop::HelpNeeded if args.empty?
        end

        result
      end

      bootstrap opts if opts["init"]

      raise "--config must be path to valid file" if @options["config"] and not File.exist? opts["config"]
      raise "config/database.yaml seems to be missing" if @options["db_config"] and not File.exist? opts["db_config"]

      @opts = opts
    end

    private

    # @note This method will always quit the application or raise another exception for errors. Catch SystemExit if that’s not good for you.
    def bootstrap opts
      opts["databases"] ||= @databases
      raise "--databases must be given when bootstrapping." unless opts["databases"]
      raise "#{opts["init"]} already exists" if File.exist? opts["init"]

      config_dir = "config"
      database_config = "database.yaml"

      FileUtils.mkdir opts["init"]
      Dir.chdir opts["init"] do
        File.write "README", bootstrap_readme(opts)
        File.write "Gemfile", bootstrap_gemfile

        FileUtils.mkdir config_dir
        Dir.chdir config_dir do
          File.write database_config, bootstrap_db_config(opts)
        end

        run_bundler
      end

      puts "#{opts["init"]} has been initialized. You can now run your program at the directory."
      exit 0
    end

    def bootstrap_db_config opts
      str = ""
      opts["databases"].each do |db|
        [ "development", "production", "test"].each do |env|
          full_name = "#{db}_#{env}"
          str << <<-EOS.gsub(/^ {10}/, "")
          #{full_name}:
            adapter: sqlite3
            database: db/#{full_name}_.sqlite3
            pool: 5
            timeout: 5000

          EOS
        end
      end

      str
    end

    def bootstrap_gemfile
      str = <<-EOS.gsub(/^ {6}/, "")
      source "http://service.slm.fi:9292/"

      gem "#{script_name}"
      EOS

      @dependencies.each do |dep, version|
        line = "gem \"#{dep}\""
        line += ", #{version}" unless version.nil?
        line += "\n"
        str << line
      end

      str
    end

    def bootstrap_readme opts
      str = <<-EOS.gsub(/^ {6}/, "")
      ## #{script_name}

      This is scaffolded runtime directory for project #{script_name}, created by cimmgnd #{script_name} --init #{opts["init"]}.

      Purpose of this scaffold is to ease usage of this #{script_name}, by providing sample configuration and ready
      bundle just ready for running. Default configuration is for SQLite3, but any databases supported
      by Activerecord can be used (you may need to add them to Gemfile in order for more rare adapters to work).

      You can run #{script_name} using bundler:

          bundle exec #{script_name}

      #{script_name} is powered by ActiveRecord migration framework MultiAR-#{VERSION}. More information bundler can be found
      at its homepage: http://bundler.io
      EOS
    end

    def run_bundler
      puts `bundle install`
    end

    def script_name
      @script_name ||= File.basename($0)
    end
  end
end

