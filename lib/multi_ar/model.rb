require "active_record"

require_relative "../multi_ar"

module MultiAR

  #
  # Base model for different model groups to include.
  #
  # This is not supposed to be included by models itself, instead you should have
  # common main parent model that extends this model, and the actual model should extend that model.
  class Model < ActiveRecord::Base
    self.abstract_class = true

    ActiveRecord::Base.time_zone_aware_attributes = true
    ActiveRecord::Base.default_timezone = :local

    # Can be used to set custom database config.
    def self.database_config= config
      @db_config = config
    end

    protected

    def self.establish_connection connection_name
      raise "MultiAR app must be initialized first" if MultiAR.app.nil?
      Database.initialize db_config: MultiAR.app.db_config
      real_connection_name = Database.connection_name connection_name
      raise "Connection #{real_connection_name} is not present in the db config file #{MultiAR.app.db_config}" if not Database.database_config[real_connection_name]

      super Database.database_config[real_connection_name]
    end

  end

end
