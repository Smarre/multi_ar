
require "fileutils"
require "pathname"
require "trollop"

require_relative "../multi_ar"
require_relative "version"

module MultiAR

  # An utility to ease creation of executable using multi database ActiveRecord
  # through command line interface.
  class Interface

    # Options that will be enabled.
    #
    # Options supported by this system are:
    # - config        # `true` or `String`
    # - db_config     # `true` or `String`
    # - dry           # boolean
    # - environment   # `true` or `String`
    # - verbose       # boolean
    # - databases     # `false` or `Array`, by default asks for databases
    # - migration_dir # String
    #
    # If value is `true`, an option will be added to CLI interface. If the value is something else, the option will be populated by this value instead.
    #
    # `environment` option is enabled by default, rest are disabled.
    attr_accessor :options

    # Version shown with --version flag on CLI
    attr_accessor :version

    # Description of the application show in usage texts on CLI
    attr_accessor :description

    # If set to true, migration framework and other Rake related functionality will be enabled.
    attr_accessor :migration_framework

    # Boolean of whether no arguments are needed
    attr_accessor :run_by_default

    # Hash of gems the application depends to.
    #
    # Format should be:
    #     { "gem_name" => "~> 2.0", "another_gem" => nil }
    #
    # This is used in --init.
    #
    # @todo what for this actually is? Write an example or just tell what for this should be used.
    attr_accessor :dependencies

    def initialize
      @options = {}
      @dependencies = {}
      @run_by_default = false
    end

    DEFAULT_DB_CONFIG = "config/database.yaml"

    # @note Consumes ARGV, create copy of it if you need it for something.
    # @todo hardcode shorthands
    def cli
      p = Trollop::Parser.new
      p.version @version if @version
      p.banner @description if @description
      p.opt "init",         "Create stub environment with configuration and database.yaml. " +
                            "For current dir, use “.”.",                                              type: :string
      p.opt "databases",    "List of databases to perform operations",                                type: :strings if(@options["databases"] != false && !@options["databases"].respond_to?(:each))
      p.opt "db_config",    "Path to database config file",                                           type: :string, default: DEFAULT_DB_CONFIG if @options["db_config"] == true
      p.opt "config",       "Path to MultiAR framework config file",                                  type: :string, default: "config/settings.yaml" if @options["config"] == true
      p.opt "dry",          "Run the program without doing anything. Useful for debugging with -v",   type: :flag if @options["dry"] == true
      p.opt "environment",  "The environment to use. Corresponds to database config name " +
            "(environment for foo_development is “development”).",                                    type: :string, default: "development"
      p.opt "verbose",      "Be verbose",                                                             type: :flag if @options["verbose"] == true

      if @migration_framework == true
        p.opt "all_rake_tasks",     "List all Rake tasks, not only commented ones",                 short: "A", type: :flag
        # TODO: not implemented currently, do we really need this?
        #p.opt "list_databases",     "Lists databases that contains migrations in the gem",                      type: :flag
        # TODO: should we do migration_dirs here too instead?
        p.opt "migration_dir",      "The directory where migrations for databases are read from",               type: :string,  default: "db/migrate"
        p.opt "task",               "Rake task to execute",                                         short: "t", type: :string
        p.opt "tasks",              "List available Rake tasks",                                    short: "T", type: :flag
      end

      yield p if block_given?

      opts = Trollop::with_standard_exception_handling p do
        args = ARGV.clone

        result = p.parse ARGV

        if not @run_by_default
          raise Trollop::HelpNeeded if args.empty?
        end

        result
      end

      @options.each do |key, value|
        next if value == true
        # Not bothering to do checks as we just take the intended values, and not looping the array otherwise
        opts[key] = value
      end

      bootstrap opts if opts["init"] # Bootstrap will exit after execution; in that case nothing after this will be run.

      raise "--config must be path to valid file" if opts[:config_given] and not File.exist? opts["config"]
      raise "Database config #{opts["db_config"]} seems to be missing" if @options["db_config"] and not File.exist? opts["db_config"]

      @opts = opts

      init_multi_ar

      # Then run Rake tasks as requested

      return opts if not @migration_framework # TODO: I think there should be much more fine grained control for this

      if opts["tasks"] || opts["all_rake_tasks"]
        @multi_ar.list_tasks all_rake_tasks: opts["all_rake_tasks"]
        exit 1
      end

      if opts["task"].nil?
        puts "Task must be specified. Check if you passed --task option."
        exit 1
      end

      puts "Running task #{opts["task"]}" if opts["verbose"]
      @multi_ar.rake_task opts["task"]
    end

    private

    def init_multi_ar
      opts = {}
      opts[:db_config] = @opts["db_config"] unless opts["db_config"].nil?
      opts[:migration_dirs] = [ @opts["migration_dir"] ]
      opts[:config] = @opts["config"] unless @opts["config"].nil?
      opts[:databases] = @opts["databases"]
      opts[:environment] = @opts["environment"]
      @multi_ar = MultiAR.new opts
    end

    # @note This method will always quit the application or raise another exception for errors. Catch SystemExit if that’s not good for you.
    def bootstrap opts
      raise "--databases must be given when bootstrapping." unless opts["databases"]
      #raise "#{opts["init"]} already exists" if File.exist? opts["init"] # We don’t want to actually check it, init is more like “add missing configuration”.

      config_dir = "config"
      database_config = "database.yaml"

      FileUtils.mkdir opts["init"] unless Dir.exist? opts["init"]
      Dir.chdir opts["init"] do
        File.write "README.md", bootstrap_readme(opts) unless File.exist?("README.md")
        bootstrap_gemfile

        FileUtils.mkdir config_dir unless Dir.exist? config_dir
        Dir.chdir config_dir do
          File.write database_config, bootstrap_db_config(opts) unless File.exist?(database_config)
        end

        bootstrap_config opts
      end

      puts "Project at dir #{opts["init"]} has been initialized. You can now run your program at the directory."
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
            database: db/#{full_name}.sqlite3
            pool: 5
            timeout: 5000

          EOS
        end
      end

      str
    end

    def bootstrap_gemfile

      str = <<-EOS.gsub(/^ {6}/, "")
      source "https://rubygems.org/"

      gem "multi_ar"
      EOS

      @dependencies.each do |dep, version|
        line = "gem \"#{dep}\""
        line += ", #{version}" unless version.nil?
        line += "\n"
        str << line
      end

      if File.exist?("Gemfile")
        puts "NOTE: you should add following to your Gemfile:"
        puts
        puts str
        return
      end

      File.write "Gemfile", str

      # For convenience, we’ll run the bundler for the user in case we created the Gemfile.
      run_bundler
    end

    def bootstrap_readme opts
      str = <<-EOS.gsub(/^ {6}/, "")
      ## #{script_name}

      This is scaffolded runtime directory for project #{project_name}, created by command #{script_name} --init #{opts["init"]}.

      Purpose of this scaffold is to ease usage of this #{script_name}, by providing sample configuration and ready
      bundle just ready for running. Default configuration is for SQLite3, but any databases supported
      by Activerecord can be used (you may need to add them to Gemfile in order for more rare adapters to work).

      You can run #{script_name} using bundler:

          bundle exec #{script_name}

      #{script_name} is powered by ActiveRecord migration framework MultiAR-#{VERSION}. More information about MultiAR
      can be found at [its home page](https://github.com/Smarre/multi_ar)

      More information bundler can be found [at its homepage](http://bundler.io)
      EOS
    end

    # Writes simple config file for some defaults we can assume from input
    def bootstrap_config opts
      settings_file = "config/settings.yaml"
      return if File.exist? settings_file
      str = <<-EOF
databases:
      EOF
      opts["databases"].each do |database|
        str << "    - #{database}"
      end

      File.open settings_file, "w" do |f|
        f.write str
      end
    end

    def run_bundler
      puts `bundle install`
    end

    def script_name
      @script_name ||= File.basename($0).gsub("_", "\\_")
    end

    def project_name
      Pathname.new(Dir.pwd).basename
    end
  end
end

