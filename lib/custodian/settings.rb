
require 'singleton'


#
# A class which encapsulates some global-settings from the custodian configuration file.
#
# The configuration file is optional, and we have defaults for every value.
#
# This class is a singleton to avoid having to re-parse the configuration file more than
# once per program-launch.
#
module Custodian

  class Settings

   include Singleton


    #
    # The parsed key=values store
    #
    attr_reader :settings


    #
    # Holder to mark whether we've loaded our file.
    #
    attr_reader :parsed




    #
    # Load the configuration file; called only once.
    #
    def _load
      @parsed   = true
      @settings = Hash.new()

      #
      # The global configuration file.
      #
      file = "/etc/custodian/custodian.cfg"
      return unless( File.exists?( file ) )

      #
      # Load and "parse" the key=value content.
      #
      File.open( file, "r").each_line do |line|
        next if ( line.nil? || line =~ /^#/ )
        if ( line =~ /^(.*)=(.*)$/ )
          key = $1.dup
          val = $2.dup
          key.strip!
          val.strip!
          @settings[key] = val
        end
      end
    end




    #
    # Have we loaded our data?
    #
    def _loaded?
      @parsed
    end




    #
    # The timeout period for all tests
    #
    def timeout
      _load() unless( _loaded? )

      @settings['timeout'] || 30
    end




    #
    # The beanstalkd server address
    #
    def queue_server
      _load() unless( _loaded? )

      @settings['queue_server'] || "127.0.0.1:11300"
    end




    #
    # The filename for the logfile.
    #
    def log_file
      _load() unless( _loaded? )

      @settings['log_file'] || "custodian-dequeue.log"
    end


    #
    # The alerter to use
    #
    def alerter
      _load() unless( _loaded? )

      @settings['alerter'] || "smtp"
    end


  end
end
